// Minimal root module for C-only executable
// The actual entry point is in asm/nasm.c (real_main function)
const std = @import("std");

// Declare the C real_main function
extern fn real_main(argc: c_int, argv: [*c][*c]u8) c_int;

pub fn main() !void {
    // Get command line arguments
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();
    
    const args = try std.process.argsAlloc(allocator);
    defer std.process.argsFree(allocator, args);
    
    // Convert to C-style argc/argv
    const argc: c_int = @intCast(args.len);
    
    // Allocate C-style argv array
    const argv_buf = try allocator.alloc([*c]u8, args.len + 1);
    defer allocator.free(argv_buf);
    
    // Allocate and store C strings for each argument
    const c_strings = try allocator.alloc([]u8, args.len);
    defer {
        for (c_strings) |c_str| {
            allocator.free(c_str);
        }
        allocator.free(c_strings);
    }
    
    // Convert each argument to C string
    for (args, 0..) |arg, i| {
        const c_str = try allocator.dupeZ(u8, arg);
        c_strings[i] = c_str;
        argv_buf[i] = c_str.ptr;
    }
    argv_buf[args.len] = null;
    
    // Call the C real_main function
    const exit_code = real_main(argc, argv_buf.ptr);
    
    std.process.exit(@intCast(exit_code));
}

