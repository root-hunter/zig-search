const std = @import("std");
const cli = @import("cli.zig");
const File = std.fs.File;

const fileOpenOptions = std.fs.File.OpenFlags{ .mode = std.fs.File.OpenMode.read_only };

pub fn checkFileExtension(
    args: cli.Arguments,
    entry: std.fs.Dir.Walker.Entry,
) !bool {
    var flag = false;
    var k: usize = 0;

    while (k < args.fileExtensions.items.len) {
        const ext = args.fileExtensions.items[k];

        var it = std.mem.split(u8, entry.path, ".");
        var fileExt: []const u8 = "";

        while (it.next()) |fe| {
            fileExt = fe;
        }

        if (std.mem.eql(u8, fileExt, ext)) {
            flag = true;
            break;
        }

        k += 1;
    }

    return flag;
}

const FindResult = struct {
    offset: usize,
    filePath: [] const u8
};

pub fn findMatchOnce(allocator: std.mem.Allocator, args: cli.Arguments, filePath: [] const u8) !?FindResult {
    const file: File = try std.fs.openFileAbsolute(filePath, fileOpenOptions);
    defer file.close();

    const metadata = try file.metadata();
    const fileSize = metadata.size();

    if (fileSize >= args.searchString.len and fileSize < args.maxFileSize) {
        var bufferReader = std.io.bufferedReader(file.reader());
        const stream = bufferReader.reader();
        
        //THREAD
        const data = try stream.readAllAlloc(allocator, args.maxFileSize);
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
                    if (!args.allMatch) {
                        return FindResult{
                            .offset = k,
                            .filePath = filePath
                        };
                    }
                }

                k += args.searchString.len;
            } else {
                k += 1;
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
) !std.ArrayList([]const u8) {
    var paths: std.ArrayList([]const u8) = std.ArrayList([]const u8).init(allocator);

    const dir = try std.fs.openDirAbsolute(args.startPath, openDirOptions);

    var walker = try dir.walk(allocator);
    defer walker.deinit();

    while (try walker.next()) |entry| {
        const path = [_][]const u8{ args.startPath, entry.path };
        if (entry.kind == std.fs.File.Kind.file) {
            const flag = try checkFileExtension(args, entry);

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

    return paths;
}