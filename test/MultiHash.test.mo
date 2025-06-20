import Multiformats "../src"; // Adjust path to your multiformats module
import Debug "mo:base/Debug";
import Blob "mo:new-base/Blob";
import Array "mo:new-base/Array";
import Text "mo:new-base/Text";
import { test } "mo:test";

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
    let actualBytes = Blob.fromArray(Multiformats.MultiHash.encode(multihash));

    if (actualBytes != expectedBytes) {
        Debug.trap(
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
    let actualMultiHash = switch (Multiformats.MultiHash.decode(bytes.vals())) {
        case (#ok(mh)) mh;
        case (#err(e)) Debug.trap("MultiHash decoding failed for " # debug_show (bytes) # ": " # e);
    };

    if (actualMultiHash.algorithm != expectedMultiHash.algorithm) {
        Debug.trap(
            "MultiHash algorithm mismatch for " # debug_show (bytes) #
            "\nExpected: " # debug_show (expectedMultiHash.algorithm) #
            "\nActual:   " # debug_show (actualMultiHash.algorithm)
        );
    };

    if (actualMultiHash.digest != expectedMultiHash.digest) {
        Debug.trap(
            "MultiHash digest mismatch for " # debug_show (bytes) #
            "\nExpected: " # debug_show (expectedMultiHash.digest) #
            "\nActual:   " # debug_show (actualMultiHash.digest)
        );
    };
};

func testMultiHashRoundtrip(multihash : Multiformats.MultiHash.MultiHash) {
    let encoded = Multiformats.MultiHash.encode(multihash);
    let decoded = switch (Multiformats.MultiHash.decode(encoded.vals())) {
        case (#ok(mh)) mh;
        case (#err(e)) Debug.trap("Round-trip decode failed for " # debug_show (multihash.algorithm) # ": " # e);
    };

    if (decoded.algorithm != multihash.algorithm) {
        Debug.trap(
            "MultiHash round-trip algorithm mismatch for " # debug_show (multihash.algorithm) #
            "\nOriginal: " # debug_show (multihash.algorithm) #
            "\nDecoded:  " # debug_show (decoded.algorithm)
        );
    };

    if (decoded.digest != multihash.digest) {
        Debug.trap(
            "MultiHash round-trip digest mismatch for " # debug_show (multihash.algorithm) #
            "\nOriginal: " # debug_show (multihash.digest) #
            "\nDecoded:  " # debug_show (decoded.digest)
        );
    };
};

func testMultiHashError(invalidBytes : [Nat8], expectedError : Text) {
    switch (Multiformats.MultiHash.decode(invalidBytes.vals())) {
        case (#ok(mh)) Debug.trap("Expected error for " # debug_show (invalidBytes) # " but got: " # debug_show (mh));
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
// SHA-256 Tests (32 bytes)
// =============================================================================

test(
    "MultiHash: SHA-256",
    func() {
        // Empty string SHA-256: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
        let sha256EmptyHash : Blob = "\E3\B0\C4\42\98\FC\1C\14\9A\FB\F4\C8\99\6F\B9\24\27\AE\41\E4\64\9B\93\4C\A4\95\99\1B\78\52\B8\55";
        testMultiHash(
            #sha2_256,
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
            #sha2_512,
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
            #blake2b_256,
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
            #blake2b_256,
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
            #blake2s_256,
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
            #sha3_256,
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
        let sha3_512Hash : Blob = "\34\34\34\34\34\34\34\34\34\34\34\34\34\34\34\34\34\34\34\34\34\34\34\34\34\34\34\34\34\34\34\34\34\34\34\34\34\34\34\34\34\34\34\34\34\34\34\34\34\34\34\34\34\34\34\34\34\34\34\34\34\34\34\34";
        testMultiHash(
            #sha3_512,
            sha3_512Hash,
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
        // Test all algorithms with appropriate digest lengths
        testMultiHashRoundtrip({
            algorithm = #sha2_256;
            digest = "\11\11\11\11\11\11\11\11\11\11\11\11\11\11\11\11\11\11\11\11\11\11\11\11\11\11\11\11\11\11\11\11" : Blob;
        });

        testMultiHashRoundtrip({
            algorithm = #sha2_512;
            digest = "\22\22\22\22\22\22\22\22\22\22\22\22\22\22\22\22\22\22\22\22\22\22\22\22\22\22\22\22\22\22\22\22\22\22\22\22\22\22\22\22\22\22\22\22\22\22\22\22\22\22\22\22\22\22\22\22\22\22\22\22\22\22\22\22" : Blob;
        });

        testMultiHashRoundtrip({
            algorithm = #blake2b_256;
            digest = "\33\33\33\33\33\33\33\33\33\33\33\33\33\33\33\33\33\33\33\33\33\33\33\33\33\33\33\33\33\33\33\33" : Blob;
        });

        testMultiHashRoundtrip({
            algorithm = #blake2s_256;
            digest = "\44\44\44\44\44\44\44\44\44\44\44\44\44\44\44\44\44\44\44\44\44\44\44\44\44\44\44\44\44\44\44\44" : Blob;
        });

        testMultiHashRoundtrip({
            algorithm = #sha3_256;
            digest = "\55\55\55\55\55\55\55\55\55\55\55\55\55\55\55\55\55\55\55\55\55\55\55\55\55\55\55\55\55\55\55\55" : Blob;
        });

        testMultiHashRoundtrip({
            algorithm = #sha3_512;
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
    },
);

// =============================================================================
// Real-world Examples
// =============================================================================

test(
    "MultiHash: Real-world examples",
    func() {
        // IPFS file hash (SHA-256)
        let ipfsHash = {
            algorithm = #sha2_256;
            digest = "\6E\6F\F7\95\0A\36\18\7A\80\16\13\42\6E\85\8D\CE\68\6C\D7\D7\E3\C0\FC\42\EE\03\30\07\2D\24\5C\95" : Blob;
        };
        testMultiHashRoundtrip(ipfsHash);

        // Git object hash (SHA-256)
        let gitHash = {
            algorithm = #sha2_256;
            digest = "\DA\39\A3\EE\5E\6B\4B\0D\32\55\BF\EF\95\60\18\90\AF\D8\07\09\04\02\6F\E2\5C\9F\7E\3F\5F\3F\67\0C" : Blob;
        };
        testMultiHashRoundtrip(gitHash);

        // Blake2b hash for IPFS alternative
        let blakeHash = {
            algorithm = #blake2b_256;
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

        // Single byte algorithm codes
        testMultiHashRoundtrip({
            algorithm = #sha2_256; // 0x12 - single byte
            digest = "\01\01\01\01\01\01\01\01\01\01\01\01\01\01\01\01\01\01\01\01\01\01\01\01\01\01\01\01\01\01\01\01" : Blob;
        });

        testMultiHashRoundtrip({
            algorithm = #sha3_512; // 0x14 - single byte
            digest = "\02\02\02\02\02\02\02\02\02\02\02\02\02\02\02\02\02\02\02\02\02\02\02\02\02\02\02\02\02\02\02\02\02\02\02\02\02\02\02\02\02\02\02\02\02\02\02\02\02\02\02\02\02\02\02\02\02\02\02\02\02\02\02\02" : Blob;
        });

        // Multi-byte algorithm codes
        testMultiHashRoundtrip({
            algorithm = #blake2b_256; // 0xb220 - multi-byte VarInt
            digest = "\03\03\03\03\03\03\03\03\03\03\03\03\03\03\03\03\03\03\03\03\03\03\03\03\03\03\03\03\03\03\03\03" : Blob;
        });

        testMultiHashRoundtrip({
            algorithm = #blake2s_256; // 0xb260 - multi-byte VarInt
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

        let testHash = {
            algorithm = #sha2_256;
            digest = "\AA\AA\AA\AA\AA\AA\AA\AA\AA\AA\AA\AA\AA\AA\AA\AA\AA\AA\AA\AA\AA\AA\AA\AA\AA\AA\AA\AA\AA\AA\AA\AA" : Blob;
        };

        let encoded = Multiformats.MultiHash.encode(testHash);

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
