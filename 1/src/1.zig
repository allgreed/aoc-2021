const std = @import("std");

pub fn main() anyerror!void {
    //const filename = std.os.argv[1];

    // TODO: make it dynamic!
    var file = try std.fs.cwd().openFile("inputs/test.txt", .{});
    defer file.close();

    var buf_reader = std.io.bufferedReader(file.reader());
    var in_stream = buf_reader.reader();

    var counter: u32 = 0;
    var window_pointer: u8 = 0;
    var windows: [4]u32 = undefined;
    var buf: [1024]u8 = undefined;
    var previous: u32 = undefined;
    while (try in_stream.readUntilDelimiterOrEof(&buf, '\n')) |line| {
        const measurement = try std.fmt.parseInt(u32, line, 10);

        if (measurement > previous) {
            counter += 1;
        }

        std.debug.print("buf {d} {d} \n", .{ measurement, previous });
        previous = measurement;
    }

    std.log.info("{d}", .{counter});
}
