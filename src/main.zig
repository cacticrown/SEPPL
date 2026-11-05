const std = @import("std");
const Lexer = @import("lexer.zig").Lexer;

pub fn main(init: std.process.Init) !void {
    const allocator = init.gpa;
    const io = init.io;

    const stdout_file = std.Io.File.stdout();

    try stdout_file.writeStreamingAll(io, "SEPPL v0.0.0 by cacticrown & contributors\n",);

    var args = init.minimal.args.iterate();
    _ = args.next();

    var show_tokens = false;
    var file_path: ?[]const u8 = null;

    while (args.next()) |arg| {
        if (std.mem.eql(u8, arg, "--show-tokens")) {
            show_tokens = true;
        } else if (std.mem.eql(u8, arg, "--help")) {
            try stdout_file.writeStreamingAll(
                io,
                \\Usage: seppl <file> [options]
                \\
                \\Options:
                \\  --show-tokens    Print lexer tokens
                \\  --help           Show this help
                \\
            );

            return;
        } else if (std.mem.startsWith(u8, arg, "-")) {
            std.debug.print("Unknown option: {s}\n", .{arg});
            return error.UnknownOption;
        } else if (file_path == null) {
            file_path = arg;
        } else {
            std.debug.print("Only one source file is supported.\n", .{});
            return error.TooManyFiles;
        }
    }

    const path = file_path orelse {
        std.debug.print("Missing source file.\n", .{});
        return error.MissingInputFile;
    };

    const source = try std.Io.Dir.cwd().readFileAlloc(
        io,
        path,
        allocator,
        .limited(16 * 1024 * 1024),
    );
    defer allocator.free(source);

    var lexer = Lexer.init(allocator, source);

    const tokens = try lexer.scanTokens();
    defer allocator.free(tokens);

    var stdout_buffer: [4096]u8 = undefined;
    var stdout_writer = stdout_file.writerStreaming(io, &stdout_buffer);
    const out = &stdout_writer.interface;

    if (show_tokens) {
        for (tokens) |token| {
            try out.print(
                "{s}: \"{s}\" ({d}:{d})\n",
                .{
                    @tagName(token.kind),
                    token.text,
                    token.line,
                    token.column,
                },
            );
        }

        try out.print("\n", .{});
    }

    try out.print("Lexed {s}: {d} tokens\n", .{
        path,
        tokens.len,
    });

    try out.flush();
}
