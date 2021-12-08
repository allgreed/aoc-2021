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

    //var positions = std.ArrayList(u32).init(allocator);
    //defer positions.deinit();

    var cumsum: u64 = 0;
    while (try in_stream.readUntilDelimiterOrEof(&buf, '\n')) |line| {
        var bar_splitter = std.mem.split(line, "|");

        const map = bar_splitter.next();
        const display = bar_splitter.next();

        var dispaly_space_splitter = std.mem.split(display.?, " ");
        while (dispaly_space_splitter.next()) |raw_wires| {
            if (raw_wires.len == 0)
                continue;

            const acc: u64 = switch (raw_wires.len) {
                2, 4, 3, 7 => 1,
                else => 0,
            };

            //std.log.info("{s} {d}", .{ raw_wires, acc });
            cumsum += acc;
        }
    }

    std.log.info("{d}", .{cumsum});
}

fn range(count: usize) []const u0 {
    return @as([*]u0, undefined)[0..count];
}
