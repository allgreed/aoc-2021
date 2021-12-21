const std = @import("std");
const expect = std.testing.expect;
const og = @import("olgierdlib");

const print = std.log.info;
const range = og.range;

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

    var players: [2]Player = undefined;
    {
        var i: usize = 0;
        while (try in_stream.readUntilDelimiterOrEof(&buf, '\n')) |line| : (i += 1) {
            var space_splitter = std.mem.split(line, " ");
            for (range(4)) |_|
                _ = space_splitter.next();
            players[i] = Player{ .pos = try std.fmt.parseInt(u16, space_splitter.next().?, 10) };
        }
    }

    var cp: *Player = &players[1];
    var cpi: usize = 1;
    var dice = DeterministicDice{};

    //for (range(10)) |_| {
    while (cp.score < 1000) {
        cpi = if (cpi == 0) 1 else 0;
        cp = &players[cpi];

        var v: u16 = 0;
        for (range(3)) |_| {
            const roll = dice.roll();
            v += roll;
        }

        const new_pos = circular(cp.pos + v, 10);
        if (new_pos == 0) {
            print("! {d} {d}", .{ cp.pos, v });
        }
        cp.pos = new_pos;
        cp.score += new_pos;

        //print("{d} - {d} [dcur: {d}+{d}+{d}]", .{ cpi + 1, cp.score, dice.cur - 2, dice.cur - 1, dice.cur });
    }

    print("{s}", .{players});

    const other: usize = if (cpi == 0) 1 else 0;
    print("{d}", .{players[other].score * dice.count});
}

const DeterministicDice = struct {
    cur: u16 = 0,
    count: u64 = 0,
    sides: u16 = 100,

    fn roll(self: *DeterministicDice) u16 {
        self.cur += 1;
        self.count += 1;
        self.cur = circular(self.cur, self.sides);
        return self.cur;
    }
};

fn circular(x: u16, n: u16) u16 {
    const result = if (x > n) x % 10 else x;
    if (result == 0)
        return n
    else
        return result;
}

test "circular" {
    try expect(circular(10 + 1, 10) == 1);
    try expect(circular(9, 10) == 9);
    try expect(circular(9 + 1, 10) == 10);
    try expect(circular(10 + 2, 10) == 2);
    try expect(circular(15 + 8, 10) == 3);
    try expect(circular(4 + 16, 10) == 10);
}

const Player = struct {
    pos: u16,
    score: u32 = 0,
};
