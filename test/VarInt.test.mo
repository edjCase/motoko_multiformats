import Multiformats "../src"; // Adjust path to your multiformats module
import Debug "mo:base/Debug";
import { test } "mo:test";

func testVarInt(
  value : Nat,
  expectedBytes : [Nat8],
) {
  testVarIntEncoding(value, expectedBytes);
  testVarIntDecoding(expectedBytes, value);
  testVarIntRoundtrip(value);
};

func testVarIntEncoding(
  value : Nat,
  expectedBytes : [Nat8],
) {
  let actualBytes = Multiformats.VarInt.toBytes(value);

  if (actualBytes != expectedBytes) {
    Debug.trap(
      "VarInt encoding mismatch for " # debug_show (value) #
      "\nExpected: " # debug_show (expectedBytes) #
      "\nActual:   " # debug_show (actualBytes)
    );
  };
};

func testVarIntDecoding(
  bytes : [Nat8],
  expectedValue : Nat,
) {
  let actualValue = switch (Multiformats.VarInt.fromBytes(bytes.vals())) {
    case (#ok(value)) value;
    case (#err(err)) Debug.trap("VarInt decoding failed for: " # debug_show (bytes) # "\nError: " # err);
  };

  if (actualValue != expectedValue) {
    Debug.trap(
      "VarInt decoding mismatch for " # debug_show (bytes) #
      "\nExpected: " # debug_show (expectedValue) #
      "\nActual:   " # debug_show (actualValue)
    );
  };
};

func testVarIntRoundtrip(value : Nat) {
  let encoded = Multiformats.VarInt.toBytes(value);
  let decoded = switch (Multiformats.VarInt.fromBytes(encoded.vals())) {
    case (#ok(value)) value;
    case (#err(err)) Debug.trap("Round-trip decode failed for: " # debug_show (value) # "\nError: " # err);
  };

  if (decoded != value) {
    Debug.trap(
      "VarInt round-trip mismatch for " # debug_show (value) #
      "\nOriginal: " # debug_show (value) #
      "\nDecoded:  " # debug_show (decoded)
    );
  };
};

func testVarIntError(invalidBytes : [Nat8]) {
  switch (Multiformats.VarInt.fromBytes(invalidBytes.vals())) {
    case (#ok(value)) Debug.trap("Expected VarInt decode error for " # debug_show (invalidBytes) # " but got: " # debug_show (value));
    case (#err(_)) {}; // Expected error
  };
};

// =============================================================================
// Single Byte Values (0-127)
// =============================================================================

test(
  "VarInt: Single byte values",
  func() {
    testVarInt(0, [0x00]);
    testVarInt(1, [0x01]);
    testVarInt(127, [0x7F]);
  },
);

// =============================================================================
// Two Byte Values (128-16383)
// =============================================================================

test(
  "VarInt: Two byte values",
  func() {
    testVarInt(128, [0x80, 0x01]);
    testVarInt(129, [0x81, 0x01]);
    testVarInt(300, [0xAC, 0x02]);
    testVarInt(16383, [0xFF, 0x7F]);
  },
);

// =============================================================================
// Three Byte Values (16384+)
// =============================================================================

test(
  "VarInt: Three byte values",
  func() {
    testVarInt(16384, [0x80, 0x80, 0x01]);
    testVarInt(65536, [0x80, 0x80, 0x04]);
    testVarInt(2097151, [0xFF, 0xFF, 0x7F]);
  },
);

// =============================================================================
// Multicodec Examples (Real-world values)
// =============================================================================

test(
  "VarInt: Multicodec values",
  func() {
    // Common multicodec values
    testVarInt(0x12, [0x12]); // SHA-256
    testVarInt(0x55, [0x55]); // Raw
    testVarInt(0x70, [0x70]); // DAG-PB
    testVarInt(0x71, [0x71]); // DAG-CBOR
    testVarInt(0xed, [0xED, 0x01]); // Ed25519 public key
    testVarInt(0xe7, [0xE7, 0x01]); // secp256k1 public key
    testVarInt(0x1200, [0x80, 0x24]); // P-256 public key
    testVarInt(0xb220, [0xA0, 0xE4, 0x02]); // Blake2b-256
  },
);

// =============================================================================
// Large Values
// =============================================================================

test(
  "VarInt: Large values",
  func() {
    testVarInt(268435455, [0xFF, 0xFF, 0xFF, 0x7F]); // 4 bytes
    testVarInt(1000000, [0xC0, 0x84, 0x3D]); // 1 million
    testVarInt(4294967295, [0xFF, 0xFF, 0xFF, 0xFF, 0x0F]); // Max 32-bit
  },
);

// =============================================================================
// Round-trip Edge Cases
// =============================================================================

test(
  "VarInt: Round-trip edge cases",
  func() {
    testVarIntRoundtrip(0);
    testVarIntRoundtrip(127);
    testVarIntRoundtrip(128);
    testVarIntRoundtrip(16383);
    testVarIntRoundtrip(16384);
    testVarIntRoundtrip(2097151);
    testVarIntRoundtrip(2097152);
    testVarIntRoundtrip(268435455);
  },
);

// =============================================================================
// Error Cases
// =============================================================================

test(
  "VarInt: Error cases",
  func() {
    // Empty input
    testVarIntError([]);

    // Incomplete varint (missing continuation)
    testVarIntError([0x80]); // Indicates more bytes but none follow
    testVarIntError([0x80, 0x80]); // Still incomplete
  },
);

// =============================================================================
// Protocol Buffer Compatibility Examples
// =============================================================================

test(
  "VarInt: Protocol Buffer compatibility",
  func() {
    // These should match protobuf varint encoding
    testVarInt(1, [0x01]);
    testVarInt(150, [0x96, 0x01]);
    testVarInt(3, [0x03]);
    testVarInt(270, [0x8E, 0x02]);
    testVarInt(86942, [0x9E, 0xA7, 0x05]);
  },
);

// =============================================================================
// Boundary Values
// =============================================================================

test(
  "VarInt: Boundary values",
  func() {
    // Powers of 2 minus 1 (common boundaries)
    testVarInt(127, [0x7F]); // 2^7 - 1
    testVarInt(128, [0x80, 0x01]); // 2^7
    testVarInt(16383, [0xFF, 0x7F]); // 2^14 - 1
    testVarInt(16384, [0x80, 0x80, 0x01]); // 2^14

    // Multicodec boundary cases
    testVarInt(255, [0xFF, 0x01]); // One byte in most systems
    testVarInt(256, [0x80, 0x02]); // Two bytes needed
  },
);
