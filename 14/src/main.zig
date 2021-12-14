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

    const polymer_line = (try in_stream.readUntilDelimiterOrEof(&buf, '\n')).?;

    var pairs = std.StringArrayHashMap(u64).init(allocator);
    {
        var cp: [2]u8 = undefined;
        cp[1] = polymer_line[0];

        for (range(polymer_line.len - 1)) |_, _i| {
            const i = _i + 1;
            cp[0] = cp[1];
            cp[1] = polymer_line[i];

            // TODO: uncrap this o.0 -> there has to be a smarter way :C
            var fuj = try allocator.alloc(u8, 2);
            std.mem.copy(u8, fuj[0..fuj.len], &cp);

            const gpr = try pairs.getOrPut(fuj);
            if (!gpr.found_existing) {
                gpr.value_ptr.* = 0;
            }
            gpr.value_ptr.* += 1;
        }
    }
    var rules = std.StringHashMap(u8).init(allocator);
    _ = try in_stream.readUntilDelimiterOrEof(&buf, '\n');
    while (try in_stream.readUntilDelimiterOrEof(&buf, '\n')) |line| {
        var space_splitter = std.mem.split(line, " ");

        const p1_view = space_splitter.next().?;
        _ = space_splitter.next();
        const c = space_splitter.next().?[0];

        var p1 = try allocator.alloc(u8, 2);
        std.mem.copy(u8, p1[0..p1.len], p1_view);

        try rules.put(p1, c);
    }

    print("{s}", .{pairs.keys()});
    print("{d}", .{pairs.values()});

    {
        var it = pairs.iterator();
        while (it.next()) |pair| {
            //const count = pair.value_ptr.*;
            const count = 1;
            pair.value_ptr.* -= count;
            const key = pair.key_ptr.*;

            const c = rules.get(key).?;
            print("{s}", .{pair});

            var cp: [2]u8 = undefined;

            cp[0] = key[0];
            cp[1] = c;

            var fuj = try allocator.alloc(u8, 2);
            std.mem.copy(u8, fuj[0..fuj.len], &cp);
            var gpr = try pairs.getOrPut(fuj);
            if (!gpr.found_existing) {
                gpr.value_ptr.* = 0;
            }
            gpr.value_ptr.* += count;

            cp[0] = c;
            cp[0] = key[1];
            fuj = try allocator.alloc(u8, 2);
            std.mem.copy(u8, fuj[0..fuj.len], &cp);
            gpr = try pairs.getOrPut(fuj);
            if (!gpr.found_existing) {
                gpr.value_ptr.* = 0;
            }
            gpr.value_ptr.* += count;
        }
    }

    print("{s}", .{pairs.keys()});
    print("{d}", .{pairs.values()});

    //{
    //var it = polymer.first;
    //while (it) |node| : (it = node.next) {
    //const c = node.data;

    //const gpr = try counters.getOrPut(c);
    //if (!gpr.found_existing) {
    //gpr.value_ptr.* = 0;
    //}
    //gpr.value_ptr.* += 1;
    //}
    //}

    //var maxx: u64 = 0;
    //var minn: u64 = std.math.maxInt(u64);
    //{
    //var it = counters.valueIterator();
    //while (it.next()) |_v| {
    //const v = _v.*;
    //maxx = std.math.max(maxx, v);
    //minn = std.math.min(minn, v);
    //}
    //}

    //print("{d}", .{maxx - minn});
}

fn range(count: usize) []const u0 {
    return @as([*]u0, undefined)[0..count];
}
