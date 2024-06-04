const std = @import("std");

const cli = @import("core/cli.zig");
const engine = @import("core/engine.zig");
const engineV8 = @import("core/engine.v8.zig");
const exportUtils = @import("core/engine.export.zig");

const Dir = std.fs.Dir;
const IterableDir = std.fs.IterableDir;

const ArenaAllocator = std.heap.ArenaAllocator;
var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
const allocator = arena.allocator();

pub fn main() !void {
    defer engineV8.threadPool.deinit();
    engineV8.init(allocator);

    const args = try cli.initArgs(allocator);
    try engine.searchFiles(allocator, args);
    defer engineV8.filePathToDoStack.deinit();

    var k: usize = 0;

    while (k < args.threadCount) {
        const argsCopy = try args.clone(allocator);

        const thread = try std.Thread.spawn(.{}, engineV8.runOnEachThread, .{
            @as(std.mem.Allocator, allocator),
            @as(cli.Arguments, argsCopy),
            @as(usize, k)
        });

        try engineV8.threadPool.append(engineV8.ThreadContext{
            .thread = thread
        });
        k += 1;
    }

    while (!engineV8.scanEnded) {
        var j: usize = 0;
        var flag: ?bool = null;

        while (j < engineV8.threadPool.items.len) {
            if(flag == null){
                flag = engineV8.threadPool.items[j].finish;
            } else {
                flag = flag.? and engineV8.threadPool.items[j].finish;
            }
            j += 1;
        }

        if(flag != null and flag.?){
            engineV8.scanEnded = true;
    
            if(args.exportPath.ptr != undefined and args.exportPath.len > 0){
                try exportUtils.exportResults(allocator, args, engineV8.filePathMatchStack);
            }
        }
    }    
}
