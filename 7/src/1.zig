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
    while (comma_splitter.next()) |raw_number| {
        try positions.append(try std.fmt.parseInt(u32, raw_number, 10));
    }

    comptime const asc_u32 = std.sort.asc(u32);
    std.sort.sort(u32, positions.items, {}, asc_u32);

    std.log.info("{d}", .{positions.items});
    const target_position = try medianFromSorted(u32, positions.items);

    var cumsum: u64 = 0;
    for (positions.items) |pos| {
        const distance = try std.math.absInt(@as(i64, pos) - target_position);
        cumsum += @intCast(u64, distance);
    }
    std.log.info("{d}", .{cumsum});
}

fn range(count: usize) []const u0 {
    return @as([*]u0, undefined)[0..count];
}

fn medianFromSorted(comptime T: type, items: []T) !T {
    const len = items.len;

    if (len % 2 == 0) {
        const r_split_idx = try std.math.divExact(usize, len, 2);
        const l = items[r_split_idx - 1];
        const r = items[r_split_idx];

        if (l == r)
            return r;

        // TODO: panic
        return 9999999;
    } else { // % 2 == 1
        return items[try std.math.divFloor(usize, len, 2)];
    }
}
