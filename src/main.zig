const std = @import("std");
const ArenaAllocator = std.heap.ArenaAllocator;
const Dir = std.fs.Dir;
const IterableDir = std.fs.IterableDir;
const File = std.fs.File;

const BUFFER_SIZE = 1024 * 1024 * 128;
var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
const allocator = arena.allocator();
const flags = std.fs.Dir.OpenDirOptions{
    .access_sub_paths = true,
    .iterate = true,
};

const Arguments = struct {
    startPath: []u8 = "",
    searchString: []u8 = "",
    caseSensitive: bool = true,
};

pub fn initArgs() !Arguments {
    var arguments = Arguments{};

    var argsIterator = try std.process.ArgIterator.initWithAllocator(allocator);
    defer argsIterator.deinit();
    _ = argsIterator.next();

    if (argsIterator.next()) |path| {
        arguments.startPath = @constCast(path);
        std.debug.print("Start directory: {s}\n", .{path});
    } else {
        std.debug.print("No args\n", .{});
    }

    if (argsIterator.next()) |searchString| {
        arguments.searchString = @constCast(searchString);
        std.debug.print("Search string: {s}\n", .{searchString});
    } else {
        std.debug.print("No args\n", .{});
    }




    return arguments;
}

pub fn main() !void {
    const args = try initArgs();

    defer arena.deinit();
    const dir = try std.fs.openDirAbsolute(args.startPath, flags);

    var walker = try dir.walk(allocator);
    defer walker.deinit();

    while (try walker.next()) |entry| {
        const paths = &[_][]const u8{ args.startPath, entry.path };

        if (entry.kind == std.fs.File.Kind.file and std.mem.containsAtLeast(u8, entry.path, 1, ".txt")) {
            const filePath = try std.fs.path.join(allocator, paths);
            defer allocator.free(filePath);

            const fileOpenOptions = std.fs.File.OpenFlags{ .mode = std.fs.File.OpenMode.read_only };

            const file: File = try std.fs.openFileAbsolute(filePath, fileOpenOptions);
            defer file.close();

            const metadata = try file.metadata();
            const fileSize = metadata.size();

            if (fileSize < BUFFER_SIZE) {
                var bufferReader = std.io.bufferedReader(file.reader());
                const stream = bufferReader.reader();
                const data = try stream.readAllAlloc(allocator, BUFFER_SIZE);
                defer allocator.free(data);

                var i: usize = 0;

                while (i + args.searchString.len + 1 < data.len) {
                    if (data[i] == args.searchString[0]) {
                        const slice = &data[i..(i + args.searchString.len)];
                        var j: usize = 0;

                        while (j < slice.len) {
                            (slice.*)[j] = std.ascii.toLower((slice.*)[j]);
                            j += 1;
                        }

                        const result = std.mem.eql(u8, (slice.*), args.searchString);

                        if (result) {
                            std.log.info("FOUND match: {s}", .{filePath});
                        }
                        i += args.searchString.len;
                    } else {
                        i += 1;
                    }
                }
            }
        }
    }
}
