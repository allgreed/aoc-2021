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

    const da_line = (try in_stream.readUntilDelimiterOrEof(&buf, '\n')).?;

    var data = std.ArrayList(u8).init(allocator);
    for (range(da_line.len / 2)) |_, i| {
        try data.append(try std.fmt.parseInt(u8, da_line[2 * i .. 2 * i + 1 + 1], 16));
    }

    var main_reader = BitReader{ .data = &data.items, .alloc = allocator };

    print("{d}", .{process_packet(&main_reader)});
}

fn process_packet(reader: *BitReader) u64 {
    const version = reader.read(u3);
    const type_id = reader.read(u3);

    const header = PacketHeader{ .version = version, .type_id = type_id };

    switch (header.type_id) {
        4 => {
            {
                var value: u64 = 0;
                while (reader.read(u1) == 1) {
                    value <<= 4;
                    value += reader.read(u4);
                }

                value <<= 4;
                value += reader.read(u4);

                return value;
            }
        },
        else => {
            const lenght_type = reader.read(u1);
            // this is crap xd, shouldn't be passing an allocator like that ;d
            var values = std.ArrayList(u64).init(reader.alloc);
            defer values.deinit();
            switch (lenght_type) {
                0 => {
                    const bits_lenght = reader.read(u15);
                    const header_end = reader.counter;
                    while (reader.counter < header_end + bits_lenght) {
                        values.append(process_packet(reader)) catch {
                            unreachable;
                        };
                    }
                },
                1 => {
                    const packet_length = reader.read(u11);
                    for (range(packet_length)) |_| {
                        values.append(process_packet(reader)) catch {
                            unreachable;
                        };
                    }
                },
            }

            switch (header.type_id) {
                0 => {
                    var acc: u64 = 0;
                    for (values.items) |v| {
                        acc += v;
                    }
                    return acc;
                },
                1 => {
                    var acc: u64 = 1;
                    for (values.items) |v| {
                        acc *= v;
                    }
                    return acc;
                },
                2 => {
                    var acc: u64 = std.math.maxInt(u64);
                    for (values.items) |v| {
                        acc = std.math.min(acc, v);
                    }
                    return acc;
                },
                3 => {
                    var acc: u64 = 0;
                    for (values.items) |v| {
                        acc = std.math.max(acc, v);
                    }
                    return acc;
                },
                5 => {
                    const self = values.items[0];
                    const other = values.items[1];
                    return if (self > other) 1 else 0;
                },
                6 => {
                    const self = values.items[0];
                    const other = values.items[1];
                    return if (self < other) 1 else 0;
                },
                7 => {
                    const self = values.items[0];
                    const other = values.items[1];
                    return if (self == other) 1 else 0;
                },
                else => unreachable,
            }
            return 5;
        },
    }
}

const BitReader = struct {
    offset: usize = 0,
    counter: usize = 0,
    data: *[]const u8,
    alloc: *std.mem.Allocator,

    pub fn read(self: *BitReader, comptime T: type) T {
        const result = extract_bits_from_bytearray(T, self.data.*, self.offset);
        self.offset += @bitSizeOf(T);
        self.counter += @bitSizeOf(T);
        return result;
    }

    pub fn skip(self: *BitReader, count: usize) void {
        self.offset += count;
        self.counter += count;
    }

    pub fn clone(self: BitReader, offset: usize) BitReader {
        return BitReader{ .data = self.data, .offset = offset, .alloc = self.alloc };
    }
};

fn extract_bits_from_bytearray(comptime T: type, bytes: []const u8, offset: usize) T {
    const _suboffset = @truncate(u3, offset % 8);
    const bits_len = @bitSizeOf(T);

    const span = offset % 8 + bits_len;
    const bytes_count = std.math.divCeil(usize, span, 8) catch {
        // yolo!
        unreachable;
    };
    // TODO: assert bytecount <= 8

    const byte_offset = offset / 8;
    const suboffset = offset % 8;
    //print("{d} {d} {d} {d} {d}", .{ bytes_count * 8, suboffset, bits_len, offset, span });
    const shift = @intCast(u5, (bytes_count * 8 - suboffset - bits_len));

    var input: u64 = bytes[byte_offset];
    for (range(bytes_count - 1)) |_, _i| {
        const i = _i + 1 + byte_offset;
        input <<= 8;
        input += bytes[i];
    }

    return @truncate(T, input >> shift);
}

const PacketHeader = struct {
    version: u3,
    type_id: u3,
};
