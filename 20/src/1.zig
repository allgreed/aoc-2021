const std = @import("std");
const og = @import("olgierdlib");

const print = std.log.info;
const range = og.range;

const PointBaseT = i32;
const Point = og.genericPoint(PointBaseT);

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

    const algo_line = (try in_stream.readUntilDelimiterOrEof(&buf, '\n')).?;
    var algo = try allocator.alloc(bool, 512);
    for (algo_line) |c, i| {
        algo[i] = c_to_bool(c);
    }

    _ = try in_stream.readUntilDelimiterOrEof(&buf, '\n'); // empty line

    const initial_border_extension = 1;

    var current_pixels = std.AutoArrayHashMap(Point, void).init(allocator);
    var processing_border_tl: Point = .{ .x = 0 - initial_border_extension, .y = 0 - initial_border_extension };
    var processing_border_br: Point = undefined;
    {
        var j: usize = 0;
        var max_x: PointBaseT = undefined;
        while (try in_stream.readUntilDelimiterOrEof(&buf, '\n')) |line| : (j += 1) {
            if (j == 0)
                max_x = @intCast(PointBaseT, line.len);

            for (line) |c, i| {
                if (c_to_bool(c)) {
                    try current_pixels.put(Point{ .x = @intCast(PointBaseT, i), .y = @intCast(PointBaseT, j) }, {});
                }
            }
        }
        processing_border_br = .{ .x = max_x + initial_border_extension, .y = @intCast(PointBaseT, j) + initial_border_extension };
    }

    var next_pixels = std.AutoArrayHashMap(Point, void).init(allocator);
    var surrounding: bool = false;
    for (range(2)) |_| {
        //dump_pixels(
        //current_pixels,
        //processing_border_tl,
        //processing_border_br,
        //surrounding,
        //);

        for (range(@intCast(usize, processing_border_br.y + 1 - processing_border_tl.y))) |_, _j| {
            const j = processing_border_tl.y + @intCast(PointBaseT, _j);
            for (range(@intCast(usize, processing_border_br.x + 1 - processing_border_tl.x))) |_, _i| {
                const i = processing_border_tl.x + @intCast(PointBaseT, _i);

                const p = Point{ .x = i, .y = j };

                var idx: u10 = 0;

                for (range(3)) |_, _y| {
                    const y: PointBaseT = @intCast(PointBaseT, _y) - 1;
                    for (range(3)) |_, _x| {
                        const x: PointBaseT = @intCast(PointBaseT, _x) - 1;

                        const pp = p.move(x, y);
                        const acc: u1 = if (current_pixels.contains(pp)) 1 else 0;

                        idx <<= 1;
                        idx += acc;

                        if (pp.y >= processing_border_br.y or pp.y <= processing_border_tl.y or pp.x >= processing_border_br.x or pp.x <= processing_border_tl.x) {
                            idx -= acc;
                            const bcc: u1 = if (surrounding) 1 else 0;
                            idx += bcc;
                        }
                    }
                }

                if (algo[idx])
                    try next_pixels.put(p, {});
            }
        }

        surrounding = if (surrounding) algo[511] else algo[0];

        processing_border_tl = processing_border_tl.move(-1, -1);
        processing_border_br = processing_border_br.move(1, 1);

        const tmp_pixels = current_pixels;
        current_pixels = next_pixels;
        next_pixels = tmp_pixels;
        next_pixels.clearRetainingCapacity();
    }

    //dump_pixels(
    //current_pixels,
    //processing_border_tl,
    //processing_border_br,
    //surrounding,
    //);
    //print("{s} {s}", .{ processing_border_tl, processing_border_br });
    print("{d}", .{current_pixels.count()});
}

fn c_to_bool(c: u8) bool {
    return switch (c) {
        '.' => false,
        '#' => true,
        else => unreachable,
    };
}

fn bool_to_c(b: bool) u8 {
    return switch (b) {
        false => '.',
        true => '#',
    };
}

fn is_lit(pp: Point, pixels: std.AutoArrayHashMap(Point, void), processing_border_tl: Point, processing_border_br: Point, surrounding: bool) bool {
    if (pp.y >= processing_border_br.y or pp.y <= processing_border_tl.y or pp.x >= processing_border_br.x or pp.x <= processing_border_tl.x) {
        return surrounding;
    } else {
        return pixels.contains(pp);
    }
}

fn dump_pixels(pixels: std.AutoArrayHashMap(Point, void), btl: Point, bbr: Point, surrounding: bool) void {
    //for (range(@intCast(usize, bbr.y - btl.y))) |_, _j| {
    //const j = btl.y + @intCast(PointBaseT, _j);
    //for (range(@intCast(usize, bbr.x - btl.x))) |_, _i| {
    //const i = btl.x + @intCast(PointBaseT, _i);
    //const p = Point{ .x = i, .y = j };
    //std.debug.print("{c}", .{bool_to_c(pixels.contains(p))});
    //}
    //std.debug.print("\n", .{});
    //}

    for (range(10)) |_, _j| {
        const j = bbr.y - 10 + @intCast(PointBaseT, _j) + 2;
        for (range(20)) |_, _i| {
            const i = bbr.x - 20 + 2 + @intCast(PointBaseT, _i);
            const pp = Point{ .x = i, .y = j };

            if (pp.y >= bbr.y or pp.y <= btl.y or pp.x >= bbr.x or pp.x <= btl.x) {
                std.debug.print("{c}", .{'x'});
            } else {
                std.debug.print("{c}", .{bool_to_c(is_lit(pp, pixels, btl, bbr, surrounding))});
            }
        }
        std.debug.print("\n", .{});
    }
    print("-----", .{});
}
