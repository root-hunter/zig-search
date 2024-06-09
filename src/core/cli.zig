const std = @import("std");
const utils = @import("utils.zig");

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

pub const Arguments = struct {
    startPath: []u8 = "",
    exportPath: []const u8 = undefined,
    exportInfo: bool = true,
    exportMatchPosition: bool = false,
    searchString: []u8 = undefined,
    isBinary: bool = false,
    caseSensitive: bool = false,
    allMatch: bool = false,
    maxFileSize: usize = 1024 * 1024 * 256,
    threadCount: usize = 1,
    fileExtensions: std.ArrayList([]const u8) = undefined,
    rawArguments: std.ArrayList([]const u8) = undefined,
    searchFilesPath: []const u8 = undefined,
    searchFiles: std.ArrayList([]const u8) = undefined,

    pub fn clone(self: Arguments, allocator: std.mem.Allocator) !Arguments {
        const startPath = try allocator.alloc(u8, self.startPath.len);
        std.mem.copyBackwards(u8, startPath, self.startPath);

        const searchString = try allocator.alloc(u8, self.searchString.len);
        std.mem.copyBackwards(u8, searchString, self.searchString);

        return Arguments{
            .caseSensitive = self.caseSensitive,
            .allMatch = self.allMatch,
            .maxFileSize = self.maxFileSize,
            .threadCount = self.threadCount,
            .fileExtensions = try self.fileExtensions.clone(),
            .searchString = searchString,
            .startPath = startPath,
            .isBinary = self.isBinary,
        };
    }

    pub fn getFileExtensionsString(self: Arguments, allocator: std.mem.Allocator) ![]u8 {
        const result = try std.mem.join(allocator, ",", self.fileExtensions.items);

        return result;
    }

    pub fn isLoadedFromListFile(self: Arguments) bool {
        return self.searchFilesPath.ptr != undefined and self.searchFiles.items.len > 0; 
    }
};

pub fn initArgs(allocator: std.mem.Allocator) !?Arguments {
    var commandsCaseSensitive: std.ArrayList([]const u8) = std.ArrayList([]const u8).init(allocator);
    try commandsCaseSensitive.append("-c");
    try commandsCaseSensitive.append("--case-sensitive");
    defer commandsCaseSensitive.deinit();

    var commandsFileExtemsions: std.ArrayList([]const u8) = std.ArrayList([]const u8).init(allocator);
    try commandsFileExtemsions.append("-f");
    try commandsFileExtemsions.append("--file-extensions");
    defer commandsFileExtemsions.deinit();

    var commandsThreadCount: std.ArrayList([]const u8) = std.ArrayList([]const u8).init(allocator);
    try commandsThreadCount.append("-t");
    try commandsThreadCount.append("--thread-count");
    defer commandsThreadCount.deinit();

    var commandsExportResults: std.ArrayList([]const u8) = std.ArrayList([]const u8).init(allocator);
    try commandsExportResults.append("-e");
    try commandsExportResults.append("--export-results");
    defer commandsExportResults.deinit();

    var commandsAllMatch: std.ArrayList([]const u8) = std.ArrayList([]const u8).init(allocator);
    try commandsAllMatch.append("-a");
    try commandsAllMatch.append("--all-match");
    defer commandsAllMatch.deinit();

    var commandsExportNoInfo: std.ArrayList([]const u8) = std.ArrayList([]const u8).init(allocator);
    try commandsExportNoInfo.append("--export-no-info");
    defer commandsExportNoInfo.deinit();

    var commandsExportMatchPostion: std.ArrayList([]const u8) = std.ArrayList([]const u8).init(allocator);
    try commandsExportMatchPostion.append("--export-match-postion");
    defer commandsExportMatchPostion.deinit();

    var commandsHelp: std.ArrayList([]const u8) = std.ArrayList([]const u8).init(allocator);
    try commandsHelp.append("-h");
    try commandsHelp.append("--help");
    defer commandsHelp.deinit();

    var commandsSearchString: std.ArrayList([]const u8) = std.ArrayList([]const u8).init(allocator);
    try commandsSearchString.append("-s");
    try commandsSearchString.append("--search-string");
    defer commandsSearchString.deinit();

    var commandsSearchBinary: std.ArrayList([]const u8) = std.ArrayList([]const u8).init(allocator);
    try commandsSearchBinary.append("-S");
    try commandsSearchBinary.append("--search-binary");
    defer commandsSearchBinary.deinit();

    var commandsSearchFilesPath: std.ArrayList([]const u8) = std.ArrayList([]const u8).init(allocator);
    try commandsSearchFilesPath.append("-sF");
    try commandsSearchFilesPath.append("--search-files-list");
    defer commandsSearchFilesPath.deinit();


    var commandsSearchStartDir: std.ArrayList([]const u8) = std.ArrayList([]const u8).init(allocator);
    try commandsSearchStartDir.append("-d");
    try commandsSearchStartDir.append("--start-dir");
    defer commandsSearchStartDir.deinit();

    var arguments = Arguments{ .fileExtensions = std.ArrayList([]const u8).init(allocator) };
    arguments.rawArguments = std.ArrayList([]const u8).init(allocator);

    var argsIterator = try std.process.ArgIterator.initWithAllocator(allocator);
    defer argsIterator.deinit();
    _ = argsIterator.next();

    while (argsIterator.next()) |arg| {
        try arguments.rawArguments.append(arg);
    }

    if (arguments.rawArguments.items.len > 0) {
        const searchString = arguments.rawArguments.items[0];

        if (utils.checkStringInChoices(searchString, commandsHelp)) {
            std.log.info("{s}", .{helpString});
            return null;
        }

        var i: usize = 0;
        while (i < arguments.rawArguments.items.len) {
            const argString = arguments.rawArguments.items[i];

            std.log.debug("{s}", .{argString});
            if (utils.checkStringInChoices(argString, commandsSearchStartDir)) {
                const value = arguments.rawArguments.items[i + 1];

                if (value.len > 0) {
                    const data = try allocator.alloc(u8, value.len);
                    std.mem.copyBackwards(u8, data, value);

                    arguments.startPath = data;

                    std.log.info("Start path: {s}", .{data});

                    i += 1;
                } else {
                    std.log.err("Not valid start path \n", .{});
                }
            } else if (utils.checkStringInChoices(argString, commandsCaseSensitive)) {
                std.log.info("Case sensitive: ON", .{});

                arguments.caseSensitive = true;
            } else if (utils.checkStringInChoices(argString, commandsSearchString)) {
                const value = arguments.rawArguments.items[i + 1];

                if (value.len > 0) {
                    arguments.searchString = @constCast(value);

                    std.debug.print("Search string: {s}\n", .{value});
                } else {
                    std.debug.print("No args\n", .{});
                }

                i += 1;
            } else if (utils.checkStringInChoices(argString, commandsSearchBinary)) {
                const value = arguments.rawArguments.items[i + 1];

                const file = try std.fs.openFileAbsolute(value, std.fs.File.OpenFlags{ .mode = std.fs.File.OpenMode.read_only });
                defer file.close();

                const content = try file.readToEndAlloc(allocator, 1024 * 1024);

                if (content.len > 0) {
                    arguments.searchString = @constCast(content);

                    std.debug.print("Search binary path: {any}\n", .{content});
                } else {
                    std.debug.print("No args\n", .{});
                }

                arguments.isBinary = true;

                i += 1;
            } else if (utils.checkStringInChoices(argString, commandsSearchFilesPath)) {
                const value = arguments.rawArguments.items[i + 1];

                arguments.searchFilesPath = value;
                arguments.searchFiles = std.ArrayList([] const u8).init(allocator);

                const file = try std.fs.openFileAbsolute(value, std.fs.File.OpenFlags{ .mode = std.fs.File.OpenMode.read_only });
                defer file.close();


                const content = try file.readToEndAlloc(allocator, 1024 * 1024);
                var paths = std.mem.split(u8, content, "\n");


                while (paths.next()) |path| {
                    try arguments.searchFiles.append(path);
                }


                if (arguments.searchFiles.items.len > 0) {
                    std.debug.print("Search file from list: {s} (TOTAL {})\n", .{arguments.searchFilesPath, arguments.searchFilesPath.len});
                } else {
                    std.debug.print("No args\n", .{});
                }

                arguments.isBinary = true;

                i += 1;
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

        if (arguments.searchString.ptr == undefined) {
            std.log.err("Not valid search string or binary content", .{});
            return null;
        }
    } else {
        std.log.err("Not valid arguments see help command -h, --help", .{});
        return null;
    }

    return arguments;
}
