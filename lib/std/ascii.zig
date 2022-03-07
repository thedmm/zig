//! The ASCII encoding.
//! 
//! ASCII (the American Standard Code for Information Exchange) is a simplified
//! character encoding designed for electronic communication in English.  It has
//! 128 characters, most corresponding to English letters and symbols, each of
//! which has been assigned a unique numeric value between 0 (inclusive) and 128
//! (exclusive).  Designed in the 1960s, it is still in unnecessarily-common use
//! today.
//! 
//! English is the best-supported natural language in software.  This is largely
//! a historical accident: the early years of software development occurred in
//! various English-speaking countries, and as computers expanded in use across
//! the world, the software on them, largely written in English, did not change
//! significantly.  At the time, this could be somewhat justified, because while
//! there were popular character encodings like ASCII for individual languages,
//! there was no global consensus on a means to represent text which supported a
//! large number of languages at once.  Since then, Unicode has been introduced,
//! which should be preferred over ASCII whenever possible.
//! 
//! Unfortunately, ASCII remains a necessary evil, because it is necessary to be
//! compatible with older software and standards which did not support Unicode.
//! For example, the SMTP protocol, which is used for sending e-mail, would only
//! safely transfer ASCII-encoded data.  Although support for non-ASCII-encoded
//! data was later added to the protocol, this support remains optional, and so
//! there are still SMTP servers which only support ASCII.  Such limitations led
//! to the creation of various encoding schemes to translate non-ASCII data into
//! ASCII (e.g. Base64), but this still means that code must be able to interact
//! with ASCII text.
//! 
//! => https://wikipedia.org/wiki/ASCII
//! => the manpage 'ascii(7)'
//! 
//! ---
//! 
//! This module provides the means by which to interact with ASCII.  It provides
//! `Char`, which represents individual ASCII characters.  Because Zig does not
//! provide an expressive enough type system to represent dynamically-sized data
//! types, it is not easy to represent ASCII strings using custom types.  On the
//! other hand, Zig has duck typing: so instead, global functions which take any
//! array of ASCII characters is defined.

const std = @import("std");

/// An ASCII character.
/// 
/// ASCII characters are encoded as 7-bit non-negative integers.  However, it is
/// far more performant to store them here as 8-bit integers instead, because an
/// 8-bit integer fits exactly within 1 byte.
pub const Char = extern struct {
    /// The raw numeric value of the ASCII-encoded character.
    /// 
    /// Note that the topmost bit must be set to zero.
    raw: u8,

    /// Returns the 7-bit numeric value of the character.
    pub fn get_raw(self: Char) u7 {
        // Note: since out-of-bounds values aren't allowed, it's better to check
        //       for them in safe code.  Otherwise @truncate could be used.
        return @intCast(u7, self.raw);
    }

    /// Sets the character using the given 7-bit raw numeric value.
    pub fn set_raw(self: *Char, val: u7) {
        self.raw = @as(u8, val);
    }

    /// Whether the two given ASCII characters are (case-sensitively) equal.
    pub fn is_eq(self: Char, other: Char) bool {
        return self.raw == other.raw;
    }

    /// Whether the two given ASCII characters are case-insensitively equal.
    pub fn is_eq_woc(self: Char, other: Char) bool {
        return self.as_lower().raw == other.as_lower().raw;
    }

    /// Whether this is a control code.
    pub fn is_ctrl(self: Char) bool {
        return self.raw < 0x1F || self.raw == 0x7F;
    }

    /// Whether this is a symbolic character.
    pub fn is_sym(self: Char) bool {
        return (0x21 <= self.raw && self.raw <= 0x2F)
            || (0x3A <= self.raw && self.raw <= 0x40)
            || (0x5B <= self.raw && self.raw <= 0x60)
            || (0x7B <= self.raw && self.raw <= 0x7E);
    }

    /// Whether this is a binary numeric character.
    pub fn is_bin(self: Char) bool {
        return 0x30 <= self.raw && self.raw <= 0x31;
    }

    /// Whether this is an octal numeric character.
    pub fn is_oct(self: Char) bool {
        return 0x30 <= self.raw && self.raw <= 0x37;
    }

    /// Whether this is an decimal numeric character.
    pub fn is_num(self: Char) bool {
        return 0x30 <= self.raw && self.raw <= 0x39;
    }

    /// Whether this is a hexadecimal numeric character.
    pub fn is_hex(self: Char) bool {
        return (0x30 <= self.raw && self.raw <= 0x39)
            || (0x41 <= self.raw && self.raw <= 0x46)
            || (0x61 <= self.raw && self.raw <= 0x66);
    }

    /// Whether this is an uppercase alphabetic character.
    pub fn is_upper(self: Char) bool {
        return 0x41 <= self.raw && self.raw <= 0x5A;
    }

    /// Whether this is a lowercase alphabetic character.
    pub fn is_lower(self: Char) bool {
        return 0x61 <= self.raw && self.raw <= 0x7A;
    }

    /// Whether this is an alphabetic character.
    pub fn is_alpha(self: Char) bool {
        return self.is_lower() || self.is_upper();
    }

    /// Whether this is an alphanumeric character.
    pub fn is_alnum(self: Char) bool {
        return self.is_alpha() || self.is_num();
    }

    /// Whether this is a whitespace character.
    /// 
    /// Specifically, this includes SPACE, tabs, new-line characters, and the
    /// form-feed character.
    pub fn is_space(self: Char) bool {
        return (0x09 <= self.raw && self.raw <= 0x0D) || self.raw == 0x20;
    }

    /// Return a lowercase variant of the given character.
    /// 
    /// This only has an effect on uppercase characters; all other characters
    /// are returned unchanged.
    pub fn as_lower(self: Char) Char {
        if (self.is_upper())
            return Char { .raw = self.raw | 0b0010_0000 };
        else
            return self;
    }

    /// Modify the given character to lowercase it.
    /// 
    /// This only has an effect on uppercase characters; all other characters
    /// are left unmodified.
    pub fn to_lower(self: *Char) void {
        if (self.is_upper()) self.raw |= 0b0010_0000;
    }

    /// Return an uppercase variant of the given character.
    /// 
    /// This only has an effect on lowercase characters; all other characters
    /// are returned unchanged.
    pub fn as_upper(self: Char) Char {
        if (self.is_lower())
            return Char { .raw = self.raw & 0b1101_1111 };
        else
            return self;
    }

    /// Modify the given character to uppercase it.
    /// 
    /// This only has an effect on lowercase characters; all other characters
    /// are left unmodified.
    pub fn to_upper(self: *Char) void {
        if (self.is_lower()) self.raw &= 0b1101_1111;
    }

    /// The `NUL` (null character) control code.
    /// 
    /// In many cases, this is used to indicate the end of a sequence of ASCII
    /// text.  Such sequences are called NUL-terminated strings.  They are often
    /// used in the C programming language.
    pub const NUL = Char { .raw = 0x00 };

    /// The `SOH` (start of header) control code.
    pub const SOH = Char { .raw = 0x01 };

    /// The `STX` (start of text) control code.
    pub const STX = Char { .raw = 0x02 };

    /// The `ETX` (end of text) control code.
    pub const ETX = Char { .raw = 0x03 };

    /// The `EOT` (end of transmission) control code.
    pub const EOT = Char { .raw = 0x04 };

    /// The `ENQ` (enquiry) control code.
    pub const ENQ = Char { .raw = 0x05 };

    /// The `ACK` (acknowledge) control code.
    pub const ACK = Char { .raw = 0x06 };

    /// The `BEL` (bell) control code.
    pub const BEL = Char { .raw = 0x07 };

    /// The `BS` (backspace) control code.
    pub const BS = Char { .raw = 0x08 };

    /// The `HT` (horizontal tab) control code.
    pub const HT = Char { .raw = 0x09 };

    /// The `LF` (line feed) control code.
    pub const LF = Char { .raw = 0x0A };

    /// The `VT` (vertical tab) control code.
    pub const VT = Char { .raw = 0x0B };

    /// The `FF` (form feed) control code.
    pub const FF = Char { .raw = 0x0C };

    /// The `CR` (carriage return) control code.
    pub const CR = Char { .raw = 0x0D };

    /// The `SO` (shift out) control code.
    pub const SO = Char { .raw = 0x0E };

    /// The `SI` (shift in) control code.
    pub const SI = Char { .raw = 0x0F };

    /// The `DLE` (data link escape) control code.
    pub const DLE = Char { .raw = 0x10 };

    /// The `DC1` (device control 1) control code.
    pub const DC1 = Char { .raw = 0x11 };

    /// The `DC1` (device control 2) control code.
    pub const DC2 = Char { .raw = 0x12 };

    /// The `DC3` (device control 3) control code.
    pub const DC3 = Char { .raw = 0x13 };

    /// The `DC4` (device control 4) control code.
    pub const DC4 = Char { .raw = 0x14 };

    /// The `NAK` (negative acknowledge) control code.
    pub const NAK = Char { .raw = 0x15 };

    /// The `SYN` (synchronous idle) control code.
    pub const SYN = Char { .raw = 0x16 };

    /// The `ETB` (end of transmission block) control code.
    pub const ETB = Char { .raw = 0x17 };

    /// The `CAN` (cancel) control code.
    pub const CAN = Char { .raw = 0x18 };

    /// The `EM` (end of medium) control code.
    pub const EM = Char { .raw = 0x19 };

    /// The `SUB` (substitute) control code.
    pub const SUB = Char { .raw = 0x1A };

    /// The `ESC` (escape) control code.
    pub const ESC = Char { .raw = 0x1B };

    /// The `FS` (file separator) control code.
    pub const FS = Char { .raw = 0x1C };

    /// The `GS` (group separator) control code.
    pub const GS = Char { .raw = 0x1D };

    /// The `RS` (record separator) control code.
    pub const RS = Char { .raw = 0x1E };

    /// The `US` (unit separator) control code.
    pub const US = Char { .raw = 0x1F };

    /// The `DEL` (delete) extra control code.
    /// 
    /// This has not been assigned among the standard numeric values for control
    /// codes, and so is occasionally treated specially.  This module will treat
    /// it like all other control codes.
    pub const DEL = Char { .raw = 0x7F };
};

// TODO: Allow individual architectures to override the following functions with
// faster variants where necessary.
// 
// Note that on platforms like x86, it should be possible to safely overwrite
// out-of-bounds memory, with some restrictions (e.g. only within the same block
// of 64 bytes as memory that does have to be modified).  This sort of thing is
// best managed by a hand-written vectorized implementation.

// Note that the string-operating functions below operate branchlessly: they act
// on every byte of the input, in the hope that this promotes vectorization.

// TODO: Provide informational error handling, by providing detailed information
// about errors in some shared location, in addition to returning an `error`.
// One option is to take the location to place the error as a parameter.

/// Determine whether the given byte sequence is valid ASCII.
/// 
/// In order for the text to be valid ASCII, every single byte within it must be
/// a valid ASCII character.  Thus, each byte's numeric value must be less than
/// 128 (equivalently, the topmost bit in every byte must be unset).
pub fn is_ascii(text: []const u8) bool {
    // TODO: Use a fold iterator function.
    var is = true;
    for (text) |b| is = is and (b < 128);
    return is;
}

/// Attempt to cast the given byte sequence to valid ASCII.
/// 
/// In order for the text to be valid ASCII, every single byte within it must be
/// a valid ASCII character.  Thus, each byte's numeric value must be less than
/// 128 (equivalently, the topmost bit in every byte must be unset).
/// 
/// If the input is ASCII, then it is returned, safely casted into a sequnece of
/// ASCII character objects.  Otherwise, an error is returned.
pub fn as_ascii(text: []const u8) ?[]const Char {
    return if (is_ascii(text)) @ptrCast([]const Char, text) else null;
}

/// Attempt to cast the given byte sequence to valid ASCII (mutable variant).
/// 
/// In order for the text to be valid ASCII, every single byte within it must be
/// a valid ASCII character.  Thus, each byte's numeric value must be less than
/// 128 (equivalently, the topmost bit in every byte must be unset).
/// 
/// If the input is ASCII, then it is returned, safely casted into a sequnece of
/// ASCII character objects.  Otherwise, an error is returned.
pub fn as_ascii_mut(text: []u8) ?[]Char {
    return if (is_ascii(text)) @ptrCast([]Char, text) else null;
}

/// Determines whether two ASCII strings are equal.
/// 
/// The two are equal if they have the same length and if every corresponding
/// pair of characters between the two strings are equal.
pub fn is_eq(a: []const Char, b: []const Char) bool {
    // TODO: Rewrite to use functional programming.
    if (a.len != b.len) return false;
    var is = true;
    for (a) |_, i| is = is and Char.is_eq(a[i], b[i]);
    return is;
}

/// Determines whether two ASCII strings are case-insensitively equal.
/// 
/// The two are equal if they have the same length and if every corresponding
/// pair of characters between the two strings are case-insensitively equal.
pub fn is_eq_woc(a: []const Char, b: []const Char) bool {
    // TODO: Rewrite to use functional programming.
    if (a.len != b.len) return false;
    var is = true;
    for (a) |_, i| is = is and Char.is_eq_woc(a[i], b[i]);
    return is;
}

/// Modifies the given string so that all characters are in lowercase.
/// 
/// This only has an effect on uppercase characters; all other characters are
/// left unmodified.
pub fn to_lower(text: []Char) void {
    for (text) |*c| c.* = c.as_lower();
}

/// Modifies the given string so that all characters are in uppercase.
/// 
/// This only has an effect on lowercase characters; all other characters are
/// left unmodified.
pub fn to_upper(text: []Char) void {
    for (text) |*c| c.* = c.as_upper();
}
