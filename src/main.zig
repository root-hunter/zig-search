const std = @import("std");
const cli = @import("cli.zig");
const engine = @import("engine.zig");

const Dir = std.fs.Dir;
const IterableDir = std.fs.IterableDir;
const File = std.fs.File;

const BUFFER_SIZE = 1024 * 1024 * 256;

const ArenaAllocator = std.heap.ArenaAllocator;
var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
const allocator = arena.allocator();

const flags = std.fs.Dir.OpenDirOptions{
    .access_sub_paths = true,
    .iterate = true,
};

pub fn main() !void {
    defer arena.deinit();

    const args = try cli.initArgs(allocator);

    const dir = try std.fs.openDirAbsolute(args.startPath, flags);

    var paths: std.ArrayList([]const u8) = std.ArrayList([]const u8).init(allocator);

    var walker = try dir.walk(allocator);
    defer walker.deinit();

    while (try walker.next()) |entry| {
        const path = [_][]const u8{ args.startPath, entry.path };
        if (entry.kind == std.fs.File.Kind.file) {
            const flag = try engine.checkFileExtension(args, entry);

            var string: [] u8 = undefined;
            if (flag) {
                const filePath = try std.fs.path.join(allocator, &path);
                defer allocator.free(filePath);
                
                string = try allocator.alloc(u8, filePath.len);
                
                std.mem.copyBackwards(u8, string, filePath);
                try paths.append(string);
            }
        }
    }

    std.log.info("FOUND {} files to be scanned", .{paths.items.len});

    var i: usize = 0;
    const fileOpenOptions = std.fs.File.OpenFlags{ .mode = std.fs.File.OpenMode.read_only };
    while (i < paths.items.len) {
        const filePath = paths.items[i];
        const file: File = try std.fs.openFileAbsolute(filePath, fileOpenOptions);
        defer file.close();
        const metadata = try file.metadata();
        const fileSize = metadata.size();
        if (fileSize >= args.searchString.len and fileSize < BUFFER_SIZE) {
            var bufferReader = std.io.bufferedReader(file.reader());
            const stream = bufferReader.reader();
            //THREAD
            const data = try stream.readAllAlloc(allocator, BUFFER_SIZE);
            defer allocator.free(data);
            var k: usize = 0;

            while (k + args.searchString.len + 1 < data.len) {
                if (data[k] == args.searchString[0]) {
                    const slice = &data[k..(k + args.searchString.len)];
                    var j: usize = 0;
                    while (j < slice.len) {
                        (slice.*)[j] = std.ascii.toLower((slice.*)[j]);
                        j += 1;
                    }
                    const result = std.mem.eql(u8, (slice.*), args.searchString);
                    if (result) {
                        std.log.info("FOUND match at position {} in: {s}", .{ k, filePath });

                        if (!args.allMatch) {
                            break;
                        }
                    }

                    k += args.searchString.len;
                } else {
                    k += 1;
                }
            }
        }
        i += 1;
    }
}
