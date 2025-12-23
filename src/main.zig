const std = @import("std");
const BigInt = std.math.big.int.Managed;
const md5 = std.crypto.hash.Md5;

const PAGE_LEN = 3200;
const ALPHABET_SIZE = 29;
const P = 50;
const B = 30;
const S = 5;
const W = 4;

const PrettyCoords = struct {
    room: BigInt,
    wall: usize,
    shelf: usize,
    book: usize,
    page: usize,
};

const Alphabet = enum(u8) {
    Space = 0,
    A,
    B,
    C,
    D,
    E,
    F,
    G,
    H,
    I,
    J,
    K,
    L,
    M,
    N,
    O,
    P,
    Q,
    R,
    S,
    T,
    U,
    V,
    W,
    X,
    Y,
    Z,
    Comma,
    Dot,

    pub fn format(self: Alphabet, writer: *std.io.Writer) !void {
        try writer.print("{c}", .{Alphabet.digitToChar(@intFromEnum(self))});
    }

    pub fn digitToChar(d: u8) u8 {
        switch (d) {
            @intFromEnum(Alphabet.A) => return 'a',
            @intFromEnum(Alphabet.B) => return 'b',
            @intFromEnum(Alphabet.C) => return 'c',
            @intFromEnum(Alphabet.D) => return 'd',
            @intFromEnum(Alphabet.E) => return 'e',
            @intFromEnum(Alphabet.F) => return 'f',
            @intFromEnum(Alphabet.G) => return 'g',
            @intFromEnum(Alphabet.H) => return 'h',
            @intFromEnum(Alphabet.I) => return 'i',
            @intFromEnum(Alphabet.J) => return 'j',
            @intFromEnum(Alphabet.K) => return 'k',
            @intFromEnum(Alphabet.L) => return 'l',
            @intFromEnum(Alphabet.M) => return 'm',
            @intFromEnum(Alphabet.N) => return 'n',
            @intFromEnum(Alphabet.O) => return 'o',
            @intFromEnum(Alphabet.P) => return 'p',
            @intFromEnum(Alphabet.Q) => return 'q',
            @intFromEnum(Alphabet.R) => return 'r',
            @intFromEnum(Alphabet.S) => return 's',
            @intFromEnum(Alphabet.T) => return 't',
            @intFromEnum(Alphabet.U) => return 'u',
            @intFromEnum(Alphabet.V) => return 'v',
            @intFromEnum(Alphabet.W) => return 'w',
            @intFromEnum(Alphabet.X) => return 'x',
            @intFromEnum(Alphabet.Y) => return 'y',
            @intFromEnum(Alphabet.Z) => return 'z',
            @intFromEnum(Alphabet.Comma) => return ',',
            @intFromEnum(Alphabet.Dot) => return '.',
            else => return ' ',
        }
    }
    pub fn charToDigit(c: u8) u8 {
        switch (c) {
            'A', 'a' => return @intFromEnum(Alphabet.A),
            'B', 'b' => return @intFromEnum(Alphabet.B),
            'C', 'c' => return @intFromEnum(Alphabet.C),
            'D', 'd' => return @intFromEnum(Alphabet.D),
            'E', 'e' => return @intFromEnum(Alphabet.E),
            'F', 'f' => return @intFromEnum(Alphabet.F),
            'G', 'g' => return @intFromEnum(Alphabet.G),
            'H', 'h' => return @intFromEnum(Alphabet.H),
            'I', 'i' => return @intFromEnum(Alphabet.I),
            'J', 'j' => return @intFromEnum(Alphabet.J),
            'K', 'k' => return @intFromEnum(Alphabet.K),
            'L', 'l' => return @intFromEnum(Alphabet.L),
            'M', 'm' => return @intFromEnum(Alphabet.M),
            'N', 'n' => return @intFromEnum(Alphabet.N),
            'O', 'o' => return @intFromEnum(Alphabet.O),
            'P', 'p' => return @intFromEnum(Alphabet.P),
            'Q', 'q' => return @intFromEnum(Alphabet.Q),
            'R', 'r' => return @intFromEnum(Alphabet.R),
            'S', 's' => return @intFromEnum(Alphabet.S),
            'T', 't' => return @intFromEnum(Alphabet.T),
            'U', 'u' => return @intFromEnum(Alphabet.U),
            'V', 'v' => return @intFromEnum(Alphabet.V),
            'W', 'w' => return @intFromEnum(Alphabet.W),
            'X', 'x' => return @intFromEnum(Alphabet.X),
            'Y', 'y' => return @intFromEnum(Alphabet.Y),
            'Z', 'z' => return @intFromEnum(Alphabet.Z),
            ',' => return @intFromEnum(Alphabet.Comma),
            '.' => return @intFromEnum(Alphabet.Dot),
            else => return @intFromEnum(Alphabet.Space),
        }
    }
};

fn hashStringMD5(s: []const u8) [16]u8 {
    var output: [md5.digest_length]u8 = undefined;
    md5.hash(s, &output, .{});
    // return std.fmt.bytesToHex(&output, .lower);
    return output;
}

fn padString(s: []const u8, outBuf: []u8, rand: *const std.Random, startOffset: usize) []const u8 {
    // const startOffset = rand.intRangeAtMost(usize, 0, PAGE_LEN - s.len);
    std.debug.print("Padding string: startOffset={d}\n", .{startOffset});

    const copy_len = @min(s.len, outBuf.len);
    // @memcpy(outBuf[0..copy_len], s[0..copy_len]);

    for (0..PAGE_LEN) |i| {
        const r = rand.intRangeAtMost(u8, 0, ALPHABET_SIZE - 1);
        outBuf[i] = r;
    }

    for (startOffset..startOffset + copy_len) |i| {
        const char_index = i - startOffset;
        outBuf[i] = Alphabet.charToDigit(s[char_index]);
    }

    return outBuf;
}

fn calculateSum(allocator: std.mem.Allocator, x: []const u8, k: usize) !BigInt {
    var result = try BigInt.init(allocator);
    errdefer result.deinit();

    var base_k = try BigInt.initSet(allocator, k);
    defer base_k.deinit();

    var current_digit = try BigInt.init(allocator);
    defer current_digit.deinit();

    // (((x[0] * k) + x[1]) * k) + x[2] ...
    for (x) |val| {
        try result.mul(&result, &base_k);
        try current_digit.set(val);
        try result.add(&result, &current_digit);
    }

    return result;
}

fn prettyCoords(alloc: std.mem.Allocator, idx: *const BigInt) !PrettyCoords {
    // 1. Setup your BigInt 'I' (Input)
    // Example value: A large number to test the logic
    var I = try idx.clone();

    // 2. Define your constants (P, B, S, W)
    // These usually fit in standard integers (usize)
    // const P: usize = 410; // Page size
    // const B: usize = 32; // Books per shelf
    // const S: usize = 5; // Shelves per wall
    // const W: usize = 4; // Walls per hexagon

    // 3. Helper BigInts for the calculation
    var quotient = try BigInt.init(alloc);
    defer quotient.deinit();

    var remainder = try BigInt.init(alloc);
    defer remainder.deinit();

    var divisor = try BigInt.init(alloc);
    defer divisor.deinit();

    // --- Step 1: page = I % P, I = I // P ---
    try divisor.set(P);
    try BigInt.divTrunc(&quotient, &remainder, &I, &divisor);
    const page = try remainder.toInt(usize);
    I.swap(&quotient); // I is now I1

    // --- Step 2: book = I % B, I = I // B ---
    try divisor.set(B);
    try BigInt.divTrunc(&quotient, &remainder, &I, &divisor);
    const book = try remainder.toInt(usize);
    I.swap(&quotient); // I is now I2

    // --- Step 3: shelf = I % S, I = I // S ---
    try divisor.set(S);
    try BigInt.divTrunc(&quotient, &remainder, &I, &divisor);
    const shelf = try remainder.toInt(usize);
    I.swap(&quotient); // I is now I3

    // --- Step 4: wall = I % W, hexagon = I // W ---
    try divisor.set(W);
    try BigInt.divTrunc(&quotient, &remainder, &I, &divisor);
    const wall = try remainder.toInt(usize);
    I.swap(&quotient); // I is now 'hexagon'

    // 'hexagon' might still be very large, so we keep it as a BigInt
    // or convert to string for printing.
    const hexagon = try I.clone();
    const hexagon_str = try I.toString(alloc, 10, .lower);
    defer alloc.free(hexagon_str);

    // Print Results
    std.debug.print("Page:    {d}\n", .{page});
    std.debug.print("Book:    {d}\n", .{book});
    std.debug.print("Shelf:   {d}\n", .{shelf});
    std.debug.print("Wall:    {d}\n", .{wall});
    std.debug.print("Hexagon: {s}\n", .{hexagon_str});

    return PrettyCoords{
        .room = hexagon,
        .wall = wall,
        .shelf = shelf,
        .book = book,
        .page = page,
    };
}

fn calculateIndex(allocator: std.mem.Allocator, coords: PrettyCoords) !BigInt {
    // 1. Constants (Sizes of each container)
    // const W = 4; // Walls per Hexagon
    // const S = 5; // Shelves per Wall
    // const B = 32; // Books per Shelf
    // const P = 410; // Pages per Book

    // 2. Start with the largest container: The Room (Hexagon)
    // We clone it because we are going to mutate 'result' by multiplying/adding
    var result = try coords.room.clone();
    errdefer result.deinit();

    // 3. Helper BigInt to hold the values of Wall, Shelf, etc. for math ops
    var tmp = try BigInt.init(allocator);
    defer tmp.deinit();

    // --- Layer 1: Add Wall ---
    // Formula: result = (result * 4) + wall
    try tmp.set(W);
    try result.mul(&result, &tmp); // Shift room to make space for wall
    try tmp.set(coords.wall);
    try result.add(&result, &tmp); // Add wall offset

    // --- Layer 2: Add Shelf ---
    // Formula: result = (result * 5) + shelf
    try tmp.set(S);
    try result.mul(&result, &tmp);
    try tmp.set(coords.shelf);
    try result.add(&result, &tmp);

    // --- Layer 3: Add Book ---
    // Formula: result = (result * 32) + book
    try tmp.set(B);
    try result.mul(&result, &tmp);
    try tmp.set(coords.book);
    try result.add(&result, &tmp);

    // --- Layer 4: Add Page ---
    // Formula: result = (result * 410) + page
    try tmp.set(P);
    try result.mul(&result, &tmp);
    try tmp.set(coords.page);
    try result.add(&result, &tmp);

    return result;
}

fn stringToCoords(s: []const u8, alloc: std.mem.Allocator, rand: *const std.Random, startOffset: usize) !BigInt {
    var padded = s;
    if (s.len < PAGE_LEN) {
        var my_mem = [_]u8{0} ** PAGE_LEN;
        padded = padString(s, my_mem[0..PAGE_LEN], rand, startOffset);

        std.debug.print("Padded string: ", .{});
        for (padded) |c_alpha| {
            const c = Alphabet.digitToChar(c_alpha);
            std.debug.print("{c}", .{c});
        }
        std.debug.print(";\n", .{});
    }

    const big_int_value = try calculateSum(alloc, padded[0..], ALPHABET_SIZE);
    std.debug.print("String to coords value: {s}\n", .{try big_int_value.toString(alloc, 10, .lower)});
    return big_int_value;
}

fn convertToBase29(alloc: std.mem.Allocator, val: *const BigInt) ![]u8 {
    // 1. Create a dynamic list to hold the digits
    var digits: std.ArrayList(u8) = .empty;
    errdefer digits.deinit(alloc);

    // 2. Create a mutable copy of 'val' (I) because we need to modify it
    var I = try val.clone();
    defer I.deinit();

    // 3. Initialize helpers
    var base = try BigInt.init(alloc);
    defer base.deinit();
    try base.set(29); // Set base to 29

    var remainder = try BigInt.init(alloc);
    defer remainder.deinit();

    var quotient = try BigInt.init(alloc);
    defer quotient.deinit();

    // 4. The Loop: while I > 0
    // eqlZero() checks if the BigInt is 0
    while (!I.eqlZero()) {

        // This performs: quotient = I / 29, remainder = I % 29
        try BigInt.divTrunc(&quotient, &remainder, &I, &base);

        // Convert the remainder (BigInt) to a primitive u8
        const digit = try remainder.toInt(u8);
        try digits.append(alloc, digit);

        // Update I to the quotient for the next iteration
        // .swap is efficient because it just swaps pointers, no allocation needed
        I.swap(&quotient);
    }

    // reverse
    std.mem.reverse(u8, digits.items);

    return digits.toOwnedSlice(alloc);
}

pub fn main() !void {
    const input = "this is soooooo cool... ";

    const seed = hashStringMD5(input);
    std.debug.print("MD5 of input string: '{s}'\n", .{std.fmt.bytesToHex(seed, .lower)});
    var prng = std.Random.DefaultPrng.init(std.mem.readInt(u64, seed[0..8], .little));
    const random = prng.random();
    const startOffset = random.intRangeAtMost(usize, 0, PAGE_LEN - input.len);

    const alloc = std.heap.page_allocator;
    const idx = try stringToCoords(input, alloc, &random, startOffset);
    // const base29_repr = try convertToBase29(alloc, &idx);

    const c = try prettyCoords(alloc, &idx);
    const base29_repr = try convertToBase29(alloc, &try calculateIndex(alloc, c));

    std.debug.print("Base-29 representation: ", .{});
    for (base29_repr, 0..) |digit, i| {
        const e: Alphabet = @enumFromInt(digit);
        if (i >= startOffset and i < startOffset + input.len) {
            std.debug.print("\x1b[1m", .{});
        } else {
            std.debug.print("\x1b[0m", .{});
        }
        std.debug.print("{f}", .{e});
    }
    std.debug.print(";[len={d}]\n", .{base29_repr.len});
}
