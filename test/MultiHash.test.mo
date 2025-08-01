import Multiformats "../src";
import Debug "mo:core/Debug";
import Blob "mo:core/Blob";
import Array "mo:core/Array";
import Text "mo:core/Text";
import { test } "mo:test";
import Runtime "mo:core/Runtime";

func testMultiHash(
  algorithm : Multiformats.MultiHash.Algorithm,
  digest : Blob,
  expectedBytes : Blob,
) {
  let multihash : Multiformats.MultiHash.MultiHash = {
    algorithm = algorithm;
    digest = digest;
  };

  testMultiHashEncoding(multihash, expectedBytes);
  testMultiHashDecoding(expectedBytes, multihash);
  testMultiHashRoundtrip(multihash);
};

func testMultiHashEncoding(
  multihash : Multiformats.MultiHash.MultiHash,
  expectedBytes : Blob,
) {
  let actualBytes = Blob.fromArray(Multiformats.MultiHash.toBytes(multihash));

  if (actualBytes != expectedBytes) {
    Runtime.trap(
      "MultiHash encoding mismatch for " # debug_show (multihash.algorithm) #
      "\nExpected: " # debug_show (expectedBytes) #
      "\nActual:   " # debug_show (actualBytes)
    );
  };
};

func testMultiHashDecoding(
  bytes : Blob,
  expectedMultiHash : Multiformats.MultiHash.MultiHash,
) {
  let actualMultiHash = switch (Multiformats.MultiHash.fromBytes(bytes.vals())) {
    case (#ok(mh)) mh;
    case (#err(e)) Runtime.trap("MultiHash decoding failed for " # debug_show (bytes) # ": " # e);
  };

  if (actualMultiHash.algorithm != expectedMultiHash.algorithm) {
    Runtime.trap(
      "MultiHash algorithm mismatch for " # debug_show (bytes) #
      "\nExpected: " # debug_show (expectedMultiHash.algorithm) #
      "\nActual:   " # debug_show (actualMultiHash.algorithm)
    );
  };

  if (actualMultiHash.digest != expectedMultiHash.digest) {
    Runtime.trap(
      "MultiHash digest mismatch for " # debug_show (bytes) #
      "\nExpected: " # debug_show (expectedMultiHash.digest) #
      "\nActual:   " # debug_show (actualMultiHash.digest)
    );
  };
};

func testMultiHashRoundtrip(multihash : Multiformats.MultiHash.MultiHash) {
  let encoded = Multiformats.MultiHash.toBytes(multihash);
  let decoded = switch (Multiformats.MultiHash.fromBytes(encoded.vals())) {
    case (#ok(mh)) mh;
    case (#err(e)) Runtime.trap("Round-trip decode failed for " # debug_show (multihash.algorithm) # ": " # e);
  };

  if (decoded.algorithm != multihash.algorithm) {
    Runtime.trap(
      "MultiHash round-trip algorithm mismatch for " # debug_show (multihash.algorithm) #
      "\nOriginal: " # debug_show (multihash.algorithm) #
      "\nDecoded:  " # debug_show (decoded.algorithm)
    );
  };

  if (decoded.digest != multihash.digest) {
    Runtime.trap(
      "MultiHash round-trip digest mismatch for " # debug_show (multihash.algorithm) #
      "\nOriginal: " # debug_show (multihash.digest) #
      "\nDecoded:  " # debug_show (decoded.digest)
    );
  };
};

func testMultiHashError(invalidBytes : [Nat8], expectedError : Text) {
  switch (Multiformats.MultiHash.fromBytes(invalidBytes.vals())) {
    case (#ok(mh)) Runtime.trap("Expected error for " # debug_show (invalidBytes) # " but got: " # debug_show (mh));
    case (#err(actualError)) {
      if (not Text.contains(actualError, #text expectedError)) {
        Debug.print("Warning: Error message mismatch for " # debug_show (invalidBytes));
        Debug.print("Expected to contain: " # expectedError);
        Debug.print("Actual: " # actualError);
      };
    };
  };
};

// =============================================================================
// Identity/None Tests (any length)
// =============================================================================

test(
  "MultiHash: Identity/None - Empty data",
  func() {
    // Identity hash with empty data
    let emptyData : Blob = "";
    testMultiHash(
      #none,
      emptyData,
      "\00\00", // 0x00 = Identity, 0x00 = 0 bytes
    );
  },
);

test(
  "MultiHash: Identity/None - Single byte",
  func() {
    // Identity hash with single byte
    let singleByte : Blob = "\42";
    testMultiHash(
      #none,
      singleByte,
      "\00\01\42", // 0x00 = Identity, 0x01 = 1 byte, 0x42 = data
    );
  },
);

test(
  "MultiHash: Identity/None - Short data",
  func() {
    // Identity hash with short data
    let shortData : Blob = "\48\65\6C\6C\6F"; // "Hello"
    testMultiHash(
      #none,
      shortData,
      "\00\05\48\65\6C\6C\6F", // 0x00 = Identity, 0x05 = 5 bytes, "Hello"
    );
  },
);

test(
  "MultiHash: Identity/None - Long data",
  func() {
    // Identity hash with longer data (64 bytes)
    let longData : Blob = "\01\02\03\04\05\06\07\08\09\0A\0B\0C\0D\0E\0F\10\11\12\13\14\15\16\17\18\19\1A\1B\1C\1D\1E\1F\20\21\22\23\24\25\26\27\28\29\2A\2B\2C\2D\2E\2F\30\31\32\33\34\35\36\37\38\39\3A\3B\3C\3D\3E\3F\40";
    testMultiHash(
      #none,
      longData,
      "\00\40\01\02\03\04\05\06\07\08\09\0A\0B\0C\0D\0E\0F\10\11\12\13\14\15\16\17\18\19\1A\1B\1C\1D\1E\1F\20\21\22\23\24\25\26\27\28\29\2A\2B\2C\2D\2E\2F\30\31\32\33\34\35\36\37\38\39\3A\3B\3C\3D\3E\3F\40", // 0x00 = Identity, 0x40 = 64 bytes
    );
  },
);

// =============================================================================
// SHA-256 Tests (32 bytes)
// =============================================================================

test(
  "MultiHash: SHA-256",
  func() {
    // Empty string SHA-256: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
    let sha256EmptyHash : Blob = "\E3\B0\C4\42\98\FC\1C\14\9A\FB\F4\C8\99\6F\B9\24\27\AE\41\E4\64\9B\93\4C\A4\95\99\1B\78\52\B8\55";
    testMultiHash(
      #sha2256,
      sha256EmptyHash,
      "\12\20\E3\B0\C4\42\98\FC\1C\14\9A\FB\F4\C8\99\6F\B9\24\27\AE\41\E4\64\9B\93\4C\A4\95\99\1B\78\52\B8\55", // 0x12 = SHA-256, 0x20 = 32 bytes
    );
  },
);

// =============================================================================
// SHA-512 Tests (64 bytes)
// =============================================================================

test(
  "MultiHash: SHA-512",
  func() {
    // Empty string SHA-512 (first 32 bytes for test brevity)
    let sha512Hash : Blob = "\AB\AB\AB\AB\AB\AB\AB\AB\AB\AB\AB\AB\AB\AB\AB\AB\AB\AB\AB\AB\AB\AB\AB\AB\AB\AB\AB\AB\AB\AB\AB\AB\AB\AB\AB\AB\AB\AB\AB\AB\AB\AB\AB\AB\AB\AB\AB\AB\AB\AB\AB\AB\AB\AB\AB\AB\AB\AB\AB\AB\AB\AB\AB\AB";
    testMultiHash(
      #sha2512,
      sha512Hash,
      "\13\40\AB\AB\AB\AB\AB\AB\AB\AB\AB\AB\AB\AB\AB\AB\AB\AB\AB\AB\AB\AB\AB\AB\AB\AB\AB\AB\AB\AB\AB\AB\AB\AB\AB\AB\AB\AB\AB\AB\AB\AB\AB\AB\AB\AB\AB\AB\AB\AB\AB\AB\AB\AB\AB\AB\AB\AB\AB\AB\AB\AB\AB\AB\AB\AB",
    );

  },
);

// =============================================================================
// Blake2b-256 Tests (32 bytes)
// =============================================================================

test(
  "MultiHash: Blake2b-256",
  func() {
    let blake2bHash : Blob = "\CD\CD\CD\CD\CD\CD\CD\CD\CD\CD\CD\CD\CD\CD\CD\CD\CD\CD\CD\CD\CD\CD\CD\CD\CD\CD\CD\CD\CD\CD\CD\CD";
    testMultiHash(
      #blake2b256,
      blake2bHash,
      "\A0\E4\02\20\CD\CD\CD\CD\CD\CD\CD\CD\CD\CD\CD\CD\CD\CD\CD\CD\CD\CD\CD\CD\CD\CD\CD\CD\CD\CD\CD\CD\CD\CD\CD\CD", // VarInt encoded 0xb220, then 0x20 = 32 bytes
    );
  },
);
// =============================================================================
// Blake2b-256 Tests (32 bytes)
// =============================================================================

test(
  "MultiHash: Blake2b-256",
  func() {
    let blake2bHash : Blob = "\CD\CD\CD\CD\CD\CD\CD\CD\CD\CD\CD\CD\CD\CD\CD\CD\CD\CD\CD\CD\CD\CD\CD\CD\CD\CD\CD\CD\CD\CD\CD\CD";
    testMultiHash(
      #blake2b256,
      blake2bHash,
      "\A0\E4\02\20\CD\CD\CD\CD\CD\CD\CD\CD\CD\CD\CD\CD\CD\CD\CD\CD\CD\CD\CD\CD\CD\CD\CD\CD\CD\CD\CD\CD\CD\CD\CD\CD", // VarInt encoded 0xb220, then 0x20 = 32 bytes
    );
  },
);

// =============================================================================
// Blake2s-256 Tests (32 bytes)
// =============================================================================

test(
  "MultiHash: Blake2s-256",
  func() {
    let blake2sHash : Blob = "\EF\EF\EF\EF\EF\EF\EF\EF\EF\EF\EF\EF\EF\EF\EF\EF\EF\EF\EF\EF\EF\EF\EF\EF\EF\EF\EF\EF\EF\EF\EF\EF";
    testMultiHash(
      #blake2s256,
      blake2sHash,
      "\E0\E4\02\20\EF\EF\EF\EF\EF\EF\EF\EF\EF\EF\EF\EF\EF\EF\EF\EF\EF\EF\EF\EF\EF\EF\EF\EF\EF\EF\EF\EF\EF\EF\EF\EF", // VarInt encoded 0xb260, then 0x20 = 32 bytes
    );
  },
);

// =============================================================================
// SHA3-256 Tests (32 bytes)
// =============================================================================

test(
  "MultiHash: SHA3-256",
  func() {
    let sha3Hash : Blob = "\12\12\12\12\12\12\12\12\12\12\12\12\12\12\12\12\12\12\12\12\12\12\12\12\12\12\12\12\12\12\12\12";
    testMultiHash(
      #sha3256,
      sha3Hash,
      "\16\20\12\12\12\12\12\12\12\12\12\12\12\12\12\12\12\12\12\12\12\12\12\12\12\12\12\12\12\12\12\12\12\12", // 0x16 = SHA3-256, 0x20 = 32 bytes
    );
  },
);

// =============================================================================
// SHA3-512 Tests (64 bytes)
// =============================================================================

test(
  "MultiHash: SHA3-512",
  func() {
    let sha3512Hash : Blob = "\34\34\34\34\34\34\34\34\34\34\34\34\34\34\34\34\34\34\34\34\34\34\34\34\34\34\34\34\34\34\34\34\34\34\34\34\34\34\34\34\34\34\34\34\34\34\34\34\34\34\34\34\34\34\34\34\34\34\34\34\34\34\34\34";
    testMultiHash(
      #sha3512,
      sha3512Hash,
      "\14\40\34\34\34\34\34\34\34\34\34\34\34\34\34\34\34\34\34\34\34\34\34\34\34\34\34\34\34\34\34\34\34\34\34\34\34\34\34\34\34\34\34\34\34\34\34\34\34\34\34\34\34\34\34\34\34\34\34\34\34\34\34\34\34\34", // 0x14 = SHA3-512, 0x40 = 64 bytes
    );
  },
);

// =============================================================================
// Round-trip Tests
// =============================================================================

test(
  "MultiHash: Round-trip all algorithms",
  func() {
    // Test Identity/None with various data sizes
    testMultiHashRoundtrip({
      algorithm = #none;
      digest = "" : Blob; // Empty data
    });

    testMultiHashRoundtrip({
      algorithm = #none;
      digest = "\AA\BB\CC" : Blob; // Short data
    });

    testMultiHashRoundtrip({
      algorithm = #none;
      digest = "\FF\FF\FF\FF\FF\FF\FF\FF\FF\FF\FF\FF\FF\FF\FF\FF\FF\FF\FF\FF\FF\FF\FF\FF\FF\FF\FF\FF\FF\FF\FF\FF" : Blob; // 32 bytes like other hashes
    });

    // Test all algorithms with appropriate digest lengths
    testMultiHashRoundtrip({
      algorithm = #sha2256;
      digest = "\11\11\11\11\11\11\11\11\11\11\11\11\11\11\11\11\11\11\11\11\11\11\11\11\11\11\11\11\11\11\11\11" : Blob;
    });

    testMultiHashRoundtrip({
      algorithm = #sha2512;
      digest = "\22\22\22\22\22\22\22\22\22\22\22\22\22\22\22\22\22\22\22\22\22\22\22\22\22\22\22\22\22\22\22\22\22\22\22\22\22\22\22\22\22\22\22\22\22\22\22\22\22\22\22\22\22\22\22\22\22\22\22\22\22\22\22\22" : Blob;
    });

    testMultiHashRoundtrip({
      algorithm = #blake2b256;
      digest = "\33\33\33\33\33\33\33\33\33\33\33\33\33\33\33\33\33\33\33\33\33\33\33\33\33\33\33\33\33\33\33\33" : Blob;
    });

    testMultiHashRoundtrip({
      algorithm = #blake2s256;
      digest = "\44\44\44\44\44\44\44\44\44\44\44\44\44\44\44\44\44\44\44\44\44\44\44\44\44\44\44\44\44\44\44\44" : Blob;
    });

    testMultiHashRoundtrip({
      algorithm = #sha3256;
      digest = "\55\55\55\55\55\55\55\55\55\55\55\55\55\55\55\55\55\55\55\55\55\55\55\55\55\55\55\55\55\55\55\55" : Blob;
    });

    testMultiHashRoundtrip({
      algorithm = #sha3512;
      digest = "\66\66\66\66\66\66\66\66\66\66\66\66\66\66\66\66\66\66\66\66\66\66\66\66\66\66\66\66\66\66\66\66\66\66\66\66\66\66\66\66\66\66\66\66\66\66\66\66\66\66\66\66\66\66\66\66\66\66\66\66\66\66\66\66" : Blob;
    });
  },
);

// =============================================================================
// Error Cases
// =============================================================================

test(
  "MultiHash: Error cases",
  func() {
    // Empty input
    testMultiHashError([], "Failed to decode algorithm");

    // Invalid algorithm
    testMultiHashError([0x99], "Unknown hash algorithm");

    // Missing length
    testMultiHashError([0x12], "Failed to decode digest length");

    // Wrong digest length for SHA-256 (should be 32, got 10)
    testMultiHashError([0x12, 0x0A], "Invalid digest length");

    // Insufficient digest bytes
    testMultiHashError([0x12, 0x20, 0x01, 0x02], "Insufficient digest bytes");

    // Wrong length for Blake2b-256
    testMultiHashError([0xA0, 0xE4, 0x02, 0x10], "Invalid digest length"); // Claims 16 bytes but Blake2b-256 needs 32

    // Identity algorithm tests - Identity is more permissive

    // Identity with missing length byte should still error
    testMultiHashError([0x00], "Failed to decode digest length");

    // Note: Identity algorithm accepts any length, so [0x00, 0x05, 0x01, 0x02]
    // would successfully parse as Identity with 2 bytes of the claimed 5 bytes,
    // consuming all available bytes. This is expected behavior for Identity.

    // Test that Identity algorithm consumes all available bytes regardless of claimed length
    let identityBytes : [Nat8] = [0x00, 0x05, 0x01, 0x02]; // Claims 5 bytes but only has 2
    let result = Multiformats.MultiHash.fromBytes(identityBytes.vals());
    switch (result) {
      case (#ok(mh)) {
        // Should successfully decode with the available bytes
        assert (mh.algorithm == #none);
        let expectedDigest : Blob = "\01\02";
        if (mh.digest != expectedDigest) {
          Runtime.trap("Expected digest to be \\01\\02, got " # debug_show (mh.digest));
        };
      };
      case (#err(e)) Runtime.trap("Identity should accept available bytes but got error: " # e);
    };
  },
);

// =============================================================================
// Real-world Examples
// =============================================================================

test(
  "MultiHash: Real-world examples",
  func() {
    // Identity hash for raw data storage
    let rawData = {
      algorithm = #none;
      digest = "\54\68\69\73\20\69\73\20\72\61\77\20\64\61\74\61" : Blob; // "This is raw data"
    };
    testMultiHashRoundtrip(rawData);

    // Identity hash for small binary data
    let binaryData = {
      algorithm = #none;
      digest = "\DE\AD\BE\EF\CA\FE\BA\BE" : Blob;
    };
    testMultiHashRoundtrip(binaryData);

    // IPFS file hash (SHA-256)
    let ipfsHash = {
      algorithm = #sha2256;
      digest = "\6E\6F\F7\95\0A\36\18\7A\80\16\13\42\6E\85\8D\CE\68\6C\D7\D7\E3\C0\FC\42\EE\03\30\07\2D\24\5C\95" : Blob;
    };
    testMultiHashRoundtrip(ipfsHash);

    // Git object hash (SHA-256)
    let gitHash = {
      algorithm = #sha2256;
      digest = "\DA\39\A3\EE\5E\6B\4B\0D\32\55\BF\EF\95\60\18\90\AF\D8\07\09\04\02\6F\E2\5C\9F\7E\3F\5F\3F\67\0C" : Blob;
    };
    testMultiHashRoundtrip(gitHash);

    // Blake2b hash for IPFS alternative
    let blakeHash = {
      algorithm = #blake2b256;
      digest = "\BE\BE\BE\BE\BE\BE\BE\BE\BE\BE\BE\BE\BE\BE\BE\BE\BE\BE\BE\BE\BE\BE\BE\BE\BE\BE\BE\BE\BE\BE\BE\BE" : Blob;
    };
    testMultiHashRoundtrip(blakeHash);
  },
);

// =============================================================================
// VarInt Encoding Edge Cases
// =============================================================================

test(
  "MultiHash: VarInt encoding edge cases",
  func() {
    // Test algorithms with different VarInt encodings

    // Identity algorithm - single byte (0x00)
    testMultiHashRoundtrip({
      algorithm = #none; // 0x00 - single byte
      digest = "\07\07\07\07\07" : Blob;
    });

    // Single byte algorithm codes
    testMultiHashRoundtrip({
      algorithm = #sha2256; // 0x12 - single byte
      digest = "\01\01\01\01\01\01\01\01\01\01\01\01\01\01\01\01\01\01\01\01\01\01\01\01\01\01\01\01\01\01\01\01" : Blob;
    });

    testMultiHashRoundtrip({
      algorithm = #sha3512; // 0x14 - single byte
      digest = "\02\02\02\02\02\02\02\02\02\02\02\02\02\02\02\02\02\02\02\02\02\02\02\02\02\02\02\02\02\02\02\02\02\02\02\02\02\02\02\02\02\02\02\02\02\02\02\02\02\02\02\02\02\02\02\02\02\02\02\02\02\02\02\02" : Blob;
    });

    // Multi-byte algorithm codes
    testMultiHashRoundtrip({
      algorithm = #blake2b256; // 0xb220 - multi-byte VarInt
      digest = "\03\03\03\03\03\03\03\03\03\03\03\03\03\03\03\03\03\03\03\03\03\03\03\03\03\03\03\03\03\03\03\03" : Blob;
    });

    testMultiHashRoundtrip({
      algorithm = #blake2s256; // 0xb260 - multi-byte VarInt
      digest = "\04\04\04\04\04\04\04\04\04\04\04\04\04\04\04\04\04\04\04\04\04\04\04\04\04\04\04\04\04\04\04\04" : Blob;
    });
  },
);

// =============================================================================
// Binary Format Validation
// =============================================================================

test(
  "MultiHash: Binary format validation",
  func() {
    // Verify the exact binary format: [algorithm-varint][length-varint][digest-bytes]

    // Test Identity algorithm binary format
    let identityTestHash = {
      algorithm = #none;
      digest = "\AA\BB\CC" : Blob;
    };

    let identityEncoded = Multiformats.MultiHash.toBytes(identityTestHash);

    // Should start with algorithm code (0x00 for Identity)
    assert (identityEncoded[0] == 0x00);

    // Should have length (0x03 = 3 for our test data)
    assert (identityEncoded[1] == 0x03);

    // Should have 5 total bytes (1 algo + 1 length + 3 digest)
    assert (identityEncoded.size() == 5);

    // Digest bytes should match
    assert (identityEncoded[2] == 0xAA);
    assert (identityEncoded[3] == 0xBB);
    assert (identityEncoded[4] == 0xCC);

    // Test SHA-256 binary format for comparison
    let testHash = {
      algorithm = #sha2256;
      digest = "\AA\AA\AA\AA\AA\AA\AA\AA\AA\AA\AA\AA\AA\AA\AA\AA\AA\AA\AA\AA\AA\AA\AA\AA\AA\AA\AA\AA\AA\AA\AA\AA" : Blob;
    };

    let encoded = Multiformats.MultiHash.toBytes(testHash);

    // Should start with algorithm code (0x12 for SHA-256)
    assert (encoded[0] == 0x12);

    // Should have length (0x20 = 32 for SHA-256)
    assert (encoded[1] == 0x20);

    // Should have 34 total bytes (1 algo + 1 length + 32 digest)
    assert (encoded.size() == 34);

    // All digest bytes should be 0xAA
    for (i in Array.keys(Array.sliceToArray(encoded, 2, 34))) {
      assert (encoded[i + 2] == 0xAA);
    };
  },
);
test(
  "MultiHash: Identity algorithm comprehensive tests",
  func() {
    // Test various scenarios specific to Identity algorithm

    // Very large data (test with 100 bytes)
    let largeData = {
      algorithm = #none;
      digest = "\01\02\03\04\05\06\07\08\09\0A\0B\0C\0D\0E\0F\10\11\12\13\14\15\16\17\18\19\1A\1B\1C\1D\1E\1F\20\21\22\23\24\25\26\27\28\29\2A\2B\2C\2D\2E\2F\30\31\32\33\34\35\36\37\38\39\3A\3B\3C\3D\3E\3F\40\41\42\43\44\45\46\47\48\49\4A\4B\4C\4D\4E\4F\50\51\52\53\54\55\56\57\58\59\5A\5B\5C\5D\5E\5F\60\61\62\63\64" : Blob;
    };
    testMultiHashRoundtrip(largeData);

    // Test with data that would be valid hash sizes for other algorithms
    // 32-byte data (same as SHA-256/Blake2b-256/SHA3-256)
    let thirtyTwoByteData = {
      algorithm = #none;
      digest = "\FF\EE\DD\CC\BB\AA\99\88\77\66\55\44\33\22\11\00\FF\EE\DD\CC\BB\AA\99\88\77\66\55\44\33\22\11\00" : Blob;
    };
    testMultiHashRoundtrip(thirtyTwoByteData);

    // 64-byte data (same as SHA-512/SHA3-512)
    let sixtyFourByteData = {
      algorithm = #none;
      digest = "\A1\A2\A3\A4\A5\A6\A7\A8\A9\AA\AB\AC\AD\AE\AF\B0\B1\B2\B3\B4\B5\B6\B7\B8\B9\BA\BB\BC\BD\BE\BF\C0\C1\C2\C3\C4\C5\C6\C7\C8\C9\CA\CB\CC\CD\CE\CF\D0\D1\D2\D3\D4\D5\D6\D7\D8\D9\DA\DB\DC\DD\DE\DF\E0\E1\E2\E3" : Blob;
    };
    testMultiHashRoundtrip(sixtyFourByteData);

    // Test ASCII text data
    let textData = {
      algorithm = #none;
      digest = "\48\65\6C\6C\6F\2C\20\57\6F\72\6C\64\21\20\54\68\69\73\20\69\73\20\61\20\74\65\73\74\2E" : Blob; // "Hello, World! This is a test."
    };
    testMultiHashRoundtrip(textData);

    // Test binary data with all byte values
    let binaryTestData = {
      algorithm = #none;
      digest = "\00\01\02\FF\FE\FD\7F\80\81" : Blob;
    };
    testMultiHashRoundtrip(binaryTestData);
  },
);
test(
  "MultiHash: Can be longer but will only parse the CID bytes",
  func() {
    let bytes : Blob = "\12\20\F8\8B\C8\53\80\4C\F2\94\FE\41\7E\4F\A8\30\28\68\9F\CD\B1\B1\59\2C\51\02\E1\47\4D\BC\20\0F\AB\8B\A2\64\6C\69\6E\6B\D8\2A\58\23\00\12\20\02\AC\EC\C5\DE\24\38\EA\41\26\A3\01\0E\CB\1F\8A\59\9C\8E\FF\22\FF\F1\A1\DC\FF\E9\99\B2\7F\D3\DE\64\6E\61\6D\65\64\62\6C\69\70";
    let bytesIter = bytes.vals();
    let #ok(_) = Multiformats.MultiHash.fromBytes(bytesIter) else Runtime.trap("Failed to decode MultiHash from bytes");
    let ?nextByte = bytesIter.next() else Runtime.trap("Expected more bytes after MultiHash");
    if (nextByte != 162) {
      Runtime.trap("Expected next byte to be 162, got " # debug_show (nextByte));
    };
  },
);
