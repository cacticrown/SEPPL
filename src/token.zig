const TokenKind = @import("token_kind.zig").TokenKind;

pub const Token = struct {
    kind: TokenKind,
    text: []const u8,
    line: usize,
    column: usize,
};
