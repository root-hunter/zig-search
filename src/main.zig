const std = @import("std");
const cli = @import("cli.zig");
const engine = @import("engine.zig");

const engineV8 = @import("engineV8.zig");

const Dir = std.fs.Dir;
const IterableDir = std.fs.IterableDir;

const ArenaAllocator = std.heap.ArenaAllocator;
var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
const allocator = arena.allocator();

pub fn main() !void {
    defer engineV8.threadPool.deinit();

    const args = try cli.initArgs(allocator);
    try engine.searchFiles(allocator, args);
    defer engineV8.stack.deinit();

    var k: usize = 0;
    //const cpuCount = try std.Thread.getCpuCount();

    while (k < args.threadCount) {
        const thread = try std.Thread.spawn(.{}, engineV8.runOnEachThread, .{@as(cli.Arguments, args), @as(usize, k)});

        try engineV8.threadPool.append(engineV8.ThreadContext{
            .thread = thread
        });
        k += 1;
    }

    while (!engineV8.scanEnded) {
        var j: usize = 0;
        var flag = true;

        while (j < engineV8.threadPool.items.len) {
            flag = flag and engineV8.threadPool.items[j].finish;

            j += 1;
        }

        if(flag){
            engineV8.scanEnded = true;
        }
    }
}
