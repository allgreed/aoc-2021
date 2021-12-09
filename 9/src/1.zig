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

    var heatmap = std.ArrayList(std.ArrayList(u8)).init(allocator);

    // TODO: often I find myself that I want to do a while over input
    // but do something on the first line
    const first_line = try in_stream.readUntilDelimiterOrEof(&buf, '\n');
    const digits_per_line = first_line.?.len;
    try file.seekTo(0);

    {
        var row = std.ArrayList(u8).init(allocator);
        for (range(digits_per_line + 2)) |_, i| {
            try row.append(9);
        }
        try heatmap.append(row);
    }

    while (try in_stream.readUntilDelimiterOrEof(&buf, '\n')) |line| {
        var row = std.ArrayList(u8).init(allocator);

        try row.append(9);
        for (line) |_, i| {
            const s = line[i .. i + 1];
            try row.append(try std.fmt.parseInt(u8, s, 10));
        }
        try row.append(9);

        try heatmap.append(row);
    }

    {
        var row = std.ArrayList(u8).init(allocator);
        for (range(digits_per_line + 2)) |_, i| {
            try row.append(9);
        }
        try heatmap.append(row);
    }

    var cumsum: u64 = 0;
    for (range(heatmap.items.len - 2)) |_, _i| {
        const i = _i + 1;
        j: for (range(digits_per_line)) |_, _j| {
            const j = _j + 1;

            const cur = heatmap.items[i].items[j];
            for (range(4)) |_, k| {
                const cmp = switch (k) {
                    0 => heatmap.items[i + 1].items[j],
                    1 => heatmap.items[i - 1].items[j],
                    2 => heatmap.items[i].items[j + 1],
                    3 => heatmap.items[i].items[j - 1],
                    else => unreachable,
                };

                if (cmp <= cur)
                    continue :j;
            }

            cumsum += cur + 1;
        }
    }
    std.log.info("{s}", .{heatmap.items[0]});

    std.log.info("{d}", .{cumsum});
}

fn range(count: usize) []const u0 {
    return @as([*]u0, undefined)[0..count];
}
