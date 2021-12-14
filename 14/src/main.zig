const std = @import("std");
const print = std.log.info;

const Lu8 = std.SinglyLinkedList(u8);
const Lu8Node = Lu8.Node;

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

    var polymer = Lu8{};

    const polymer_line = (try in_stream.readUntilDelimiterOrEof(&buf, '\n')).?;

    var initial_node = try mk_node(polymer_line[0], allocator);
    polymer.prepend(initial_node);
    var head: *Lu8Node = initial_node;
    for (range(polymer_line.len - 1)) |_, _i| {
        const i = _i + 1;

        var new_node = try mk_node(polymer_line[i], allocator);
        head.insertAfter(new_node);
        head = new_node;
    }

    var rules = std.StringHashMap(u8).init(allocator);
    _ = try in_stream.readUntilDelimiterOrEof(&buf, '\n');
    while (try in_stream.readUntilDelimiterOrEof(&buf, '\n')) |line| {
        var space_splitter = std.mem.split(line, " ");

        const p1_view = space_splitter.next().?;
        _ = space_splitter.next();
        const c = space_splitter.next().?[0];

        var p1 = try allocator.alloc(u8, p1_view.len);
        std.mem.copy(u8, p1[0..p1.len], p1_view);

        try rules.put(p1, c);
    }

    var insertQ = std.ArrayList(InsertionCommand).init(allocator);

    for (range(10)) |_| {
        var cp: [2]u8 = undefined;
        var it = polymer.first;
        var pp: *Lu8Node = it.?;
        cp[0] = it.?.data;
        it = it.?.next;
        cp[1] = it.?.data;

        try insertQ.append(InsertionCommand{ .after = pp, .data = rules.get(cp[0..2]).? });

        pp = it.?;
        it = it.?.next;

        while (it) |node| : (it = node.next) {
            cp[0] = cp[1];
            cp[1] = node.data;

            try insertQ.append(InsertionCommand{ .after = pp, .data = rules.get(cp[0..2]).? });

            pp = node;
        }

        while (insertQ.popOrNull()) |ic| {
            ic.after.insertAfter(try mk_node(ic.data, allocator));
        }
    }

    var counters = std.AutoHashMap(u8, u64).init(allocator);

    {
        var it = polymer.first;
        while (it) |node| : (it = node.next) {
            const c = node.data;

            const gpr = try counters.getOrPut(c);
            if (!gpr.found_existing) {
                gpr.value_ptr.* = 0;
            }
            gpr.value_ptr.* += 1;
        }
    }

    var maxx: u64 = 0;
    var minn: u64 = std.math.maxInt(u64);
    {
        var it = counters.valueIterator();
        while (it.next()) |_v| {
            const v = _v.*;
            maxx = std.math.max(maxx, v);
            minn = std.math.min(minn, v);
        }
    }

    print("{d}", .{maxx - minn});
    //print("{d}", .{counters});
}

fn range(count: usize) []const u0 {
    return @as([*]u0, undefined)[0..count];
}

fn mk_node(data: u8, allocator: *std.mem.Allocator) !*Lu8Node {
    var node_mem = try allocator.alloc(Lu8Node, 1);
    node_mem[0] = Lu8Node{ .data = data };
    return &node_mem[0];
}

const InsertionCommand = struct {
    after: *Lu8Node,
    data: u8,
};

fn dump_list(list: std.SinglyLinkedList(u8)) void {
    var it = list.first;
    while (it) |node| : (it = node.next) {
        std.debug.print("{c}", .{node.data});
    }
    std.debug.print("\n", .{});
}
