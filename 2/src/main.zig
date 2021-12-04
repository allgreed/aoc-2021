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
    var buf_reader = std.io.bufferedReader(file.reader());
    var in_stream = buf_reader.reader();

    var h: u32 = 0;
    var v: u32 = 0;
    var a: u32 = 0;
    while (try in_stream.readUntilDelimiterOrEof(&buf, '\n')) |line| {
        const direction = line[0];

        // TODO: does this has to be done so crudely?
        var i: u32 = 0;
        while (line[i] != ' ') {
            i += 1;
        }

        const _value = line[(i + 1)..];
        const value = try std.fmt.parseInt(u32, _value, 10);

        switch (direction) {
            'f' => {
                h += value;
                v += value * a;
            },
            'd' => a += value,
            'u' => a -= value,
            else => unreachable,
        }
    }

    std.log.info("{d}", .{v * h});
}
