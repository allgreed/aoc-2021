const std = @import("std");
const expect = std.testing.expect;
const og = @import("olgierdlib");

const print = std.log.info;
const range = og.range;
const Point = og.genericPoint3d(i32);

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
    const reactor_real_size = 2 * reactor_size + 1;

    var reactor: [reactor_real_size][reactor_real_size][reactor_real_size]bool = undefined;
    for (range(reactor_real_size)) |_, i| {
        for (range(reactor_real_size)) |_, j| {
            for (range(reactor_real_size)) |_, k| {
                reactor[i][j][k] = false;
            }
        }
    }

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

                    if (v < -reactor_size or v > reactor_size)
                        continue :per_line;

                    coords[i][j] = v;
                }
            }

            const flip_value: bool = if (raw_flip[1] == 'n') true else false;

            // processing
            print("{d}, {s}", .{ coords, flip_value });

            var i: i32 = coords[0][0];
            while (i <= coords[0][1]) : (i += 1) {
                var j: i32 = coords[1][0];
                while (j <= coords[1][1]) : (j += 1) {
                    var k: i32 = coords[2][0];
                    while (k <= coords[2][1]) : (k += 1) {
                        reactor[@intCast(usize, i + reactor_size)][@intCast(usize, j + reactor_size)][@intCast(usize, k + reactor_size)] = flip_value;
                    }
                }
            }
        }
    }

    var cumsum: u64 = 0;
    for (range(reactor_real_size)) |_, i| {
        for (range(reactor_real_size)) |_, j| {
            for (range(reactor_real_size)) |_, k| {
                if (reactor[i][j][k])
                    cumsum += 1;
            }
        }
    }

    print("{d}", .{cumsum});
}
