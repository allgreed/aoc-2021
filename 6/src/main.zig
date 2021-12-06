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

    var lf_buckets: [9]u64 = [1]u64{0} ** 9;
    for (laternfishes.items) |lf| {
        lf_buckets[lf] += 1;
    }

    for (range(0, 256)) |_| {
        var carry: u64 = 0;
        for (range(0, lf_buckets.len)) |_, i| {
            const idx = lf_buckets.len - i - 1;
            const count = lf_buckets[idx];

            lf_buckets[idx] = carry;
            carry = count;
        }
        lf_buckets[8] = carry;
        lf_buckets[6] += carry;
    }

    // TODO: is there stdlib for that?
    var cumsum: u64 = 0;
    for (lf_buckets) |count| {
        cumsum += count;
    }
    std.log.info("{d}", .{cumsum});
}

fn range(start: usize, end: usize) []const u0 {
    return @as([*]u0, undefined)[start..end];
}
