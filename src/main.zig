const std = @import("std");
const cli = @import("cli.zig");
const engine = @import("engine.zig");

const Dir = std.fs.Dir;
const IterableDir = std.fs.IterableDir;

const ArenaAllocator = std.heap.ArenaAllocator;
var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
const allocator = arena.allocator();

pub fn main() !void {
    const args = try cli.initArgs(allocator);
    const paths = try engine.searchFiles(allocator, args);
    defer paths.deinit();

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
