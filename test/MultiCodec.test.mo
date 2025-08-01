import Multiformats "../src";
import { test } "mo:test";
import Runtime "mo:core/Runtime";

func testMultiCodec(
  codec : Multiformats.MultiCodec.Codec,
  expectedBytes : [Nat8],
) {
  testMultiCodecEncoding(codec, expectedBytes);
  testMultiCodecDecoding(expectedBytes, codec);
};

func testMultiCodecEncoding(
  codec : Multiformats.MultiCodec.Codec,
  expectedBytes : [Nat8],
) {
  let actualBytes = Multiformats.MultiCodec.toBytes(codec);

  if (actualBytes != expectedBytes) {
    Runtime.trap(
      "MultiCodec encoding mismatch for " # debug_show (codec) #
      "\nExpected: " # debug_show (expectedBytes) #
      "\nActual:   " # debug_show (actualBytes)
    );
  };
};

func testMultiCodecDecoding(
  bytes : [Nat8],
  expectedCodec : Multiformats.MultiCodec.Codec,
) {
  let actualCodec = switch (Multiformats.MultiCodec.fromBytes(bytes.vals())) {
    case (#ok(codec)) codec;
    case (#err(err)) Runtime.trap("MultiCodec decoding failed for: " # debug_show (bytes) # "\nError: " # err);
  };

  if (actualCodec != expectedCodec) {
    Runtime.trap(
      "MultiCodec decoding mismatch for " # debug_show (bytes) #
      "\nExpected: " # debug_show (expectedCodec) #
      "\nActual:   " # debug_show (actualCodec)
    );
  };
};

func testMultiCodecRoundtrip(codec : Multiformats.MultiCodec.Codec) {
  let encoded = Multiformats.MultiCodec.toBytes(codec);
  let decoded = switch (Multiformats.MultiCodec.fromBytes(encoded.vals())) {
    case (#ok(codec)) codec;
    case (#err(err)) Runtime.trap("Round-trip decode failed for: " # debug_show (codec) # "\nError: " # err);
  };

  if (decoded != codec) {
    Runtime.trap(
      "MultiCodec round-trip mismatch for " # debug_show (codec) #
      "\nOriginal: " # debug_show (codec) #
      "\nDecoded:  " # debug_show (decoded)
    );
  };
};

func testMultiCodecError(invalidBytes : [Nat8]) {
  switch (Multiformats.MultiCodec.fromBytes(invalidBytes.vals())) {
    case (#ok(codec)) Runtime.trap("Expected MultiCodec decode error for " # debug_show (invalidBytes) # " but got: " # debug_show (codec));
    case (#err(_)) {}; // Expected error
  };
};

// =============================================================================
// Content/Data Codecs
// =============================================================================

test(
  "MultiCodec: Content codecs",
  func() {
    testMultiCodec(#raw, [0x55]);
    testMultiCodec(#dagPb, [0x70]);
    testMultiCodec(#dagCbor, [0x71]);
    testMultiCodec(#dagJson, [0xA9, 0x02]); // VarInt encoded 297
  },
);

// =============================================================================
// Ed25519 Key Tests
// =============================================================================

test(
  "MultiCodec: Ed25519 keys",
  func() {
    testMultiCodec(#ed25519Pub, [0xED, 0x01]); // VarInt encoded 237
  },
);

// =============================================================================
// secp256k1 Key Tests
// =============================================================================

test(
  "MultiCodec: secp256k1 keys",
  func() {
    testMultiCodec(#secp256k1Pub, [0xE7, 0x01]); // VarInt encoded 231
  },
);

// =============================================================================
// NIST P-curve Key Tests
// =============================================================================

test(
  "MultiCodec: NIST P-curve keys",
  func() {
    testMultiCodec(#p256Pub, [0x80, 0x24]); // VarInt encoded 4608
    testMultiCodec(#p384Pub, [0x81, 0x24]); // VarInt encoded 4609
    testMultiCodec(#p521Pub, [0x82, 0x24]); // VarInt encoded 4610
  },
);

// =============================================================================
// Ed448 and X-curve Key Tests
// =============================================================================

test(
  "MultiCodec: Ed448 and X-curve keys",
  func() {
    testMultiCodec(#ed448Pub, [0xEE, 0x01]); // VarInt encoded 238
    testMultiCodec(#x25519Pub, [0xEC, 0x01]); // VarInt encoded 236
    testMultiCodec(#x448Pub, [0xEF, 0x01]); // VarInt encoded 239
  },
);

// =============================================================================
// RSA and BLS Key Tests
// =============================================================================

test(
  "MultiCodec: RSA and BLS keys",
  func() {
    testMultiCodec(#rsaPub, [0x85, 0x24]); // VarInt encoded 4613
    testMultiCodec(#bls12381G1Pub, [0xEA, 0x01]); // VarInt encoded 234
    testMultiCodec(#bls12381G2Pub, [0xEB, 0x01]); // VarInt encoded 235
  },
);

// =============================================================================
// Hash Algorithm Codecs
// =============================================================================

test(
  "MultiCodec: Hash algorithms",
  func() {
    testMultiCodec(#sha2256, [0x12]);
    testMultiCodec(#sha2512, [0x13]);
    testMultiCodec(#blake2b256, [0xA0, 0xE4, 0x02]); // VarInt encoded 45600
    testMultiCodec(#blake2s256, [0xE0, 0xE4, 0x02]); // VarInt encoded 45664
    testMultiCodec(#sha3256, [0x16]);
    testMultiCodec(#sha3512, [0x14]);
  },
);

// =============================================================================
// Error Cases
// =============================================================================

test(
  "MultiCodec: Error cases",
  func() {
    // Empty input
    testMultiCodecError([]);

    // Invalid VarInt (incomplete)
    testMultiCodecError([0x80]); // Indicates more bytes but none follow

    // Unknown codec codes
    testMultiCodecError([0x99, 0x99]); // Some random unsupported code
    testMultiCodecError([0xFF, 0xFF, 0xFF, 0xFF, 0x0F]); // Very large code
  },
);

// =============================================================================
// Real-world Usage Examples
// =============================================================================

test(
  "MultiCodec: Real-world examples",
  func() {
    // CID components
    testMultiCodecRoundtrip(#dagCbor); // Common in IPFS
    testMultiCodecRoundtrip(#dagPb); // Legacy IPFS format
    testMultiCodecRoundtrip(#raw); // Raw data

    // DID key components
    testMultiCodecRoundtrip(#ed25519Pub); // Most common DID key
    testMultiCodecRoundtrip(#secp256k1Pub); // Bitcoin/Ethereum style
    testMultiCodecRoundtrip(#p256Pub); // NIST standard

    // Multihash components
    testMultiCodecRoundtrip(#sha2256); // Most common hash
    testMultiCodecRoundtrip(#blake2b256); // Alternative hash
    testMultiCodecRoundtrip(#sha3256); // SHA-3 variant
  },
);

// =============================================================================
// VarInt Boundary Cases
// =============================================================================

test(
  "MultiCodec: VarInt boundary cases",
  func() {
    // Test codecs that have interesting VarInt encodings

    // Single byte codes (< 128)
    testMultiCodec(#raw, [0x55]);
    testMultiCodec(#dagPb, [0x70]);
    testMultiCodec(#dagCbor, [0x71]);
    testMultiCodec(#sha2256, [0x12]);
    testMultiCodec(#sha2512, [0x13]);

    // Two byte codes (>= 128)
    testMultiCodec(#ed25519Pub, [0xED, 0x01]);
    testMultiCodec(#secp256k1Pub, [0xE7, 0x01]);
    testMultiCodec(#dagJson, [0xA9, 0x02]);

    // Three byte codes (large values)
    testMultiCodec(#p256Pub, [0x80, 0x24]);
    testMultiCodec(#blake2b256, [0xA0, 0xE4, 0x02]);
  },
);
