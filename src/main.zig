const std = @import("std");
const cli = @import("cli.zig");
const engine = @import("engine.zig");

const Dir = std.fs.Dir;
const IterableDir = std.fs.IterableDir;

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
    while (i < paths.items.len) {
        const filePath = paths.items[i];
        const result = try engine.findMatchOnce(allocator, args, filePath);

        if(result != null){
            std.log.info("FOUND match at position {} in: {s}", .{ result.?.offset, result.?.filePath });
        }

        i += 1;
    }
}
