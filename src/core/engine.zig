const std = @import("std");
const cli = @import("cli.zig");
const File = std.fs.File;
const engineV8 = @import("engine.v8.zig");

const EngineError = error{NotValidLoadedPaths};

pub fn checkFileExtension(
    args: cli.Arguments,
    entry: std.fs.Dir.Walker.Entry,
) !bool {
    var flag = false;
    var i: usize = 0;

    while (i < args.fileExtensions.items.len) {
        const ext = args.fileExtensions.items[i];

        var it = std.mem.split(u8, entry.path, ".");
        var fileExt: []const u8 = "";

        while (it.next()) |fe| {
            fileExt = fe;
        }

        if (std.mem.eql(u8, fileExt, ext)) {
            flag = true;
            break;
        }

        i += 1;
    }

    return flag;
}

pub const FindResult = struct { offset: usize, filePath: []const u8 };

pub fn convertToLowerCase(slice: *const []u8) void {
    var i: usize = 0;
    while (i < slice.len) {
        (slice.*)[i] = std.ascii.toLower((slice.*)[i]);
        i += 1;
    }
}

pub fn findMatchOnce(allocator: std.mem.Allocator, args: cli.Arguments, filePath: *const []const u8) !?FindResult {
    const fileOpenOptions = std.fs.File.OpenFlags{ .mode = std.fs.File.OpenMode.read_only };

    if (std.fs.path.isAbsolute(filePath.*)) {
        std.log.debug("FILE PATH: {s}", .{filePath.*});

        const file: File = try std.fs.openFileAbsolute(filePath.*, fileOpenOptions);
        defer file.close();

        const metadata = try file.metadata();
        const fileSize = metadata.size();

        var isLock = engineV8.lock.tryLock();

        while (!isLock) {
            isLock = engineV8.lock.tryLock();
        }
        defer engineV8.lock.unlock();

        const searchString = try allocator.alloc(u8, args.searchString.len);
        std.mem.copyBackwards(u8, searchString, args.searchString);
        defer allocator.free(searchString);

        if (fileSize >= searchString.len and fileSize < args.maxFileSize) {
            var bufferReader = std.io.bufferedReader(file.reader());
            const stream = bufferReader.reader();

            const data = try stream.readAllAlloc(allocator, args.maxFileSize);
            defer allocator.free(data);

            var i: usize = 0;

            while (i + searchString.len + 1 < data.len) {
                if (data[i] == searchString[0]) {
                    const slice: []u8 = data[i..(i + searchString.len)];

                    if (!args.isBinary and !args.caseSensitive) {
                        convertToLowerCase(&slice);
                    }

                    const hasMatch = std.mem.eql(u8, slice, searchString);

                    if (hasMatch) {
                        if (!args.allMatch) {
                            const result = FindResult{ .offset = i, .filePath = filePath.* };
                            try engineV8.filePathMatchStack.append(result);

                            return result;
                        }
                    }

                    if (args.isBinary) {
                        i += 1;
                    } else {
                        i += args.searchString.len;
                    }
                } else {
                    i += 1;
                }
            }
        }
    } else {
        return null;
    }

    return null;
}

const openDirOptions = std.fs.Dir.OpenDirOptions{
    .access_sub_paths = true,
    .iterate = true,
};

pub fn searchFiles(
    allocator: std.mem.Allocator,
    args: cli.Arguments,
) !void {
    const dir = try std.fs.openDirAbsolute(args.startPath, openDirOptions);

    var walker = try dir.walk(allocator);
    defer walker.deinit();

    while (try walker.next()) |entry| {
        const paths = [_][]const u8{ args.startPath, entry.path };
        if (entry.kind == std.fs.File.Kind.file) {
            const flag = try checkFileExtension(args, entry);

            var string: []u8 = undefined;
            if (flag) {
                const filePath = try std.fs.path.join(allocator, &paths);
                defer allocator.free(filePath);

                string = try allocator.alloc(u8, filePath.len);
                std.mem.copyBackwards(u8, string, filePath);

                try engineV8.filePathToDoStack.append(string);
            }
        }
    }
}

pub fn loadFromListFile(
    args: cli.Arguments,
) !void {
    var i: usize = 0;
    var isLock = engineV8.lock.tryLock();

    if (args.searchFiles.items.ptr != undefined and args.searchFiles.items.len > 0) {
        while (!isLock) {
            isLock = engineV8.lock.tryLock();
        }

        while (i < args.searchFiles.items.len) {
            try engineV8.filePathToDoStack.append(args.searchFiles.items[i]);

            i += 1;
        }

        engineV8.lock.unlock();
    } else {
        return EngineError.NotValidLoadedPaths;
    }
}
