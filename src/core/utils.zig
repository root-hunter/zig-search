const std = @import("std");

pub fn checkStringInChoices(str: []const u8, choices: std.ArrayList([] const u8)) bool {
    var i: usize = 0;

    while (i < choices.items.len) {
        if (std.mem.eql(u8, str, choices.items[i])) {
            return true;
        }
        i += 1;
    }

    return false;
}
