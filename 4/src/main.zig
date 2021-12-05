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

    var buf: [1024]u8 = undefined;
    var buf_reader = std.io.bufferedReader(file.reader());
    var in_stream = buf_reader.reader();

    var numbers = std.ArrayList(u32).init(allocator);
    // TODO: how to free it?

    const first_line = try in_stream.readUntilDelimiterOrEof(&buf, '\n');
    var comma_splitter = std.mem.split(first_line.?, ",");
    while (comma_splitter.next()) |raw_number| {
        try numbers.append(try std.fmt.parseInt(u32, raw_number, 10));
    }

    var boards = std.ArrayList(Board).init(allocator);
    // TODO: free
    var i: usize = 0;
    var j: usize = 0;
    var buffer: [25]u32 = undefined;

    _ = try in_stream.readUntilDelimiterOrEof(&buf, '\n'); // first empty line is not super useful
    while (try in_stream.readUntilDelimiterOrEof(&buf, '\n')) |line| {
        if (line.len == 0) {
            try boards.append(Board.init(buffer));
            i += 1;
            j = 0;
        } else {
            var splitter = std.mem.split(line, " ");
            while (splitter.next()) |raw_number| {
                if (raw_number.len == 0)
                    continue;
                buffer[j] = try std.fmt.parseInt(u32, raw_number, 10);
                j += 1;
            }
        }
    }
    try boards.append(Board.init(buffer));

    var seen = std.ArrayList(bool).init(allocator);
    try seen.ensureTotalCapacity(boards.items.len);
    for (boards.items) |_| {
        try seen.append(false);
    }

    var b: *Board = undefined;
    var lucky_number: u32 = undefined;
    var winners: usize = 0;
    outer: for (numbers.items) |number| {
        for (boards.items) |*board, ii| {
            board.mark(number);
            if (board.is_winner()) {
                if (!seen.items[ii]) {
                    b = board;
                    seen.items[ii] = true;
                    lucky_number = number;
                    winners += 1;
                }

                if (winners == boards.items.len)
                    break :outer;
            }
        }
    }

    var cumsum: u32 = 0;
    for (b.values) |row, ii| {
        for (row) |v, jj| {
            if (!b.marks[ii][jj]) {
                cumsum += v;
            }
        }
    }
    std.log.info("{d}", .{cumsum * lucky_number});
}

const Board = struct {
    marks: [5][5]bool = [1][5]bool{[1]bool{false} ** 5} ** 5,
    values: [5][5]u32 = undefined,

    pub fn init(values: [25]u32) Board {
        var b = Board{};
        var k: usize = 0;

        for (b.values) |_, i| {
            for (b.values[i]) |_, j| {
                b.values[i][j] = values[k];
                k += 1;
            }
        }

        return b;
    }

    fn mark(self: *Board, number: u32) void {
        outer: for (self.values) |_, i| {
            for (self.values[i]) |_, j| {
                if (self.values[i][j] == number) {
                    self.marks[i][j] = true;
                    break :outer;
                }
            }
        }
    }

    fn is_winner(self: Board) bool {
        var i: usize = 0;
        // TODO: ranges?
        while (i < 5) {
            if (self.marks[i][i]) {
                var j: usize = 0;
                var winner = true;
                while (j < 5) {
                    winner = winner and self.marks[i][j];
                    j += 1;
                }
                if (winner) return true;

                winner = true;
                j = 0;
                while (j < 5) {
                    winner = winner and self.marks[j][i];
                    j += 1;
                }
                if (winner) return true;
            }
            i += 1;
        }

        return false;
    }
};
