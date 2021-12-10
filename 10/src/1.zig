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
    var in_stream = file.reader();

    var cumsum: u64 = 0;

    while (try in_stream.readUntilDelimiterOrEof(&buf, '\n')) |line| {
        var stack = std.ArrayList(u8).init(allocator);

        for (line) |c| {
            //std.log.info("{c} {s}", .{ c, stack.items });
            switch (c) {
                '(', '[', '{', '<' => try stack.append(c),
                ')', ']', '}', '>' => {
                    const cp = stack.popOrNull() orelse break;
                    const diff = try std.math.absInt(@intCast(i64, cp) - @intCast(i64, c));
                    if (diff > 2) {
                        const acc: u64 = switch (c) {
                            ')' => 3,
                            ']' => 57,
                            '}' => 1197,
                            '>' => 25137,
                            else => unreachable,
                        };
                        cumsum += acc;
                        break;
                    }
                },
                else => unreachable,
            }
        }
    }

    std.log.info("{d}", .{cumsum});
}
