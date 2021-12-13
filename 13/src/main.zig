const std = @import("std");
const mem = std.mem;

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

    var initial_points = std.ArrayList(Point).init(allocator);
    var folds = std.ArrayList(Fold).init(allocator);

    while (try in_stream.readUntilDelimiterOrEof(&buf, '\n')) |line| {
        if (line.len == 0)
            break;

        var comma_splitter = std.mem.split(line, ",");

        const _x = comma_splitter.next().?;
        const _y = comma_splitter.next().?;

        const x = try std.fmt.parseInt(u32, _x, 10);
        const y = try std.fmt.parseInt(u32, _y, 10);

        const p = Point{ .x = x, .y = y };
        try initial_points.append(p);
    }

    while (try in_stream.readUntilDelimiterOrEof(&buf, '\n')) |line| {
        var space_splitter = std.mem.split(line, " ");
        for (range(2)) |_| {
            _ = space_splitter.next();
        }

        const raw_fold = space_splitter.next().?;

        var eq_splitter = std.mem.split(raw_fold, "=");

        const raw_axis = eq_splitter.next().?;
        const param = try std.fmt.parseInt(u32, eq_splitter.next().?, 10);

        const fold = Fold{ .param = param, .axis = switch (raw_axis[0]) {
            'x' => Axis.x,
            'y' => Axis.y,
            else => unreachable,
        } };

        try folds.append(fold);
    }

    var x_size: usize = undefined;
    for (folds.items) |fold| {
        if (fold.axis == Axis.x) {
            x_size = fold.param * 2 + 1;
            break;
        }
    }
    var y_size: usize = undefined;
    for (folds.items) |fold| {
        if (fold.axis == Axis.y) {
            y_size = fold.param * 2 + 1;
            break;
        }
    }

    var points = try alloc2d(bool, x_size, y_size, allocator);
    for (points) |_, i| {
        for (points[i]) |_, j| {
            points[i][j] = false;
        }
    }

    for (initial_points.items) |p| {
        points[p.x][p.y] = true;
    }

    for (folds.items) |fold| {
        const p2 = 2 * fold.param;

        switch (fold.axis) {
            Axis.x => {
                for (range(y_size)) |_, j| {
                    for (range(fold.param)) |_, i| {
                        points[i][j] = points[i][j] or points[p2 - i][j];
                    }
                }
                x_size /= 2;
            },
            Axis.y => {
                for (range(x_size)) |_, i| {
                    for (range(fold.param)) |_, j| {
                        points[i][j] = points[i][j] or points[i][p2 - j];
                    }
                }
                y_size /= 2;
            },
        }
    }

    for (range(y_size)) |_, j| {
        for (range(x_size)) |_, i| {
            const c: u8 = if (points[i][j]) '#' else '.';
            std.debug.print("{c}", .{c});
        }
        std.debug.print("\n", .{});
    }
}

fn range(count: usize) []const u0 {
    return @as([*]u0, undefined)[0..count];
}

const Point = struct {
    x: u32,
    y: u32,
};

const Axis = enum {
    x,
    y,
};

const Fold = struct {
    axis: Axis,
    param: u32,
};

inline fn alloc2d(comptime t: type, m: usize, n: usize, allocator: *std.mem.Allocator) ![][]t {
    const array = try allocator.alloc([]t, m);
    for (array) |_, index| {
        array[index] = try allocator.alloc(t, n);
    }
    return array;
}
