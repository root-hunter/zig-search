const std = @import("std");

pub const Arguments = struct {
    startPath: []u8 = "",
    searchString: []u8 = "",
    caseSensitive: bool = false,
    allMatch: bool = false,
    fileExtensions: std.ArrayList([]const u8),
};

pub fn initArgs(allocator: std.mem.Allocator) !Arguments {
    var arguments = Arguments{
        .fileExtensions = std.ArrayList([]const u8).init(allocator)
    };

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
        //const buf = try allocator.alloc(u8, searchString.len - 2);
        //std.mem.copyBackwards(u8, buf, searchString[1..(searchString.len - 2)]);
        arguments.searchString = @constCast(searchString);

        std.debug.print("Search string: {s}\n", .{searchString});
    } else {
        std.debug.print("No args\n", .{});
    }

    while (argsIterator.next()) |searchString| {
        if (std.mem.eql(u8, searchString, "--case-sensitive")) {
            std.log.info("Case sensitive: ON", .{});

            arguments.caseSensitive = true;
        } else if (std.mem.eql(u8, searchString, "--file-extensions")) {
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
        } else if (std.mem.eql(u8, searchString, "--all-match")) {
            arguments.allMatch = true;
        }
    }

    return arguments;
}