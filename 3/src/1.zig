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
    //var buf_reader = std.io.bufferedReader(file.reader()); <- ha, suck it!
    var in_stream = file.reader();

    const first_line = try in_stream.readUntilDelimiterOrEof(&buf, '\n');
    const width = first_line.?.len;
    try file.seekTo(0);

    const counters: []PostionCounter = try allocator.alloc(PostionCounter, width);
    for (counters) |*c| {
        // TODO: deffinitely a better way!
        c.zeroes = 0;
        c.ones = 0;
    }

    while (try in_stream.readUntilDelimiterOrEof(&buf, '\n')) |line| {
        for (line) |c, i| {
            if (c == '0')
                counters[i].zeroes += 1
            else
                counters[i].ones += 1;
        }
    }

    var g: u32 = 0;
    var e: u32 = 0;
    for (counters) |*c, i| {
        // TODO: double assignment?
        const most_common: u32 = if (c.zeroes >= c.ones) 0 else 1;
        const least_common: u32 = if (c.zeroes >= c.ones) 1 else 0;
        g += most_common;
        e += least_common;
        g <<= 1;
        e <<= 1;
    }
    g >>= 1;
    e >>= 1;

    std.log.info("{d}", .{g * e});
}

const PostionCounter = struct {
    zeroes: u32 = 0,
    ones: u32 = 0,
};
