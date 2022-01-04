const std = @import("std");
const expect = std.testing.expect;
const og = @import("olgierdlib");

const print = std.log.info;
const range = og.range;
const Point = genericPoint3d(i32);

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

    const reactor_size = 50;

    const c1 = Cuboid{ .start = Point{ .x = 0, .y = 0, .z = 0 }, .end = Point{ .x = 10, .y = 10, .z = 10 }, .state = CuboidState.On };
    const c2 = Cuboid{ .start = Point{ .x = 3, .y = 3, .z = 3 }, .end = Point{ .x = 8, .y = 8, .z = 8 }, .state = CuboidState.Off };

    var buff = std.ArrayList(Cuboid).init(allocator);
    print("{s}", .{c1.split(c2, buff).items});
    if (1 == 1)
        return;

    var cubes = std.ArrayList(Cuboid).init(allocator);
    try cubes.append(Cuboid{ .start = Point{ .x = -reactor_size, .y = -reactor_size, .z = -reactor_size }, .end = Point{ .x = reactor_size, .y = reactor_size, .z = reactor_size }, .state = CuboidState.On });

    {
        per_line: while (try in_stream.readUntilDelimiterOrEof(&buf, '\n')) |line| {
            var space_splitter = std.mem.split(line, " ");

            const raw_flip = space_splitter.next().?;
            const raw_coords = space_splitter.next().?;

            var comma_splitter = std.mem.split(raw_coords, ",");

            var coords: [3][2]i32 = undefined;
            for (range(3)) |_, i| {
                const ble = comma_splitter.next().?[2..];
                var range_splitter = std.mem.split(ble, "..");

                for (range(2)) |_, j| {
                    const v = try std.fmt.parseInt(i32, range_splitter.next().?, 10);

                    if (v < -reactor_size or v > reactor_size) {
                        //print("Skipping!", .{});
                        continue :per_line;
                    }

                    coords[i][j] = v;
                }
            }

            const c_state = if (raw_flip[1] == 'n') CuboidState.On else CuboidState.Off;
            const cuboid = Cuboid{ .state = c_state, .start = Point{
                .x = coords[0][0],
                .y = coords[1][0],
                .z = coords[2][0],
            }, .end = Point{
                .x = coords[0][1],
                .y = coords[1][1],
                .z = coords[2][1],
            } };

            // processing
            print("{d}", .{cuboid});

            for (cubes.items) |cube_c| {
                print("{d} {d}", .{ cuboid.intersect(cube_c), cuboid.state == cube_c.state });
            }
            try cubes.append(cuboid);
        }
    }

    var cumsum: u64 = 0;

    print("{d}", .{cumsum});
}

const CuboidState = enum {
    On,
    Off,
};

const Cuboid = struct {
    start: Point,
    end: Point,
    state: CuboidState,

    fn intersect(self: Cuboid, other: Cuboid) bool {
        return (self.end.x >= other.start.x) and
            (self.start.x <= other.end.x) and
            (self.end.y >= other.start.y) and
            (self.start.y <= other.end.y) and
            (self.end.z >= other.start.z) and
            (self.start.z <= other.end.z);
    }

    fn split(self: Cuboid, other: Cuboid, tmp: std.ArrayList(Cuboid)) std.ArrayList(Cuboid) {
        if (other.end.z > self.start.z
        // caller asserts they intersect ?
        return tmp;
    }
};

test "cuboid intersect" {
    const c1 = Cuboid{ .start = Point{ .x = 0, .y = 0, .z = 0 }, .end = Point{ .x = 10, .y = 10, .z = 10 }, .state = CuboidState.On };
    const c2 = Cuboid{ .start = Point{ .x = 3, .y = 3, .z = 3 }, .end = Point{ .x = 8, .y = 8, .z = 8 }, .state = CuboidState.On };
    const c3 = Cuboid{ .start = Point{ .x = 13, .y = 13, .z = 13 }, .end = Point{ .x = 14, .y = 14, .z = 14 }, .state = CuboidState.On };
    const c4 = Cuboid{ .start = Point{ .x = 13, .y = 13, .z = 13 }, .end = Point{ .x = 13, .y = 13, .z = 13 }, .state = CuboidState.On };

    try expect(c1.intersect(c2) == true);
    try expect(c1.intersect(c3) == false);
    try expect(c4.intersect(c4) == true);
}

pub fn genericPoint3d(comptime T: type) type {
    return struct {
        const Self = @This();

        x: T,
        y: T,
        z: T,

        pub fn eql(self: Self, other: Self) bool {
            return std.meta.eql(self, other);
        }

        pub fn move(self: Self, x: T, y: T) Self {
            return Self{ .x = self.x + x, .y = self.y + y, .z = self.z + z };
        }
    };
}
