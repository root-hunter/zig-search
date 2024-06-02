const std = @import("std");
const cli = @import("cli.zig");

pub fn checkFileExtension(
    args: cli.Arguments,
    entry: std.fs.Dir.Walker.Entry,
) !bool {
    var flag = false;
    var k: usize = 0;
    
    while (k < args.fileExtensions.items.len) {
        const ext = args.fileExtensions.items[k];

        var it = std.mem.split(u8, entry.path, ".");
        var fileExt: []const u8 = "";

        while (it.next()) |fe| {
            fileExt = fe;
        }

        if (std.mem.eql(u8, fileExt, ext)) {
            flag = true;
            break;
        }

        k += 1;
    }

    return flag;
}
