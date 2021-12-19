const std = @import("std");
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

    var snums = std.ArrayList(*Snumber).init(allocator);
    while (try in_stream.readUntilDelimiterOrEof(&buf, '\n')) |line| {
        const s = parse_snumber(line, null, allocator);
        try snums.append(s);
    }

    var cumsum: u32 = 0;
    for (snums.items) |s1| {
        for (snums.items) |s2| {
            if (s1 == s2) continue else {
                cumsum = std.math.max(cumsum, magnitude_add_reduce(s1, s2, allocator));
            }
        }
    }

    print("{d}", .{cumsum});
}

fn clone(s: *Snumber, allocator: *std.mem.Allocator) *Snumber {
    return clone_rec(shift_snumber(s), allocator, null).complex;
}

fn clone_rec(s: Scontent, allocator: *std.mem.Allocator, p: ?*Snumber) Scontent {
    var result: Scontent = undefined;
    switch (s) {
        Scontent.direct => |x| {
            result = shift_u32(x);
        },
        Scontent.complex => |complex| {
            var ss = (allocator.create(Snumber) catch unreachable);
            ss.* = Snumber{
                .left = clone_rec(complex.left, allocator, ss),
                .right = clone_rec(complex.right, allocator, ss),
                .parent = p,
            };
            result = shift_snumber(ss);
        },
    }

    return result;
}

fn magnitude_add_reduce(_a: *Snumber, _b: *Snumber, allocator: *std.mem.Allocator) u32 {
    const a = clone(_a, allocator);
    const b = clone(_b, allocator);

    var result = add(a, b, allocator);
    reduce: while (true) {
        if (!explode(result)) {
            if (!split(result, allocator)) break :reduce;
        }
    }

    return magnitude(result);
}

fn magnitude_rec(s: Scontent) u32 {
    return switch (s) {
        Scontent.direct => |x| x,
        Scontent.complex => |complex| 3 * magnitude_rec(complex.left) + 2 * magnitude_rec(complex.right),
    };
}

fn magnitude(s: *Snumber) u32 {
    return magnitude_rec(shift_snumber(s));
}

fn mk_split(val: u32, p: *Snumber, allocator: *std.mem.Allocator) *Snumber {
    var result = (allocator.create(Snumber) catch unreachable);

    result.* = Snumber{
        .left = shift_u32(std.math.divFloor(u32, val, 2) catch unreachable),
        .right = shift_u32(std.math.divCeil(u32, val, 2) catch unreachable),
        .parent = p,
    };
    return result;
}

fn split(s: *Snumber, allocator: *std.mem.Allocator) bool {
    var result = false;
    // would be hacky to symetrize
    if (s.left == Scontent.direct and s.left.direct >= 10) {
        s.left = shift_snumber(mk_split(s.left.direct, s, allocator));
        result = true;
    }

    if (s.left == Scontent.complex and !result) {
        result = split(s.left.complex, allocator);
    }

    if (s.right == Scontent.complex and !result) {
        result = split(s.right.complex, allocator);
    }

    if (!result and s.right == Scontent.direct and s.right.direct >= 10) {
        s.right = shift_snumber(mk_split(s.right.direct, s, allocator));
        result = true;
    }

    return result;
}

fn find_explode(s: *Snumber, depth: u32) ?*Snumber {
    var result: ?*Snumber = null;
    if (depth == 4) {
        return s;
    }

    inline for (Directions) |d| {
        const child = access_dp(s, d);
        if (child.* == Scontent.complex and result == null) {
            result = find_explode(child.complex, depth + 1);
        }
    }

    return result;
}

const Direction = enum {
    Left,
    Right,

    pub fn opposite(self: Direction) Direction {
        return switch (self) {
            .Left => .Right,
            .Right => .Left,
        };
    }
};

const Directions = [_]Direction{ Direction.Left, Direction.Right };

fn explode(s: *Snumber) bool {
    const maybe_explosion_point = find_explode(s, 0);
    if (maybe_explosion_point == null)
        return false;

    const ep = maybe_explosion_point.?;

    inline for (Directions) |d| {
        var maybe_cur: ?*Snumber = ep;
        var last: *Snumber = ep;

        flip_p: while (maybe_cur) |cur| : (maybe_cur = cur.parent) {
            var elem_d = access_dp(cur, d);
            const ep_dv = access_dp(ep, d).direct;

            if (elem_d.* == Scontent.direct and cur != ep) {
                elem_d.* = shift_u32(elem_d.direct + ep_dv);
                break :flip_p;
            }

            if (elem_d.* == Scontent.complex and elem_d.complex != last) {
                var subcur = elem_d.complex;

                while (access_dp(subcur, d.opposite()).* == Scontent.complex) {
                    subcur = access_dp(subcur, d.opposite()).complex;
                }

                var subcur_d = access_dp(subcur, d.opposite());
                subcur_d.* = shift_u32(subcur_d.direct + ep_dv);
                break :flip_p;
            }

            last = cur;
        }
    }

    inline for (Directions) |d| {
        var branch_to_zero = access_dp(ep.parent.?, d);
        if (branch_to_zero.* == Scontent.complex and branch_to_zero.complex == ep) {
            branch_to_zero.* = shift_u32(0);
            break;
        }
    }

    return true;
}

fn access_dp(s: *Snumber, d: Direction) *Scontent {
    return switch (d) {
        Direction.Left => &s.left,
        Direction.Right => &s.right,
    };
}

fn add(a: *Snumber, b: *Snumber, allocator: *std.mem.Allocator) *Snumber {
    var result = (allocator.create(Snumber) catch unreachable);

    a.parent = result;
    b.parent = result;

    result.* = Snumber{
        .left = shift_snumber(a),
        .right = shift_snumber(b),
        .parent = null,
    };
    return result;
}

fn parse_scontent(raw: []u8, parent: ?*Snumber, allocator: *std.mem.Allocator) Scontent {
    if (raw[0] == '[') {
        return shift_snumber(parse_snumber(raw, parent, allocator));
    } else {
        return shift_u32(std.fmt.parseInt(u32, raw, 10) catch unreachable);
    }
}

fn parse_snumber(raw: []u8, parent: ?*Snumber, allocator: *std.mem.Allocator) *Snumber {
    var open_p_count: u32 = 1;
    var comma_pos: usize = undefined;

    for (raw[1..]) |c, i| {
        switch (c) {
            '[' => open_p_count += 1,
            ']' => open_p_count -= 1,
            else => {},
        }
        if (open_p_count == 1) {
            comma_pos = i;
            break;
        }
    }

    while (raw[comma_pos] != ',') : (comma_pos += 1) {}

    var result = (allocator.create(Snumber) catch unreachable);
    result.* = .{
        .left = parse_scontent(raw[1..comma_pos], result, allocator),
        .right = parse_scontent(raw[comma_pos + 1 .. raw.len - 1], result, allocator),
        .parent = parent,
    };
    return result;
}

const Scontent = union(enum) {
    complex: *Snumber,
    direct: u32,

    fn _dump(self: Scontent) void {
        switch (self) {
            Scontent.complex => |complex| complex._dump(),
            Scontent.direct => |x| std.debug.print("{d}", .{x}),
        }
    }

    pub fn shift_u32(x: u32) Scontent {
        return Scontent{ .direct = x };
    }

    pub fn shift_snumber(x: *Snumber) Scontent {
        return Scontent{ .complex = x };
    }

    fn dump(self: Scontent) void {
        self._dump();
        std.debug.print("\n", .{});
    }
};

const shift_snumber = Scontent.shift_snumber;
const shift_u32 = Scontent.shift_u32;

const Snumber = struct {
    left: Scontent,
    right: Scontent,
    parent: ?*Snumber,

    fn _dump(self: Snumber) void {
        std.debug.print("[", .{});
        self.left._dump();
        std.debug.print(",", .{});
        self.right._dump();
        std.debug.print("]", .{});
    }

    fn dump(self: Snumber) void {
        self._dump();
        std.debug.print("\n", .{});
    }
};
