const std = @import("std");
const utils = @import("utils.zig");

pub const Arguments = struct {
    startPath: []u8 = "",
    exportPath: []const u8 = undefined,
    exportInfo: bool = true,
    exportMatchPosition: bool = false,
    searchString: []u8 = "",
    caseSensitive: bool = false,
    allMatch: bool = false,
    maxFileSize: usize = 1024 * 1024 * 256,
    threadCount: usize = 1,
    fileExtensions: std.ArrayList([]const u8) = undefined,
    rawArguments: std.ArrayList([]const u8) = undefined,

    pub fn clone(self: Arguments, allocator: std.mem.Allocator) !Arguments {
        const startPath = try allocator.alloc(u8, self.startPath.len);
        std.mem.copyBackwards(u8, startPath, self.startPath);

        const searchString = try allocator.alloc(u8, self.searchString.len);
        std.mem.copyBackwards(u8, searchString, self.searchString);

        return Arguments{ .caseSensitive = self.caseSensitive, .allMatch = self.allMatch, .maxFileSize = self.maxFileSize, .threadCount = self.threadCount, .fileExtensions = try self.fileExtensions.clone(), .searchString = searchString, .startPath = startPath };
    }

    pub fn getFileExtensionsString(self: Arguments, allocator: std.mem.Allocator) ![]u8 {
        const result = try std.mem.join(allocator, ",", self.fileExtensions.items);

        return result;
    }
};

pub fn initArgs(allocator: std.mem.Allocator) !?Arguments {
    var commandsCaseSensitive: std.ArrayList([]const u8) = std.ArrayList([]const u8).init(allocator);
    try commandsCaseSensitive.append("-c");
    try commandsCaseSensitive.append("--case-sensitive");
    //defer commandsCaseSensitive.deinit();

    var commandsFileExtemsions: std.ArrayList([]const u8) = std.ArrayList([]const u8).init(allocator);
    try commandsFileExtemsions.append("-f");
    try commandsFileExtemsions.append("--file-extensions");
    //defer commandsFileExtemsions.deinit();

    var commandsThreadCount: std.ArrayList([]const u8) = std.ArrayList([]const u8).init(allocator);
    try commandsThreadCount.append("-t");
    try commandsThreadCount.append("--thread-count");
    //defer commandsThreadCount.deinit();

    var commandsExportResults: std.ArrayList([]const u8) = std.ArrayList([]const u8).init(allocator);
    try commandsExportResults.append("-e");
    try commandsExportResults.append("--export-results");
    //defer commandsExportResults.deinit();

    var commandsAllMatch: std.ArrayList([]const u8) = std.ArrayList([]const u8).init(allocator);
    try commandsAllMatch.append("-a");
    try commandsAllMatch.append("--all-match");
    //defer commandsAllMatch.deinit();

    var commandsExportNoInfo: std.ArrayList([]const u8) = std.ArrayList([]const u8).init(allocator);
    try commandsExportNoInfo.append("--export-no-info");
    //defer commandsExportNoInfo.deinit();

    var commandsExportMatchPostion: std.ArrayList([]const u8) = std.ArrayList([]const u8).init(allocator);
    try commandsExportMatchPostion.append("--export-match-postion");
    //defer commandsExportMatchPostion.deinit();

    var commandsHelp: std.ArrayList([]const u8) = std.ArrayList([]const u8).init(allocator);
    try commandsHelp.append("-h");
    try commandsHelp.append("--help");
    //defer commandsHelp.deinit();

    var arguments = Arguments{ .fileExtensions = std.ArrayList([]const u8).init(allocator) };
    arguments.rawArguments = std.ArrayList([]const u8).init(allocator);

    var argsIterator = try std.process.ArgIterator.initWithAllocator(allocator);
    defer argsIterator.deinit();
    _ = argsIterator.next();

    while (argsIterator.next()) |arg| {
        try arguments.rawArguments.append(arg);
    }

    if (arguments.rawArguments.items.len == 1) {
        const searchString = arguments.rawArguments.items[0];

        const helpString =
            \\zig-search - High-performance search utility written entirely in Zig
            \\
            \\START_PATH: The starting directory path (ABSOLUTE)
            \\SEARCH_STRING: String to search
            \\ 
            \\Usage: zig-search START_PATH SEARCH_STRING [OPTIONS]...
            \\
            \\Options:
            \\  --help                           Help command
            \\  -f, --file-extensions            File extensions, in this form: txt,js | js,c,cpp
            \\  -t, --thread-count               Scan thread count (Default: 1)
            \\  -a, --all-match                  Match all the occurence in the file (Default: false)
            \\  -c, --case-sensitive             Case sensitive search (Default: false)
            \\Export options:
            \\  -e, --export-path                File export path (ABSOLUTE)
            \\  --export-no-info                 Disable info header in the export file
            \\  --export-match-position          Add match position info for each path in the export file
            \\
            \\Examples:
            \\1) zig-search /home "password" -f txt -e ${CURDIR}/Documents/zig-search_result.txt
            \\2) zig-search /home "password" -t 16 -f txt,js,cpp,dart -e ${CURDIR}/Documents/zig-search_result.txt
            \\
            \\Repo: https://github.com/root-hunter/zig-search
            \\
            \\Copyright (c) 2024 Antonio Ricciardi
            \\Permission is hereby granted, free of charge, to any person
            \\obtaining a copy of this software and associated documentation
            \\files (the "Software"), to deal in the Software without
            \\restriction, including without limitation the rights to use,
            \\copy, modify, merge, publish, distribute, sublicense, and/or sell
            \\copies of the Software, and to permit persons to whom the
            \\
            \\Software is furnished to do so, subject to the following
            \\conditions:
            \\
            \\The above copyright notice and this permission notice shall be
            \\included in all copies or substantial portions of the Software.
            \\THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
            \\EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES
            \\OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
            \\NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT
            \\HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
            \\WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
            \\FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
            \\OTHER DEALINGS IN THE SOFTWARE.
        ;

        if (utils.checkStringInChoices(searchString, commandsHelp)) {
            std.log.info("{s}", .{helpString});
            return null;
        }
    } else if (arguments.rawArguments.items.len > 1) {
        const startDirArg = arguments.rawArguments.items[0];
        const searchStringArg = arguments.rawArguments.items[1];

        if (startDirArg.len > 0) {
            arguments.startPath = @constCast(startDirArg);
            std.debug.print("Start directory: {s}\n", .{startDirArg});
        } else {
            std.debug.print("No args\n", .{});
        }

        if (searchStringArg.len > 0) {
            arguments.searchString = @constCast(searchStringArg);

            std.debug.print("Search string: {s}\n", .{searchStringArg});
        } else {
            std.debug.print("No args\n", .{});
        }

        var i: usize = 2;
        while (i < arguments.rawArguments.items.len) {
            const argString = arguments.rawArguments.items[i];

            std.log.debug("{s}", .{argString});
            if (utils.checkStringInChoices(argString, commandsCaseSensitive)) {
                std.log.info("Case sensitive: ON", .{});

                arguments.caseSensitive = true;
            } else if (utils.checkStringInChoices(argString, commandsFileExtemsions)) {
                const value = arguments.rawArguments.items[i + 1];

                if (value.len > 0) {
                    var it = std.mem.split(u8, value, ",");
                    while (it.next()) |ext| {
                        try arguments.fileExtensions.append(ext);
                    }
                    std.log.info("Custom extensions: {s}", .{value});
                } else {
                    std.log.err("Not valid file extensions, the extensions must be in this form: txt,js,c,cpp \n", .{});
                }

                i += 1;
            } else if (utils.checkStringInChoices(argString, commandsThreadCount)) {
                const value = arguments.rawArguments.items[i + 1];

                if (value.len > 0) {
                    const parsed = try std.fmt.parseUnsigned(usize, value, 10);

                    if (parsed == 0) {
                        arguments.threadCount = try std.Thread.getCpuCount();
                    } else {
                        arguments.threadCount = parsed;
                    }

                    std.log.info("Thread count: {}", .{parsed});

                    i += 1;
                } else {
                    std.log.err("Not valid thread count \n", .{});
                }
            } else if (utils.checkStringInChoices(argString, commandsExportResults)) {
                const value = arguments.rawArguments.items[i + 1];

                if (value.len > 0) {
                    const data = try allocator.alloc(u8, value.len);
                    std.mem.copyBackwards(u8, data, value);

                    arguments.exportPath = data;

                    std.log.info("Export path: {s}", .{data});

                    i += 1;
                } else {
                    std.log.err("Not valid export path \n", .{});
                }
            } else if (utils.checkStringInChoices(argString, commandsAllMatch)) {
                arguments.allMatch = true;
            } else if (utils.checkStringInChoices(argString, commandsExportNoInfo)) {
                arguments.exportInfo = false;
            } else if (utils.checkStringInChoices(argString, commandsExportMatchPostion)) {
                arguments.exportMatchPosition = true;
            }

            i += 1;
        }
    } else {
        std.log.err("Not valid arguments see help command -h, --help", .{});
        return null;
    }

    return arguments;
}
