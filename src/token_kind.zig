pub const TokenKind = enum {
    // values
    identifier,
    integer,
    float_literal,
    string_literal,

    // keywords
    kw_import,
    kw_const,
    kw_struct,
    kw_func,
    kw_ret,
    kw_rets,
    kw_end,

    kw_int,
    kw_float,
    kw_bool,
    kw_string,
    kw_void,

    kw_if,
    kw_then,
    kw_else,
    kw_while,
    kw_do,
    kw_for,

    kw_break,
    kw_continue,

    kw_and,
    kw_or,
    kw_not,

    kw_true,
    kw_false,

    // operators
    plus,
    minus,
    star,
    slash,
    percent,

    equal,
    equal_equal,
    bang_equal,
    greater,
    greater_equal,
    less,
    less_equal,

    // punctuation
    left_paren,
    right_paren,
    left_bracket,
    right_bracket,
    comma,
    dot,

    newline,
    eof,
};
