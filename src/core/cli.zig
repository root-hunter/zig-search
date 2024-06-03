const std = @import("std");
const utils = @import("utils.zig");

pub const Arguments = struct {
    startPath: []u8 = "",
    exportPath: [] const u8 = undefined,
    exportInfo: bool = true,
    searchString: []u8 = "",
    caseSensitive: bool = false,
    allMatch: bool = false,
    maxFileSize: usize = 1024 * 1024 * 256,
    threadCount: usize = 1,
    fileExtensions: std.ArrayList([]const u8),

    pub fn clone(self: Arguments, allocator: std.mem.Allocator) !Arguments {
        const startPath = try allocator.alloc(u8, self.startPath.len);
        std.mem.copyBackwards(u8, startPath, self.startPath);

        const searchString = try allocator.alloc(u8, self.searchString.len);
        std.mem.copyBackwards(u8, searchString, self.searchString);

        return Arguments{ .caseSensitive = self.caseSensitive, .allMatch = self.allMatch, .maxFileSize = self.maxFileSize, .threadCount = self.threadCount, .fileExtensions = try self.fileExtensions.clone(), .searchString = searchString, .startPath = startPath };
    }

    pub fn getFileExtensionsString(self: Arguments, allocator: std.mem.Allocator) ![] u8 {
        const result = try std.mem.join(allocator, ",", self.fileExtensions.items);

        return result;
    }
};

pub fn initArgs(allocator: std.mem.Allocator) !Arguments {
    var arguments = Arguments{ .fileExtensions = std.ArrayList([]const u8).init(allocator) };

    var argsIterator = try std.process.ArgIterator.initWithAllocator(allocator);
    defer argsIterator.deinit();
    _ = argsIterator.next();

    if (argsIterator.next()) |path| {
        arguments.startPath = @constCast(path);
        std.debug.print("Start directory: {s}\n", .{path});
    } else {
        std.debug.print("No args\n", .{});
    }

    if (argsIterator.next()) |searchString| {
        arguments.searchString = @constCast(searchString);

        std.debug.print("Search string: {s}\n", .{searchString});
    } else {
        std.debug.print("No args\n", .{});
    }

    while (argsIterator.next()) |searchString| {
        if (utils.checkStringInChoices(searchString, .{"-c", "--case-sensitive"})) {
            std.log.info("Case sensitive: ON", .{});

            arguments.caseSensitive = true;
        } else if (std.mem.eql(u8, searchString, "-f") or std.mem.eql(u8, searchString, "--file-extensions")) {
            const value = argsIterator.next();

            if (value != null) {
                var it = std.mem.split(u8, value.?, ",");
                while (it.next()) |ext| {
                    try arguments.fileExtensions.append(ext);
                }
                std.log.info("Custom extensions: {s}", .{value.?});
            } else {
                std.log.err("Not valid file extensions, the extensions must be in this form: txt,js,c,cpp \n", .{});
            }
        } else if (std.mem.eql(u8, searchString, "-t") or std.mem.eql(u8, searchString, "--thread-count")) {
            const value = argsIterator.next();

            if (value != null) {
                const parsed = try std.fmt.parseUnsigned(usize, value.?, 10);

                if (parsed == 0) {
                    arguments.threadCount = try std.Thread.getCpuCount();
                } else {
                    arguments.threadCount = parsed;
                }

                std.log.info("Thread count: {}", .{parsed});
            } else {
                std.log.err("Not valid thread count \n", .{});
            }
        } else if (std.mem.eql(u8, searchString, "-e") or std.mem.eql(u8, searchString, "--export-path")) {
            const value = argsIterator.next();

            if (value != null) {
                const data = try allocator.alloc(u8, value.?.len);
                std.mem.copyBackwards(u8, data, value.?);

                arguments.exportPath = data;

                std.log.info("Export path: {s}", .{data});
            } else {
                std.log.err("Not valid export path \n", .{});
            }
        } else if (std.mem.eql(u8, searchString, "-a") or std.mem.eql(u8, searchString, "--all-match")) {
            arguments.allMatch = true;
        } else if (std.mem.eql(u8, searchString, "--export-no-info")) {
            arguments.exportInfo = false;
        }
    }

    return arguments;
}
