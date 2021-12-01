const std = @import("std");

pub fn main() anyerror!void {
    //const filename = std.os.argv[1];

    // TODO: make it dynamic!
    var file = try std.fs.cwd().openFile("inputs/test.txt", .{});
    //var file = try std.fs.cwd().openFile("inputs/real.txt", .{});
    defer file.close();

    var counter: u32 = 0;

    var first_window_idx: u8 = 0;
    var windows = [_]u32{0} ** 4;

    var buf: [1024]u8 = undefined;
    var buf_reader = std.io.bufferedReader(file.reader());
    var in_stream = buf_reader.reader();

    {
        const line = try in_stream.readUntilDelimiterOrEof(&buf, '\n');
        const measurement = try std.fmt.parseInt(u32, line.?, 10);
        windows[first_window_idx] += measurement;
    }
    {
        const line = try in_stream.readUntilDelimiterOrEof(&buf, '\n');
        const measurement = try std.fmt.parseInt(u32, line.?, 10);
        windows[first_window_idx] += measurement;
        windows[first_window_idx + 1] += measurement;
    }
    {
        const line = try in_stream.readUntilDelimiterOrEof(&buf, '\n');
        const measurement = try std.fmt.parseInt(u32, line.?, 10);
        windows[first_window_idx % 4] += measurement;
        windows[(first_window_idx + 1) % 4] += measurement;
        windows[(first_window_idx + 2) % 4] += measurement;
        first_window_idx = 1;
    }

    while (try in_stream.readUntilDelimiterOrEof(&buf, '\n')) |line| {
        const measurement = try std.fmt.parseInt(u32, line, 10);

        windows[first_window_idx % 4] += measurement;
        windows[(first_window_idx + 1) % 4] += measurement;
        windows[(first_window_idx + 2) % 4] += measurement;

        //std.debug.print("{d}\n", .{windows});

        if (windows[(first_window_idx + 3) % 4] < windows[first_window_idx]) {
            counter += 1;
        }
        windows[(first_window_idx + 3) % 4] = 0;
        first_window_idx += 1;
        first_window_idx %= 4;
    }

    std.log.info("{d}", .{counter});
}
