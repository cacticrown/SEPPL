const std = @import("std");
const TokenKind = @import("token_kind.zig").TokenKind;
const Token = @import("token.zig").Token;

pub const Lexer = struct {
    allocator: std.mem.Allocator,
    source: []const u8,

    start: usize = 0,
    current: usize = 0,

    line: usize = 1,
    column: usize = 1,

    start_line: usize = 1,
    start_column: usize = 1,

    pub fn init(allocator: std.mem.Allocator, source: []const u8) Lexer {
        return .{
            .allocator = allocator,
            .source = source,
        };
    }

    pub fn scanTokens(self: *Lexer) ![]Token {
        var tokens: std.ArrayList(Token) = .empty;
        errdefer tokens.deinit(self.allocator);

        while (!self.isAtEnd()) {
            self.start = self.current;
            self.start_line = self.line;
            self.start_column = self.column;

            try self.scanToken(&tokens);
        }

        try tokens.append(self.allocator, .{
            .kind = .eof,
            .text = "",
            .line = self.line,
            .column = self.column,
        });

        return tokens.toOwnedSlice(self.allocator);
    }

    fn scanToken(self: *Lexer, tokens: *std.ArrayList(Token)) !void {
        const c = self.advance();

        switch (c) {
            ' ', '\t', '\r' => {},

            '\n' => try self.addToken(tokens, .newline),

            '(' => try self.addToken(tokens, .left_paren),
            ')' => try self.addToken(tokens, .right_paren),
            '[' => try self.addToken(tokens, .left_bracket),
            ']' => try self.addToken(tokens, .right_bracket),
            ',' => try self.addToken(tokens, .comma),
            '.' => try self.addToken(tokens, .dot),

            '+' => try self.addToken(tokens, .plus),
            '-' => try self.addToken(tokens, .minus),
            '*' => try self.addToken(tokens, .star),
            '/' => try self.addToken(tokens, .slash),
            '%' => try self.addToken(tokens, .percent),

            '=' => {
                if (self.match('=')) {
                    try self.addToken(tokens, .equal_equal);
                } else {
                    try self.addToken(tokens, .equal);
                }
            },

            '!' => {
                if (self.match('=')) {
                    try self.addToken(tokens, .bang_equal);
                } else {
                    return error.UnexpectedCharacter;
                }
            },

            '>' => {
                if (self.match('=')) {
                    try self.addToken(tokens, .greater_equal);
                } else {
                    try self.addToken(tokens, .greater);
                }
            },

            '<' => {
                if (self.match('=')) {
                    try self.addToken(tokens, .less_equal);
                } else {
                    try self.addToken(tokens, .less);
                }
            },

            '"' => try self.string(tokens),

            else => {
                if (isDigit(c)) {
                    try self.number(tokens);
                } else if (isLetter(c)) {
                    try self.identifier(tokens);
                } else {
                    return error.UnexpectedCharacter;
                }
            },
        }
    }

    fn identifier(self: *Lexer, tokens: *std.ArrayList(Token)) !void {
        while (isLetterOrDigit(self.peek())) {
            _ = self.advance();
        }

        const text = self.source[self.start..self.current];

        // REM comments out everything until the next newline.
        if (std.mem.eql(u8, text, "REM")) {
            while (!self.isAtEnd() and self.peek() != '\n') {
                _ = self.advance();
            }

            return;
        }

        try self.addToken(tokens, keywordType(text));
    }

    fn number(self: *Lexer, tokens: *std.ArrayList(Token)) !void {
        while (isDigit(self.peek())) {
            _ = self.advance();
        }

        var kind: TokenKind = .integer;

        if (self.peek() == '.' and isDigit(self.peekNext())) {
            _ = self.advance();

            while (isDigit(self.peek())) {
                _ = self.advance();
            }

            kind = .float_literal;
        }

        try self.addToken(tokens, kind);
    }

    fn string(self: *Lexer, tokens: *std.ArrayList(Token)) !void {
        while (!self.isAtEnd() and self.peek() != '"') {
            if (self.peek() == '\n') {
                return error.UnterminatedString;
            }

            if (self.peek() == '\\') {
                _ = self.advance();

                if (self.isAtEnd() or self.peek() == '\n') {
                    return error.UnterminatedString;
                }
            }

            _ = self.advance();
        }

        if (self.isAtEnd()) {
            return error.UnterminatedString;
        }

        _ = self.advance();

        try self.addToken(tokens, .string_literal);
    }

    fn addToken(self: *Lexer, tokens: *std.ArrayList(Token), kind: TokenKind) !void {
        try tokens.append(self.allocator, .{
            .kind = kind,
            .text = self.source[self.start..self.current],
            .line = self.start_line,
            .column = self.start_column,
        });
    }

    fn advance(self: *Lexer) u8 {
        const c = self.source[self.current];

        self.current += 1;

        if (c == '\n') {
            self.line += 1;
            self.column = 1;
        } else {
            self.column += 1;
        }

        return c;
    }

    fn match(self: *Lexer, expected: u8) bool {
        if (self.isAtEnd()) {
            return false;
        }

        if (self.source[self.current] != expected) {
            return false;
        }

        _ = self.advance();
        return true;
    }

    fn peek(self: *const Lexer) u8 {
        if (self.isAtEnd()) {
            return 0;
        }

        return self.source[self.current];
    }

    fn peekNext(self: *const Lexer) u8 {
        if (self.current + 1 >= self.source.len) {
            return 0;
        }

        return self.source[self.current + 1];
    }

    fn isAtEnd(self: *const Lexer) bool {
        return self.current >= self.source.len;
    }

    fn isDigit(c: u8) bool {
        return c >= '0' and c <= '9';
    }

    fn isLetter(c: u8) bool {
        return (c >= 'a' and c <= 'z') or
            (c >= 'A' and c <= 'Z') or
            c == '_';
    }

    fn isLetterOrDigit(c: u8) bool {
        return isLetter(c) or isDigit(c);
    }

    fn keywordType(text: []const u8) TokenKind {
        if (std.mem.eql(u8, text, "IMPORT")) return .kw_import;
        if (std.mem.eql(u8, text, "CONST")) return .kw_const;
        if (std.mem.eql(u8, text, "STRUCT")) return .kw_struct;
        if (std.mem.eql(u8, text, "FUNC")) return .kw_func;
        if (std.mem.eql(u8, text, "RET")) return .kw_ret;
        if (std.mem.eql(u8, text, "RETS")) return .kw_rets;
        if (std.mem.eql(u8, text, "END")) return .kw_end;

        if (std.mem.eql(u8, text, "INT")) return .kw_int;
        if (std.mem.eql(u8, text, "FLOAT")) return .kw_float;
        if (std.mem.eql(u8, text, "BOOL")) return .kw_bool;
        if (std.mem.eql(u8, text, "STRING")) return .kw_string;
        if (std.mem.eql(u8, text, "VOID")) return .kw_void;

        if (std.mem.eql(u8, text, "IF")) return .kw_if;
        if (std.mem.eql(u8, text, "THEN")) return .kw_then;
        if (std.mem.eql(u8, text, "ELSE")) return .kw_else;
        if (std.mem.eql(u8, text, "WHILE")) return .kw_while;
        if (std.mem.eql(u8, text, "DO")) return .kw_do;

        if (std.mem.eql(u8, text, "BREAK")) return .kw_break;
        if (std.mem.eql(u8, text, "CONTINUE")) return .kw_continue;

        if (std.mem.eql(u8, text, "AND")) return .kw_and;
        if (std.mem.eql(u8, text, "OR")) return .kw_or;
        if (std.mem.eql(u8, text, "NOT")) return .kw_not;

        if (std.mem.eql(u8, text, "TRUE")) return .kw_true;
        if (std.mem.eql(u8, text, "FALSE")) return .kw_false;

        return .identifier;
    }
};
