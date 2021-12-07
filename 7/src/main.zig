const std = @import("std");

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

    var buf: [1024 * 4]u8 = undefined;
    var buf_reader = std.io.bufferedReader(file.reader());
    var in_stream = buf_reader.reader();

    var positions = std.ArrayList(u32).init(allocator);
    defer positions.deinit();

    const da_line = try in_stream.readUntilDelimiterOrEof(&buf, '\n');
    var comma_splitter = std.mem.split(da_line.?, ",");
    var sum: u64 = 0;
    while (comma_splitter.next()) |raw_number| {
        const pos = try std.fmt.parseInt(u32, raw_number, 10);
        try positions.append(pos);
        sum += pos;
    }

    const target_position: usize = try std.math.divFloor(u64, sum, positions.items.len);

    var cumsum: u64 = 0;
    for (positions.items) |pos| {
        const distance = try std.math.absInt(@as(i64, pos) - @intCast(i64, target_position));
        const f = fuel(@intCast(u64, distance + 1));
        cumsum += f;
    }
    std.log.info("{d}", .{cumsum});
}

fn range(count: usize) []const u0 {
    return @as([*]u0, undefined)[0..count];
}

fn fuel(n: u64) u64 {
    var cumsum: u64 = 0;
    for (range(n)) |_, i| {
        cumsum += i;
    }

    return cumsum;
}
