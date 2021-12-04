const std = @import("std");
const expect = std.testing.expect;

pub fn main() anyerror!void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();

    const allocator = &arena.allocator;
    var arg_it = std.process.args();
    _ = arg_it.skip();

    const filename = try (arg_it.next(allocator) orelse {
        std.debug.warn("Missing input filename\n", .{});
        return error.InvalidArgs;
    });

    var file = try std.fs.cwd().openFile(filename, .{});
    defer file.close();

    var buf: [1024]u8 = undefined;
    var in_stream = file.reader();

    const first_line = try in_stream.readUntilDelimiterOrEof(&buf, '\n');
    const width = first_line.?.len;
    try file.seekTo(0);

    var numbers = std.ArrayList(u32).init(allocator);
    while (try in_stream.readUntilDelimiterOrEof(&buf, '\n')) |line| {
        try numbers.append(try std.fmt.parseInt(u32, line, 2));
    }

    var togo = numbers.items.len;
    var sox = try allocator.alloc(bool, numbers.items.len);
    {
        var i: usize = 0;
        while (i < numbers.items.len) {
            sox[i] = true;
            i += 1;
        }
    }

    var bi: u5 = @truncate(u5, width) - 1;
    while (togo > 1) {
        var ox_0: i32 = 0;

        for (numbers.items) |number, j| {
            if (!sox[j]) {
                continue;
            }
            const b = get_bit(number, bi);
            if (b == '0')
                ox_0 += 1
            else
                ox_0 -= 1;
        }

        const desired_bit: u8 = if (ox_0 > 0) '0' else '1';

        for (numbers.items) |number, j| {
            if (!sox[j]) {
                continue;
            }

            const b = get_bit(number, bi);
            if (b != desired_bit) {
                sox[j] = false;
                togo -= 1;
            }
        }
        if (togo == 1)
            break;
        bi -= 1;
    }

    var ox: u32 = undefined;
    {
        var i: usize = 0;
        while (!sox[i])
            i += 1;
        ox = numbers.items[i];
    }

    togo = numbers.items.len;
    // TODO: deallocate above
    {
        var i: usize = 0;
        while (i < numbers.items.len) {
            sox[i] = true;
            i += 1;
        }
    }

    bi = @truncate(u5, width) - 1;
    while (togo > 1) {
        var ox_0: i32 = 0;

        for (numbers.items) |number, j| {
            if (!sox[j]) {
                continue;
            }
            const b = get_bit(number, bi);
            if (b == '0')
                ox_0 += 1
            else
                ox_0 -= 1;
        }

        const desired_bit: u8 = if (ox_0 > 0) '1' else '0';

        for (numbers.items) |number, j| {
            if (!sox[j]) {
                continue;
            }

            const b = get_bit(number, bi);
            if (b != desired_bit) {
                sox[j] = false;
                togo -= 1;
            }
        }
        if (togo == 1)
            break;
        bi -= 1;
    }

    var co: u32 = undefined;
    {
        var i: usize = 0;
        while (!sox[i])
            i += 1;
        co = numbers.items[i];
    }
    std.log.info("{d}", .{co * ox});
}

fn get_bit(n: u32, b: u5) u8 {
    return if (((n >> b) & 1) > 0) '1' else '0';
}
