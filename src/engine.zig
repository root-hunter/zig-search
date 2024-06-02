const std = @import("std");
const cli = @import("cli.zig");
const File = std.fs.File;
const engineV8 = @import("engineV8.zig");


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

const FindResult = struct { offset: usize, filePath: []const u8 };

pub fn convertToLowerCase(slice: *const []u8) void {
    var i: usize = 0;
    while (i < slice.len) {
        (slice.*)[i] = std.ascii.toLower((slice.*)[i]);
        i += 1;
    }
}

pub fn findMatchOnce(allocator: std.mem.Allocator, args: cli.Arguments, filePath: *const []const u8) !?FindResult {
    const fileOpenOptions = std.fs.File.OpenFlags{ .mode = std.fs.File.OpenMode.read_only };

    const file: File = try std.fs.openFileAbsolute(filePath.*, fileOpenOptions);
    defer file.close();

    const metadata = try file.metadata();
    const fileSize = metadata.size();

    if (fileSize >= args.searchString.len and fileSize < args.maxFileSize) {
        var bufferReader = std.io.bufferedReader(file.reader());
        const stream = bufferReader.reader();

        const data = try stream.readAllAlloc(allocator, args.maxFileSize);
        defer allocator.free(data);
        var i: usize = 0;

        while (i + args.searchString.len + 1 < data.len) {
            if (data[i] == args.searchString[0]) {
                var slice = data[i..(i + args.searchString.len)];
                
                //var slice = try allocator.alloc(u8, args.searchString.len);
                //const tmp = data[i..(i + args.searchString.len)];
                //_ = std.mem.copyBackwards(u8, slice, tmp);
                
                if (!args.caseSensitive) {
                    convertToLowerCase(&slice);
                }

                const result = std.mem.eql(u8, slice, args.searchString);
                if (result) {
                    if (!args.allMatch) {
                        return FindResult{ .offset = i, .filePath = filePath.* };
                    }
                }

                i += args.searchString.len;
            } else {
                i += 1;
            }
        }
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
    if (!args.caseSensitive) {
        convertToLowerCase(&args.searchString);
    }

    const dir = try std.fs.openDirAbsolute(args.startPath, openDirOptions);

    var walker = try dir.walk(allocator);
    defer walker.deinit();

    while (try walker.next()) |entry| {
        const path = [_][]const u8{ args.startPath, entry.path };
        if (entry.kind == std.fs.File.Kind.file) {
            const flag = try checkFileExtension(args, entry);

            var string: []u8 = undefined;
            if (flag) {
                const filePath = try std.fs.path.join(allocator, &path);
                defer allocator.free(filePath);

                string = try allocator.alloc(u8, filePath.len);

                std.mem.copyBackwards(u8, string, filePath);
                try engineV8.stack.append(string);
            }
        }
    }
}
