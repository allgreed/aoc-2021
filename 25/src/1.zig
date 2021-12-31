const std = @import("std");
const og = @import("olgierdlib");

const print = std.log.info;
const range = og.range;
const Point = og.genericPoint(u32);

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

    const first_line = try in_stream.readUntilDelimiterOrEof(&buf, '\n');
    const positions_per_line = first_line.?.len;
    try file.seekTo(0);

    var map = std.ArrayList([]Space).init(allocator);
    var new_map = std.ArrayList([]Space).init(allocator);

    while (try in_stream.readUntilDelimiterOrEof(&buf, '\n')) |line| {
        var new_row = try allocator.alloc(Space, positions_per_line);
        var new_new_row = try allocator.alloc(Space, positions_per_line);

        for (line) |c, i| {
            new_row[i] = switch (c) {
                '>' => Space.East,
                'v' => Space.South,
                '.' => Space.Empty,
                else => unreachable,
            };
        }

        try map.append(new_row);
        std.mem.copy(Space, new_new_row, new_row);
        try new_map.append(new_new_row);
    }

    const map_x = positions_per_line;
    const map_y = map.items.len;

    var cumsum: u64 = 0;
    while (true) {
        var moves: u64 = 0;

        for (map.items) |_, j| {
            for (map.items[j]) |_, i| {
                const c = map.items[j][i];
                switch (c) {
                    Space.Empty => {},
                    Space.South => {},
                    Space.East => {
                        const new_x = (i + 1) % map_x;
                        const new_y = j;

                        if (map.items[new_y][new_x] == Space.Empty) {
                            //print("{d} {d} {d} {d}", .{ i, j, new_x, map_x });
                            new_map.items[j][i] = Space.Empty;
                            new_map.items[new_y][new_x] = Space.East;
                            moves += 1;
                        }
                    },
                }
            }
        }

        clone_map(new_map, map);

        //display_map(map);

        for (map.items) |_, j| {
            for (map.items[j]) |_, i| {
                const c = map.items[j][i];
                switch (c) {
                    Space.Empty => {},
                    Space.East => {},
                    Space.South => {
                        const new_x = i;
                        const new_y = (j + 1) % map_y;

                        if (map.items[new_y][new_x] == Space.Empty) {
                            //print("{d} {d} {d} {d}", .{ i, j, new_x, map_x });
                            new_map.items[j][i] = Space.Empty;
                            new_map.items[new_y][new_x] = Space.South;
                            moves += 1;
                        }
                    },
                }
            }
        }

        cumsum += 1;

        if (moves == 0) {
            break;
        }

        clone_map(new_map, map);

        //display_map(map);
        //print("{s} {d}", .{ "ble", moves });
    }

    print("{d}", .{cumsum});
}

const Space = enum {
    East,
    South,
    Empty,
};

fn display_map(map: std.ArrayList([]Space)) void {
    for (map.items) |_, j| {
        for (map.items[j]) |_, i| {
            const c: u8 = switch (map.items[j][i]) {
                Space.Empty => '.',
                Space.East => '>',
                Space.South => 'v',
            };
            std.debug.print("{c}", .{c});
        }
        std.debug.print("\n", .{});
    }
}

fn clone_map(src: std.ArrayList([]Space), dest: std.ArrayList([]Space)) void {
    for (src.items) |_, j| {
        std.mem.copy(Space, dest.items[j], src.items[j]);
    }
}
