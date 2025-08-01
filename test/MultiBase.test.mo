import Multiformats "../src"; // Adjust path to your multiformats module
import Text "mo:core/Text";
import Blob "mo:core/Blob";
import Nat8 "mo:core/Nat8";
import Array "mo:core/Array";
import { test } "mo:test";
import Runtime "mo:core/Runtime";
import List "mo:core/List";

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
  let actualText = Multiformats.MultiBase.toText(bytes.vals(), encoding);

  if (actualText != expectedText) {
    Runtime.trap(
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
  let (actualByteArray, actualEncoding) = switch (Multiformats.MultiBase.fromText(text)) {
    case (#ok(result)) result;
    case (#err(e)) Runtime.trap("MultiBase decoding failed for '" # text # "': " # e);
  };

  let actualBytes = Blob.fromArray(actualByteArray);

  if (actualBytes != expectedBytes) {
    Runtime.trap(
      "MultiBase byte decoding mismatch for '" # text # "'" #
      "\nExpected: " # debug_show (expectedBytes) #
      "\nActual:   " # debug_show (actualBytes)
    );
  };

  if (actualEncoding != expectedEncoding) {
    Runtime.trap(
      "MultiBase encoding detection mismatch for '" # text # "'" #
      "\nExpected: " # debug_show (expectedEncoding) #
      "\nActual:   " # debug_show (actualEncoding)
    );
  };
};

func testMultiBaseRoundtrip(bytes : Blob, encoding : Multiformats.MultiBase.MultiBase) {
  let encoded = Multiformats.MultiBase.toText(bytes.vals(), encoding);
  let (decodedByteArray, decodedEncoding) = switch (Multiformats.MultiBase.fromText(encoded)) {
    case (#ok(result)) result;
    case (#err(e)) Runtime.trap("Round-trip decode failed: " # e);
  };

  let decodedBytes = Blob.fromArray(decodedByteArray);

  if (decodedBytes != bytes) {
    Runtime.trap(
      "MultiBase round-trip byte mismatch for " # debug_show (encoding) #
      "\nOriginal: " # debug_show (bytes) #
      "\nDecoded:  " # debug_show (decodedBytes)
    );
  };

  if (decodedEncoding != encoding) {
    Runtime.trap(
      "MultiBase round-trip encoding mismatch" #
      "\nOriginal: " # debug_show (encoding) #
      "\nDecoded:  " # debug_show (decodedEncoding)
    );
  };
};

func testMultiBaseError(invalidText : Text) {
  switch (Multiformats.MultiBase.fromText(invalidText)) {
    case (#ok(result)) Runtime.trap("Expected error for '" # invalidText # "' but got: " # debug_show (result));
    case (#err(_)) {};
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
    testMultiBaseError("");

    // Unknown prefix
    testMultiBaseError("xabc123");

    // Invalid base58
    testMultiBaseError("z0OIl"); // 0, O, I, l are not in base58

    // Invalid base32
    testMultiBaseError("b189"); // 1, 8, 9 not in base32

    // Invalid hex
    testMultiBaseError("fghij"); // g, h, i, j not in hex
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

// =============================================================================
// New Function Tests
// =============================================================================

test(
  "MultiBase: baseFromByte and baseToByte tests",
  func() {
    // Test all valid byte mappings
    let testCases : [(Nat8, Multiformats.MultiBase.MultiBaseOrIdentity)] = [
      (0x00, #identity),
      (0x5a, #base58btc),
      (0x62, #base32),
      (0x42, #base32Upper),
      (0x6d, #base64),
      (0x75, #base64Url),
      (0x55, #base64UrlPad),
      (0x66, #base16),
      (0x46, #base16Upper),
    ];

    for ((byte, encoding) in testCases.vals()) {
      // Test byte to encoding
      let actualEncoding = switch (Multiformats.MultiBase.baseFromByte(byte)) {
        case (?enc) enc;
        case null Runtime.trap("baseFromByte failed for byte: " # debug_show (byte));
      };

      if (actualEncoding != encoding) {
        Runtime.trap(
          "baseFromByte mismatch for byte " # debug_show (byte) #
          "\nExpected: " # debug_show (encoding) #
          "\nActual:   " # debug_show (actualEncoding)
        );
      };

      // Test encoding to byte
      let actualByte = Multiformats.MultiBase.baseToByte(encoding);
      if (actualByte != byte) {
        Runtime.trap(
          "baseToByte mismatch for encoding " # debug_show (encoding) #
          "\nExpected: " # debug_show (byte) #
          "\nActual:   " # debug_show (actualByte)
        );
      };
    };

    // Test invalid bytes
    let invalidBytes : [Nat8] = [0x01, 0x99, 0xFF, 0x12, 0x34];
    for (invalidByte in invalidBytes.vals()) {
      switch (Multiformats.MultiBase.baseFromByte(invalidByte)) {
        case (?_) Runtime.trap("baseFromByte should return null for invalid byte: " # debug_show (invalidByte));
        case null {}; // Expected
      };
    };
  },
);

test(
  "MultiBase: fromTextWithoutPrefix tests",
  func() {
    // Test various encodings without prefixes
    let testCases : [(Text, Multiformats.MultiBase.MultiBase, Blob)] = [
      ("JxF12TrwUP45BMd", #base58btc, "\48\65\6C\6C\6F\20\57\6F\72\6C\64"),
      ("jbswy3dpeblw64tmmq", #base32, "\48\65\6C\6C\6F\20\57\6F\72\6C\64"),
      ("JBSWY3DP", #base32Upper, "\48\65\6C\6C\6F"),
      ("SGVsbG8gV29ybGQ", #base64, "\48\65\6C\6C\6F\20\57\6F\72\6C\64"),
      ("SGVsbG8gV29ybGQ", #base64Url, "\48\65\6C\6C\6F\20\57\6F\72\6C\64"),
      ("SGVsbG8", #base64UrlPad, "\48\65\6C\6C\6F"),
      ("48656c6c6f", #base16, "\48\65\6C\6C\6F"),
      ("48656C6C6F", #base16Upper, "\48\65\6C\6C\6F"),
    ];

    for ((text, encoding, expectedBytes) in testCases.vals()) {
      let actualBytesArray = switch (Multiformats.MultiBase.fromTextWithoutPrefix(text, encoding)) {
        case (#ok(bytes)) bytes;
        case (#err(e)) Runtime.trap("fromTextWithoutPrefix failed for " # text # " with encoding " # debug_show (encoding) # ": " # e);
      };

      let actualBytes = Blob.fromArray(actualBytesArray);
      if (actualBytes != expectedBytes) {
        Runtime.trap(
          "fromTextWithoutPrefix mismatch for " # text # " with encoding " # debug_show (encoding) #
          "\nExpected: " # debug_show (expectedBytes) #
          "\nActual:   " # debug_show (actualBytes)
        );
      };
    };

    // Test error cases
    let errorCases : [(Text, Multiformats.MultiBase.MultiBase)] = [
      ("0OIl", #base58btc), // Invalid base58 characters
      ("189", #base32), // Invalid base32 characters
      ("ghij", #base16), // Invalid hex characters
    ];

    for ((invalidText, encoding) in errorCases.vals()) {
      switch (Multiformats.MultiBase.fromTextWithoutPrefix(invalidText, encoding)) {
        case (#ok(_)) Runtime.trap("fromTextWithoutPrefix should fail for invalid text: " # invalidText);
        case (#err(_)) {}; // Expected
      };
    };
  },
);

test(
  "MultiBase: fromEncodedBytes tests",
  func() {
    // Test identity encoding (no encoding)
    let identityBytes : [Nat8] = [0x00, 0x01, 0x02, 0x03, 0x04];
    let (decodedBytes, encoding) = switch (Multiformats.MultiBase.fromEncodedBytes(identityBytes.vals())) {
      case (#ok(result)) result;
      case (#err(e)) Runtime.trap("fromEncodedBytes failed for identity: " # e);
    };

    if (decodedBytes != [0x01, 0x02, 0x03, 0x04]) {
      Runtime.trap("Identity decoding mismatch\nExpected: [1, 2, 3, 4]\nActual: " # debug_show (decodedBytes));
    };

    if (encoding != #identity) {
      Runtime.trap("Identity encoding detection failed\nExpected: #identity\nActual: " # debug_show (encoding));
    };

    // Test base16 encoding (simpler to test)
    // "Hello" -> base16 -> "48656c6c6f" -> as UTF-8 bytes with 'f' prefix
    let base16Text = "48656c6c6f";
    let base16TextBytes = Blob.toArray(Text.encodeUtf8(base16Text));
    let base16Buffer = List.empty<Nat8>();
    List.add(base16Buffer, 0x66 : Nat8); // 'f' prefix
    for (byte in base16TextBytes.vals()) {
      List.add(base16Buffer, byte);
    };
    let base16Bytes = List.toArray(base16Buffer);

    let (decodedBytes2, encoding2) = switch (Multiformats.MultiBase.fromEncodedBytes(base16Bytes.vals())) {
      case (#ok(result)) result;
      case (#err(e)) Runtime.trap("fromEncodedBytes failed for base16: " # e);
    };

    if (encoding2 != #base16) {
      Runtime.trap("Base16 encoding detection failed\nExpected: #base16\nActual: " # debug_show (encoding2));
    };

    // The decoded bytes should be "Hello"
    let expectedHelloBytes : [Nat8] = [0x48, 0x65, 0x6C, 0x6C, 0x6F];
    if (decodedBytes2 != expectedHelloBytes) {
      Runtime.trap("Base16 decoding mismatch\nExpected: " # debug_show (expectedHelloBytes) # "\nActual: " # debug_show (decodedBytes2));
    };

    // Test round-trip encoding/decoding with toEncodedBytes
    let testBytes : [Nat8] = [0x01, 0x23, 0x45, 0x67, 0x89, 0xAB];
    let encodings : [Multiformats.MultiBase.MultiBaseOrIdentity] = [
      #identity,
      #base58btc,
      #base32,
      #base32Upper,
      #base64,
      #base64Url,
      #base64UrlPad,
      #base16,
      #base16Upper,
    ];

    for (testEncoding in encodings.vals()) {
      // Encode bytes to encoded bytes
      let encodedBytes = Multiformats.MultiBase.toEncodedBytes(testBytes.vals(), testEncoding);

      // Decode back to original bytes
      let (roundTripBytes, roundTripEncoding) = switch (Multiformats.MultiBase.fromEncodedBytes(encodedBytes.vals())) {
        case (#ok(result)) result;
        case (#err(e)) Runtime.trap("Round-trip fromEncodedBytes failed for " # debug_show (testEncoding) # ": " # e);
      };

      // Verify bytes match
      if (roundTripBytes != testBytes) {
        Runtime.trap(
          "Round-trip bytes mismatch for " # debug_show (testEncoding) #
          "\nExpected: " # debug_show (testBytes) #
          "\nActual:   " # debug_show (roundTripBytes)
        );
      };

      // Verify encoding matches
      if (roundTripEncoding != testEncoding) {
        Runtime.trap(
          "Round-trip encoding mismatch for " # debug_show (testEncoding) #
          "\nExpected: " # debug_show (testEncoding) #
          "\nActual:   " # debug_show (roundTripEncoding)
        );
      };
    };
  },
);

test(
  "MultiBase: fromEncodedBytes error cases",
  func() {
    // Empty bytes
    switch (Multiformats.MultiBase.fromEncodedBytes([].vals())) {
      case (#ok(_)) Runtime.trap("fromEncodedBytes should fail for empty bytes");
      case (#err(e)) {
        if (not Text.contains(e, #text "Empty multibase")) {
          Runtime.trap("Unexpected error message for empty bytes: " # e);
        };
      };
    };

    // Invalid prefix byte
    let invalidPrefix : [Nat8] = [0x99, 0x01, 0x02, 0x03];
    switch (Multiformats.MultiBase.fromEncodedBytes(invalidPrefix.vals())) {
      case (#ok(_)) Runtime.trap("fromEncodedBytes should fail for invalid prefix");
      case (#err(e)) {
        if (not Text.contains(e, #text "Unsupported multibase byte")) {
          Runtime.trap("Unexpected error message for invalid prefix: " # e);
        };
      };
    };

    // Invalid UTF-8 encoding for non-identity
    let invalidUtf8 : [Nat8] = [0x5a, 0xFF, 0xFE, 0xFD]; // 'z' prefix + invalid UTF-8
    switch (Multiformats.MultiBase.fromEncodedBytes(invalidUtf8.vals())) {
      case (#ok(_)) Runtime.trap("fromEncodedBytes should fail for invalid UTF-8");
      case (#err(e)) {
        if (not Text.contains(e, #text "Invalid UTF-8")) {
          Runtime.trap("Unexpected error message for invalid UTF-8: " # e);
        };
      };
    };
  },
);

test(
  "MultiBase: CID-style byte decoding integration test",
  func() {
    // Simulate a CID stored in DAGCBOR format
    // This would be a common use case for fromEncodedBytes

    // Create a mock CID hash (32 bytes)
    let mockHash : [Nat8] = [
      0x12,
      0x34,
      0x56,
      0x78,
      0x9A,
      0xBC,
      0xDE,
      0xF0,
      0x11,
      0x22,
      0x33,
      0x44,
      0x55,
      0x66,
      0x77,
      0x88,
      0x99,
      0xAA,
      0xBB,
      0xCC,
      0xDD,
      0xEE,
      0xFF,
      0x00,
      0x01,
      0x02,
      0x03,
      0x04,
      0x05,
      0x06,
      0x07,
      0x08,
    ];

    // Test with identity encoding (common for CIDs)
    let identityEncodedCid : [Nat8] = Array.concat([0x00 : Nat8], mockHash);
    let (decodedHash, encoding) = switch (Multiformats.MultiBase.fromEncodedBytes(identityEncodedCid.vals())) {
      case (#ok(result)) result;
      case (#err(e)) Runtime.trap("CID identity decoding failed: " # e);
    };

    if (decodedHash != mockHash) {
      Runtime.trap("CID hash decoding mismatch\nExpected: " # debug_show (mockHash) # "\nActual: " # debug_show (decodedHash));
    };

    if (encoding != #identity) {
      Runtime.trap("CID encoding detection failed\nExpected: #identity\nActual: " # debug_show (encoding));
    };

    // Test with base32 encoding (also common for CIDs)
    let base32EncodedHash = Multiformats.MultiBase.toText(mockHash.vals(), #base32);
    let base32Bytes : [Nat8] = Array.concat([0x62 : Nat8], Blob.toArray(Text.encodeUtf8(Text.trimStart(base32EncodedHash, #char 'b'))));
    let (decodedHash2, encoding2) = switch (Multiformats.MultiBase.fromEncodedBytes(base32Bytes.vals())) {
      case (#ok(result)) result;
      case (#err(e)) Runtime.trap("CID base32 decoding failed: " # e);
    };

    if (decodedHash2 != mockHash) {
      Runtime.trap("CID base32 hash decoding mismatch\nExpected: " # debug_show (mockHash) # "\nActual: " # debug_show (decodedHash2));
    };

    if (encoding2 != #base32) {
      Runtime.trap("CID base32 encoding detection failed\nExpected: #base32\nActual: " # debug_show (encoding2));
    };
  },
);
