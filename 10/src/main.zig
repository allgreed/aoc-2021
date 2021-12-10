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

    var scores = std.ArrayList(u64).init(allocator);

    outer: while (try in_stream.readUntilDelimiterOrEof(&buf, '\n')) |line| {
        var stack = std.ArrayList(u8).init(allocator);

        for (line) |c| {
            switch (c) {
                '(', '[', '{', '<' => try stack.append(c),
                ')', ']', '}', '>' => {
                    const cp = stack.pop();
                    const diff = try std.math.absInt(@intCast(i64, cp) - @intCast(i64, c));
                    if (diff > 2) continue :outer;
                },
                else => unreachable,
            }
        }

        var subscore: u64 = 0;

        while (stack.popOrNull()) |c| {
            subscore *= 5;
            const acc: u64 = switch (c) {
                '(' => 1,
                '[' => 2,
                '{' => 3,
                '<' => 4,
                else => unreachable,
            };
            subscore += acc;
        }

        try scores.append(subscore);
    }

    std.sort.sort(u64, scores.items, {}, comptime std.sort.desc(u64));

    const half = scores.items.len / 2;

    std.log.info("{d}", .{scores.items[scores.items.len / 2]});
}
