const std = @import("std");
const mem = std.mem;

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

    var cave_name_to_idx = std.StringArrayHashMap(u8).init(allocator);
    var caves = std.ArrayList(Cave).init(allocator);

    while (try in_stream.readUntilDelimiterOrEof(&buf, '\n')) |line| {
        var dash_splitter = std.mem.split(line, "-");
        const _from = dash_splitter.next().?;
        const _to = dash_splitter.next().?;
        const is_small = false;

        const crf = try cave_name_to_idx.getOrPut(_from);
        if (!crf.found_existing) {
            const idx = @truncate(u8, caves.items.len);
            try caves.append(Cave{ .is_small = _from[0] > 96, .name = _from, .neighbours = std.ArrayList(u8).init(allocator) });
            crf.value_ptr.* = idx;
        }
        const from = crf.value_ptr.*;

        const crt = try cave_name_to_idx.getOrPut(_to);
        if (!crt.found_existing) {
            const idx = @truncate(u8, caves.items.len);
            try caves.append(Cave{ .is_small = _to[0] > 96, .name = _to, .neighbours = std.ArrayList(u8).init(allocator) });
            crt.value_ptr.* = idx;
        }
        const to = crt.value_ptr.*;

        try caves.items[from].neighbours.append(to);
    }

    // TODO: ok, apparently the pointers point to buffer, which is overwritten, like... that's my best guess...
    for (caves.items) |c| {
        std.log.info("{d}", .{
            c.name,
        });
    }
    // find start and end

    // traverse and count paths

    var cumsum: u64 = 0;
    std.log.info("{d}", .{cumsum});
}

fn range(count: usize) []const u0 {
    return @as([*]u0, undefined)[0..count];
}

const Cave = struct {
    is_small: bool,
    name: []const u8,
    neighbours: std.ArrayList(u8),
};
