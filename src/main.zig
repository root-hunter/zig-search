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
    caseSensitive: bool = false,
    fileExtensions: std.ArrayList([]const u8) = std.ArrayList([]const u8).init(allocator),
};
var arguments = Arguments{};

pub fn initArgs() !void {
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

    while (argsIterator.next()) |searchString| {
        if (std.mem.eql(u8, searchString, "--case-sensitive")) {
            std.log.info("Case sensitive: ON", .{});

            arguments.caseSensitive = true;
        } else if (std.mem.eql(u8, searchString, "--file-extensions")) {
            const value = argsIterator.next();

            if (value != null) {
                var it = std.mem.split(u8, value.?, ",");
                while (it.next()) |ext| {
                    try arguments.fileExtensions.append(ext);
                }
                std.log.info("Custom extensions: {s}", .{value.?});
            } else {
                std.log.err("Not valid file extensions, the extensions must be in this form: txt,js,c,cpp \n", .{});
            }
        }
    }
}

pub fn processData(args: Arguments) void {
    _ = args;
}

pub fn main() !void {
    defer arena.deinit();

    try initArgs();

    const dir = try std.fs.openDirAbsolute(arguments.startPath, flags);

    var paths = std.ArrayList([]const u8).init(allocator);

    var walker = try dir.walk(allocator);
    defer walker.deinit();

    while (try walker.next()) |entry| {
        const path = [_][]const u8{ arguments.startPath, entry.path };
        if (entry.kind == std.fs.File.Kind.file) {
            var flag = false;
            var k: usize = 0;
            while (k < arguments.fileExtensions.items.len) {
                const ext = arguments.fileExtensions.items[k];
               
                var it = std.mem.split(u8, entry.path, ".");
                var fileExt: [] const u8 = "";

                while (it.next()) |fe| {
                    fileExt = fe;
                }

                if (std.mem.eql(u8, fileExt, ext)) {
                    flag = true;
                    break;
                }

                k += 1;
            }

            if (flag) {
                const filePath = try std.fs.path.join(allocator, &path);
                defer allocator.free(filePath);

                const string = try allocator.alloc(u8, filePath.len);
                std.mem.copyBackwards(u8, string, filePath);
                try paths.append(string);
            }
        }
    }

    var i: usize = 0;
    while (i < paths.items.len) {
        const filePath = paths.items[i];
        const fileOpenOptions = std.fs.File.OpenFlags{ .mode = std.fs.File.OpenMode.read_only };
        const file: File = try std.fs.openFileAbsolute(filePath, fileOpenOptions);
        defer file.close();
        const metadata = try file.metadata();
        const fileSize = metadata.size();
        if (fileSize < BUFFER_SIZE) {
            var bufferReader = std.io.bufferedReader(file.reader());
            const stream = bufferReader.reader();
            //THREAD
            const data = try stream.readAllAlloc(allocator, BUFFER_SIZE);
            defer allocator.free(data);
            var k: usize = 0;
            while (k + arguments.searchString.len + 1 < data.len) {
                if (data[k] == arguments.searchString[0]) {
                    const slice = &data[k..(k + arguments.searchString.len)];
                    var j: usize = 0;
                    while (j < slice.len) {
                        (slice.*)[j] = std.ascii.toLower((slice.*)[j]);
                        j += 1;
                    }
                    const result = std.mem.eql(u8, (slice.*), arguments.searchString);
                    if (result) {
                        std.log.info("FOUND match: {s}", .{filePath});
                    }
                    k += arguments.searchString.len;
                } else {
                    k += 1;
                }
            }
        }
        i += 1;
    }
}
