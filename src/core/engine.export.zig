const std = @import("std");
const cli = @import("cli.zig");
const engine = @import("engine.zig");
const engineV8 = @import("engine.v8.zig");

const createFlags: std.fs.File.CreateFlags = .{};

pub fn exportResults(allocator: std.mem.Allocator, args: cli.Arguments, results: std.ArrayList(engine.FindResult)) !void {
    var isLock = engineV8.lock.tryLock();

    while (!isLock and !engineV8.scanEnded) {
        isLock = engineV8.lock.tryLock();
    }

    if (args.exportPath.ptr != undefined and args.exportPath.len > 0) {
        const filePath: []const u8 = args.exportPath;

        std.log.info("Export path: {s}", .{filePath});
        const file = try std.fs.createFileAbsolute(args.exportPath, createFlags);

        var i: usize = 0;
        while (i < results.items.len) {
            const result = results.items[i];

            if (i == 0 and args.exportInfo) {
                const lineBuffer2: []u8 = try allocator.alloc(u8, 4096);

                var line = try std.fmt.bufPrint(lineBuffer2, "# SCAN INFO\n", .{});
                _ = try file.write(line);

                line = try std.fmt.bufPrint(lineBuffer2, "# Searched string: \"{s}\"\n", .{args.searchString});
                _ = try file.write(line);

                line = try std.fmt.bufPrint(lineBuffer2, "# Start directory: {s}\n", .{args.startPath});
                _ = try file.write(line);

                const fileExtensionsString = try args.getFileExtensionsString(allocator);
                line = try std.fmt.bufPrint(lineBuffer2, "# File extensions: {s}\n\n", .{fileExtensionsString});
                _ = try file.write(line);
            }

            const lineBuffer: []u8 = try allocator.alloc(u8, result.filePath.len + 1);
            const line = try std.fmt.bufPrint(lineBuffer, "{s}\n", .{result.filePath});
            _ = try file.write(line);

            i += 1;
        }
    } else {
        std.log.err("Not valid export result path: {s}", .{args.exportPath});
    }
}
