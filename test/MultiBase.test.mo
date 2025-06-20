import Multiformats "../src"; // Adjust path to your multiformats module
import Debug "mo:base/Debug";
import Text "mo:new-base/Text";
import Blob "mo:new-base/Blob";
import { test } "mo:test";

func testMultiBase(
    bytes : Blob,
    encoding : Multiformats.MultiBase.MultiBase,
    expectedText : Text,
) {
    testMultiBaseEncoding(bytes, encoding, expectedText);
    testMultiBaseDecoding(expectedText, bytes, encoding);
    testMultiBaseRoundtrip(bytes, encoding);
};

func testMultiBaseEncoding(
    bytes : Blob,
    encoding : Multiformats.MultiBase.MultiBase,
    expectedText : Text,
) {
    let actualText = Multiformats.MultiBase.fromBytes(bytes.vals(), encoding);

    if (actualText != expectedText) {
        Debug.trap(
            "MultiBase encoding mismatch for " # debug_show (bytes) # " with " # debug_show (encoding) #
            "\nExpected: " # debug_show (expectedText) #
            "\nActual:   " # debug_show (actualText)
        );
    };
};

func testMultiBaseDecoding(
    text : Text,
    expectedBytes : Blob,
    expectedEncoding : Multiformats.MultiBase.MultiBase,
) {
    let (actualByteArray, actualEncoding) = switch (Multiformats.MultiBase.toBytes(text)) {
        case (#ok(result)) result;
        case (#err(e)) Debug.trap("MultiBase decoding failed for '" # text # "': " # e);
    };

    let actualBytes = Blob.fromArray(actualByteArray);

    if (actualBytes != expectedBytes) {
        Debug.trap(
            "MultiBase byte decoding mismatch for '" # text # "'" #
            "\nExpected: " # debug_show (expectedBytes) #
            "\nActual:   " # debug_show (actualBytes)
        );
    };

    if (actualEncoding != expectedEncoding) {
        Debug.trap(
            "MultiBase encoding detection mismatch for '" # text # "'" #
            "\nExpected: " # debug_show (expectedEncoding) #
            "\nActual:   " # debug_show (actualEncoding)
        );
    };
};

func testMultiBaseRoundtrip(bytes : Blob, encoding : Multiformats.MultiBase.MultiBase) {
    let encoded = Multiformats.MultiBase.fromBytes(bytes.vals(), encoding);
    let (decodedByteArray, decodedEncoding) = switch (Multiformats.MultiBase.toBytes(encoded)) {
        case (#ok(result)) result;
        case (#err(e)) Debug.trap("Round-trip decode failed: " # e);
    };

    let decodedBytes = Blob.fromArray(decodedByteArray);

    if (decodedBytes != bytes) {
        Debug.trap(
            "MultiBase round-trip byte mismatch for " # debug_show (encoding) #
            "\nOriginal: " # debug_show (bytes) #
            "\nDecoded:  " # debug_show (decodedBytes)
        );
    };

    if (decodedEncoding != encoding) {
        Debug.trap(
            "MultiBase round-trip encoding mismatch" #
            "\nOriginal: " # debug_show (encoding) #
            "\nDecoded:  " # debug_show (decodedEncoding)
        );
    };
};

func testMultiBaseError(invalidText : Text, expectedError : Text) {
    switch (Multiformats.MultiBase.toBytes(invalidText)) {
        case (#ok(result)) Debug.trap("Expected error for '" # invalidText # "' but got: " # debug_show (result));
        case (#err(actualError)) {
            if (not Text.contains(actualError, #text expectedError)) {
                Debug.print("Warning: Error message mismatch for '" # invalidText # "'");
                Debug.print("Expected to contain: " # expectedError);
                Debug.print("Actual: " # actualError);
            };
        };
    };
};

// =============================================================================
// Base58BTC Tests ('z' prefix)
// =============================================================================

test(
    "MultiBase: Base58BTC encoding",
    func() {
        // "Hello World" in Base58BTC
        testMultiBase(
            "\48\65\6C\6C\6F\20\57\6F\72\6C\64",
            #base58btc,
            "zJxF12TrwUP45BMd",
        );

        // Empty bytes
        testMultiBase("", #base58btc, "z");

        // Single byte
        testMultiBase("\00", #base58btc, "z1");
        testMultiBase("\01", #base58btc, "z2");
        testMultiBase("\FF", #base58btc, "z5Q");

        // SHA-256 hash (32 bytes)
        testMultiBase(
            "\E3\B0\C4\42\98\FC\1C\14\9A\FB\F4\C8\99\6F\B9\24\27\AE\41\E4\64\9B\93\4C\A4\95\99\1B\78\52\B8\55",
            #base58btc,
            "zGKot5hBsd81kMupNCXHaqbhv3huEbxAFMLnpcX2hniwn",
        );
    },
);

// =============================================================================
// Base32 Tests ('b' prefix)
// =============================================================================

test(
    "MultiBase: Base32 encoding",
    func() {
        // "Hello World" in Base32
        testMultiBase(
            "\48\65\6C\6C\6F\20\57\6F\72\6C\64",
            #base32,
            "bjbswy3dpeblw64tmmq",
        );

        // Empty bytes
        testMultiBase("", #base32, "b");

        // CIDv1 typical case (32-byte hash)
        testMultiBase(
            "\E3\B0\C4\42\98\FC\1C\14\9A\FB\F4\C8\99\6F\B9\24\27\AE\41\E4\64\9B\93\4C\A4\95\99\1B\78\52\B8\55",
            #base32,
            "b4oymiquy7qobjgx36tejs35zeqt24qpemsnzgtfeswmrw6csxbkq",
        );
    },
);

// =============================================================================
// Base32 Upper Tests ('B' prefix)
// =============================================================================

test(
    "MultiBase: Base32 Upper encoding",
    func() {
        testMultiBase(
            "\48\65\6C\6C\6F",
            #base32Upper,
            "BJBSWY3DP",
        );
    },
);

// =============================================================================
// Base64 Tests ('m' prefix)
// =============================================================================

test(
    "MultiBase: Base64 encoding",
    func() {
        // "Hello World" in Base64
        testMultiBase(
            "\48\65\6C\6C\6F\20\57\6F\72\6C\64",
            #base64,
            "mSGVsbG8gV29ybGQ",
        );

        // Empty bytes
        testMultiBase("", #base64, "m");

        // Test without padding
        testMultiBase("\48\65\6C\6C\6F", #base64, "mSGVsbG8");
    },
);

// =============================================================================
// Base64 URL Tests ('u' prefix)
// =============================================================================

test(
    "MultiBase: Base64 URL encoding",
    func() {
        // Test URL-safe characters (+ becomes -, / becomes _)
        testMultiBase(
            "\3E\3F\BE\FF",
            #base64Url,
            "uPj--_w",
        );
    },
);

// =============================================================================
// Base64 URL Padded Tests ('U' prefix)
// =============================================================================

test(
    "MultiBase: Base64 URL Padded encoding",
    func() {
        testMultiBase(
            "\48\65\6C\6C\6F",
            #base64UrlPad,
            "USGVsbG8=",
        );
    },
);

// =============================================================================
// Base16 Tests ('f' prefix)
// =============================================================================

test(
    "MultiBase: Base16 encoding",
    func() {
        // "Hello" in Base16 (hex)
        testMultiBase(
            "\48\65\6C\6C\6F",
            #base16,
            "f48656c6c6f",
        );

        // Empty bytes
        testMultiBase("", #base16, "f");

        // All byte values
        testMultiBase("\00\10\AB\FF", #base16, "f0010abff");
    },
);

// =============================================================================
// Base16 Upper Tests ('F' prefix)
// =============================================================================

test(
    "MultiBase: Base16 Upper encoding",
    func() {
        testMultiBase(
            "\48\65\6C\6C\6F",
            #base16Upper,
            "F48656C6C6F",
        );

        testMultiBase("\DE\AD\BE\EF", #base16Upper, "FDEADBEEF");
    },
);

// =============================================================================
// Round-trip Tests
// =============================================================================

test(
    "MultiBase: Round-trip various encodings",
    func() {
        let testBytes : Blob = "\01\23\45\67\89\AB\CD\EF";

        testMultiBaseRoundtrip(testBytes, #base58btc);
        testMultiBaseRoundtrip(testBytes, #base32);
        testMultiBaseRoundtrip(testBytes, #base32Upper);
        testMultiBaseRoundtrip(testBytes, #base64);
        testMultiBaseRoundtrip(testBytes, #base64Url);
        testMultiBaseRoundtrip(testBytes, #base64UrlPad);
        testMultiBaseRoundtrip(testBytes, #base16);
        testMultiBaseRoundtrip(testBytes, #base16Upper);
    },
);

test(
    "MultiBase: Round-trip edge cases",
    func() {
        // Empty bytes
        testMultiBaseRoundtrip("", #base58btc);
        testMultiBaseRoundtrip("", #base32);

        // Single byte
        testMultiBaseRoundtrip("\00", #base58btc);
        testMultiBaseRoundtrip("\FF", #base16);

        // Large data (256 bytes)
        let largeBytes : Blob = "\00\01\02\03\04\05\06\07\08\09\0A\0B\0C\0D\0E\0F\10\11\12\13\14\15\16\17\18\19\1A\1B\1C\1D\1E\1F\20\21\22\23\24\25\26\27\28\29\2A\2B\2C\2D\2E\2F\30\31\32\33\34\35\36\37\38\39\3A\3B\3C\3D\3E\3F\40\41\42\43\44\45\46\47\48\49\4A\4B\4C\4D\4E\4F\50\51\52\53\54\55\56\57\58\59\5A\5B\5C\5D\5E\5F\60\61\62\63\64\65\66\67\68\69\6A\6B\6C\6D\6E\6F\70\71\72\73\74\75\76\77\78\79\7A\7B\7C\7D\7E\7F\80\81\82\83\84\85\86\87\88\89\8A\8B\8C\8D\8E\8F\90\91\92\93\94\95\96\97\98\99\9A\9B\9C\9D\9E\9F\A0\A1\A2\A3\A4\A5\A6\A7\A8\A9\AA\AB\AC\AD\AE\AF\B0\B1\B2\B3\B4\B5\B6\B7\B8\B9\BA\BB\BC\BD\BE\BF\C0\C1\C2\C3\C4\C5\C6\C7\C8\C9\CA\CB\CC\CD\CE\CF\D0\D1\D2\D3\D4\D5\D6\D7\D8\D9\DA\DB\DC\DD\DE\DF\E0\E1\E2\E3\E4\E5\E6\E7\E8\E9\EA\EB\EC\ED\EE\EF\F0\F1\F2\F3\F4\F5\F6\F7\F8\F9\FA\FB\FC\FD\FE\FF";
        testMultiBaseRoundtrip(largeBytes, #base32);
        testMultiBaseRoundtrip(largeBytes, #base58btc);
    },
);

// =============================================================================
// Error Cases
// =============================================================================

test(
    "MultiBase: Error cases",
    func() {
        // Empty string
        testMultiBaseError("", "Empty multibase");

        // Unknown prefix
        testMultiBaseError("xabc123", "Unsupported multibase prefix");

        // Invalid base58
        testMultiBaseError("z0OIl", "Failed to decode"); // 0, O, I, l are not in base58

        // Invalid base32
        testMultiBaseError("b189", "Failed to decode"); // 1, 8, 9 not in base32

        // Invalid hex
        testMultiBaseError("fghij", "Failed to decode"); // g, h, i, j not in hex
    },
);

// =============================================================================
// Real-world Examples
// =============================================================================

test(
    "MultiBase: Real-world examples",
    func() {
        // IPFS CID examples (base32)
        testMultiBaseRoundtrip(
            "\01\70\12\20\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00" : Blob,
            #base32,
        );

        // DID key examples (base58btc)
        testMultiBaseRoundtrip(
            "\ED\42\42\42\42\42\42\42\42\42\42\42\42\42\42\42\42\42\42\42\42\42\42\42\42\42\42\42\42\42\42\42\42" : Blob,
            #base58btc,
        );

        // Git commit hash (base16)
        testMultiBaseRoundtrip(
            "\AB\AB\AB\AB\AB\AB\AB\AB\AB\AB\AB\AB\AB\AB\AB\AB\AB\AB\AB\AB" : Blob,
            #base16,
        );
    },
);
