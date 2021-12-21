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

    var wins = [_]u64{0} ** 2;
    var games = std.AutoArrayHashMap(Game, u64).init(allocator);
    var new_games = std.AutoArrayHashMap(Game, u64).init(allocator);
    {
        var init_pos: [2]u16 = undefined;
        var i: usize = 0;
        while (try in_stream.readUntilDelimiterOrEof(&buf, '\n')) |line| : (i += 1) {
            var space_splitter = std.mem.split(line, " ");
            for (range(4)) |_|
                _ = space_splitter.next();

            init_pos[i] = try std.fmt.parseInt(u16, space_splitter.next().?, 10);
        }

        try games.put(Game{ .p0 = Player{ .score = 0, .pos = init_pos[0] }, .p1 = Player{ .score = 0, .pos = init_pos[1] }, .turn = 0 }, 1);
    }

    const dd_generic_vector = init: {
        var initial_value = [_]u8{0} ** 11;
        // generated from Python with love
        //import itertools; from collections import Counter
        //d = list(range(1, 4))
        //for i, n in Counter(list(map(sum, (itertools.product(d, d, d))))).items():
        //    print(f"initial_value[{i}] = {n};")
        initial_value[3] = 1;
        initial_value[4] = 3;
        initial_value[5] = 6;
        initial_value[6] = 7;
        initial_value[7] = 6;
        initial_value[8] = 3;
        initial_value[9] = 1;
        break :init initial_value;
    };

    const dd_vector_table = init: {
        var initial_value: [11][11]u8 = undefined;

        for (range(11)) |_, pos| {
            var dd_specific_vector = [_]u8{0} ** 11;
            for (dd_generic_vector) |count, v| {
                dd_specific_vector[circular(@intCast(u16, v) + @intCast(u16, pos), 10)] += count;
            }
            initial_value[pos] = dd_specific_vector;
        }
        initial_value[0] = [_]u8{0} ** 11;

        break :init initial_value;
    };

    //while (true) {
    for (range(100)) |_| {
        new_games.clearRetainingCapacity();

        var git = games.iterator();
        while (git.next()) |entry| {
            const game = entry.key_ptr;
            const turn = game.turn;
            const p = if (turn == 1) game.p1 else game.p0;
            const next_turn: usize = if (turn == 1) 0 else 1;
            const pos: u16 = p.pos;
            const pos_count: u64 = entry.value_ptr.*;
            const score: u64 = p.score;

            for (dd_vector_table[pos]) |count, new_pos| {
                if (count == 0) continue;

                const new_score = score + new_pos;
                const new_count: u64 = count * pos_count;
                // extract const
                if (new_score >= 21) {
                    if (turn > 1)
                        print("! {d}", .{turn});
                    wins[turn] += new_count;
                } else {
                    const new_player = Player{ .pos = @intCast(u16, new_pos), .score = new_score };

                    var p0: Player = undefined;
                    var p1: Player = undefined;
                    if (turn == 0) {
                        p0 = new_player;
                        p1 = game.p1;
                    } else {
                        p0 = game.p0;
                        p1 = new_player;
                    }

                    const g = Game{ .p0 = p0, .p1 = p1, .turn = next_turn };
                    const gpr = try new_games.getOrPut(g);
                    if (!gpr.found_existing) {
                        gpr.value_ptr.* = 0;
                    }
                    gpr.value_ptr.* += new_count;
                }
            }
        }
        const tmp = games;
        games = new_games;
        new_games = tmp;
    }

    print("{d}", .{wins});
    //print("{s}", .{players[1].positions.items});
}

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
    score: u64 = 0,
};

const Game = struct {
    p0: Player,
    p1: Player,
    turn: usize,

    pub fn eql(self: Game, other: Game) bool {
        return std.meta.eql(self.p0, other.p0) and std.meta.eql(self.p1, other.p1) and self.turn == other.turn;
    }
};
