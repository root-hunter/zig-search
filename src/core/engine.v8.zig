// MULTITHREAD ENGINE

const std = @import("std");
const cli = @import("cli.zig");
const engine = @import("engine.zig");

pub var filePathToDoStack: std.ArrayList([]const u8) = undefined;
pub var filePathMatchStack: std.ArrayList(engine.FindResult) = undefined;

pub var lock: std.Thread.Mutex = .{};

pub const ThreadContext = struct {
    thread: std.Thread,
    finish: bool = false,
};

pub var threadPool: std.ArrayList(ThreadContext) = undefined;
pub var scanEnded = false;

pub fn init(allocator: std.mem.Allocator, args: cli.Arguments) void {
    filePathToDoStack = std.ArrayList([]const u8).init(allocator);
    filePathMatchStack = std.ArrayList(engine.FindResult).init(allocator);
    threadPool = std.ArrayList(ThreadContext).init(allocator);

    if (!args.isBinary and !args.caseSensitive) {
         engine.convertToLowerCase(&args.searchString);
    }
}

pub fn runOnEachThread(allocator: std.mem.Allocator, args: cli.Arguments, iThread: usize) !void {
    while (try dequeue(allocator)) |filePath| {
        const result = try engine.findMatchOnce(allocator, args, &filePath);

        if (result != null) {
            std.log.info("Thread {} FOUND match at position {} in: {s}", .{ iThread, result.?.offset, result.?.filePath });
        }
    }

    threadPool.items[iThread].finish = true;
}

fn dequeue(allocator: std.mem.Allocator) !?[]u8 {
    var isLock = lock.tryLock();

    while (!isLock) {
        isLock = lock.tryLock();
    }

    if (isLock) {
        const data: ?[]const u8 = filePathToDoStack.popOrNull();
        defer lock.unlock();

        if (data != null) {
            const dataCopy: []u8 = try allocator.alloc(u8, data.?.len);
            std.mem.copyBackwards(u8, dataCopy, data.?);

            return dataCopy;
        } else {
            return null;
        }
    } else {
        return null;
    }
}
