const std = @import("std");
const expect = std.testing.expect;

pub fn main() anyerror!void {
    //const filename = std.os.argv[1];
    // TODO: make it dynamic!
    var file = try std.fs.cwd().openFile("inputs/test.txt", .{});
    //var file = try std.fs.cwd().openFile("inputs/real.txt", .{});
    defer file.close();

    var counter: u32 = 0;

    var s_windows = SlidingWindows3.init();

    var buf: [1024]u8 = undefined;
    var buf_reader = std.io.bufferedReader(file.reader());
    var in_stream = buf_reader.reader();

    while (s_windows.state != 3) {
        const line = try in_stream.readUntilDelimiterOrEof(&buf, '\n');
        const measurement = try std.fmt.parseInt(u32, line.?, 10);
        s_windows.acc(measurement);
    }
    while (try in_stream.readUntilDelimiterOrEof(&buf, '\n')) |line| {
        const measurement = try std.fmt.parseInt(u32, line, 10);

        s_windows.acc(measurement);

        if (s_windows.first() < s_windows.second()) {
            counter += 1;
        }
    }

    try expect(counter == 5);
    std.log.info("{d}", .{counter});
}

const SlidingWindows3 = struct {
    windows: [3 + 1]u32,
    state: u8,
    window_idx: u8,

    pub fn init() SlidingWindows3 {
        return SlidingWindows3{
            .windows = [_]u32{ undefined, undefined, undefined, 0 },
            .state = 0,
            .window_idx = 0,
        };
    }

    fn acc(self: *SlidingWindows3, v: u32) void {
        if (self.state == 0) {
            self.windows[self.window_idx] = v;
            self.state = 1;
        } else if (self.state == 1) {
            self.windows[self.window_idx] += v;
            self.windows[self.window_idx + 1] = v;
            self.state = 2;
        } else if (self.state == 2) {
            self.windows[self.window_idx] += v;
            self.windows[self.window_idx + 1] += v;
            self.windows[self.window_idx + 2] = v;
            self.state = 3;
            self.window_idx = 1;
        } else if (self.state == 3) {
            self.windows[self.window_idx] += v;
            self.windows[(self.window_idx + 1) % 4] += v;
            self.windows[(self.window_idx + 2) % 4] += v;
            self.state = 4;
        } else if (self.state == 4) {
            self.windows[(self.window_idx + 3) % 4] = 0;
            self.window_idx += 1;
            self.window_idx %= 4;
            self.windows[self.window_idx] += v;
            self.windows[(self.window_idx + 1) % 4] += v;
            self.windows[(self.window_idx + 2) % 4] += v;
        }
    }
    pub fn first(self: SlidingWindows3) u32 {
        return self.windows[(self.window_idx + 3) % 4];
    }

    pub fn second(self: SlidingWindows3) u32 {
        return self.windows[self.window_idx];
    }
};
