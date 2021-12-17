const std = @import("std");
const og = @import("olgierdlib");

const print = std.log.info;
const range = og.range;

const CoordType = i32;

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

    const da_line = (try in_stream.readUntilDelimiterOrEof(&buf, '\n')).?;

    var space_splitter = std.mem.split(da_line, " ");

    for (range(2)) |_|
        _ = space_splitter.next();

    const x_component = space_splitter.next().?;
    const y_component = space_splitter.next().?;

    var dot_splitter = std.mem.split(x_component, "..");
    const x_target_min = try std.fmt.parseInt(CoordType, dot_splitter.next().?[2..], 10);
    const _zorg = dot_splitter.next().?;
    const x_target_max = try std.fmt.parseInt(CoordType, _zorg[0 .. _zorg.len - 1], 10);

    dot_splitter = std.mem.split(y_component, "..");
    const y_target_min = try std.fmt.parseInt(CoordType, dot_splitter.next().?[2..], 10);
    const y_target_max = try std.fmt.parseInt(CoordType, dot_splitter.next().?, 10);

    var cumsum: u64 = 0;
    for (range(@intCast(usize, x_target_max + 1))) |_, i| {
        const dy_max = -y_target_min;
        for (range(2 * @intCast(usize, dy_max + 1))) |_, _j| {
            var x: CoordType = 0;
            var y: CoordType = 0;
            var dx: CoordType = @intCast(i32, i);
            const j = @intCast(i32, _j) - dy_max;
            var dy: CoordType = j;

            while (x < x_target_max and y > y_target_min) {
                x += dx;
                y += dy;
                const ddx: CoordType = if (dx > 0) 1 else 0;
                dx -= ddx;
                dy -= 1;

                if (x >= x_target_min and x <= x_target_max and y >= y_target_min and y <= y_target_max) {
                    cumsum += 1;
                    break;
                }
            }
        }
    }
    print("{d}", .{cumsum});
}
