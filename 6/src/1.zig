const std = @import("std");
const expect = std.testing.expect;
const max3 = std.math.max3;
const max = std.math.max;
const min = std.math.min;

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
    var buf_reader = std.io.bufferedReader(file.reader());
    var in_stream = buf_reader.reader();

    var laternfishes = std.ArrayList(u32).init(allocator);
    defer laternfishes.deinit();

    const da_line = try in_stream.readUntilDelimiterOrEof(&buf, '\n');
    var comma_splitter = std.mem.split(da_line.?, ",");
    while (comma_splitter.next()) |raw_number| {
        try laternfishes.append(try std.fmt.parseInt(u32, raw_number, 10));
    }

    for (range(0, 80)) |_| {
        for (laternfishes.items) |val, j| {
            const new_val = if (val == 0) 6 else val - 1;

            laternfishes.items[j] = new_val;

            if (val == 0) {
                try laternfishes.append(8);
            }
        }
    }
    std.log.info("{d}", .{laternfishes.items.len});
}

fn range(start: usize, end: usize) []const u0 {
    return @as([*]u0, undefined)[start..end];
}
