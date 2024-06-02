// MULTITHREAD ENGINE

const std = @import("std");
const cli = @import("cli.zig");
const engine = @import("engine.zig");

const ArenaAllocator = std.heap.ArenaAllocator;
var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
const allocator = arena.allocator();

pub var stack: std.ArrayList([]const u8) = std.ArrayList([]const u8).init(allocator);
pub var lock: std.Thread.Mutex = .{};

pub const ThreadContext = struct {
    thread: std.Thread,
    finish: bool = false,
};

pub var threadPool = std.ArrayList(ThreadContext).init(allocator);
pub var scanEnded = false;

pub fn runOnEachThread(args: cli.Arguments, iThread: usize) !void {
    while (dequeue()) |task| {
        const filePath = task.*;
        const result = try engine.findMatchOnce(allocator, args, &filePath);

        if (result != null) {
            std.log.info("Thread {} FOUND match at position {} in: {s}", .{ iThread, result.?.offset, result.?.filePath });
        }
    }

    threadPool.items[iThread].finish = true;
}

fn dequeue() ?*const [] const u8 {
    const held = lock.tryLock();

    if (held) {
        const data: ?[] const u8 = stack.popOrNull();
        lock.unlock();
        if (data != null) {
            return &(data.?);
        } else {
            return null;
        }
    } else {
        return null;
    }
}