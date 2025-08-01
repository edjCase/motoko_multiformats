# Motoko Multiformats

A comprehensive Motoko library for working with Multiformats, including multicodec, multihash, multibase, and variable-length integers. This library provides IPFS/IPLD-compatible implementations for encoding and decoding various data formats.

## Features

- **MultiBase**: Encode/decode data with various base encodings (Base58, Base32, Base64, Base16) with proper prefix handling
- **MultiCodec**: Support for IPFS/IPLD codec types and cryptographic key formats
- **MultiHash**: Hash algorithm identification and multihash format support

## Installation

### MOPS

```bash
mops install multiformats
```

To setup MOPS package manager, follow the instructions from the [MOPS Site](https://j4mwm-bqaaa-aaaam-qajbq-cai.ic0.app/)

## Usage

```motoko
import Multiformats "mo:multiformats";

// Access individual modules
let { MultiBase; MultiCodec; MultiHash; VarInt } = Multiformats;
```

## API Reference

### MultiBase

MultiBase provides encoding and decoding for various base formats with standardized prefixes.

#### Types

**`MultiBase`**

Represents the multibase encoding format with its character prefix:

```motoko
public type MultiBase = {
    #base58btc;    // 'z' prefix
    #base32;       // 'b' prefix
    #base32Upper;  // 'B' prefix
    #base64;       // 'm' prefix
    #base64Url;    // 'u' prefix
    #base64UrlPad; // 'U' prefix
    #base16;       // 'f' prefix
    #base16Upper;  // 'F' prefix
};
```

**`MultiBaseOrIdentity`**

Extends MultiBase to include identity encoding (no encoding):

```motoko
public type MultiBaseOrIdentity = MultiBase or {
    #identity; // 0x00 byte prefix (no encoding)
};
```

#### Functions

**`toText(bytes: Iter.Iter<Nat8>, encoding: MultiBase): Text`**

Converts bytes to multibase text with proper prefix:

```motoko
let bytes: [Nat8] = [0x01, 0x02, 0x03];
let text = MultiBase.toText(bytes.vals(), #base58btc);
// Returns: "z3mJ" (example base58btc encoding)
```

**`fromText(text: Text): Result.Result<([Nat8], MultiBase), Text>`**

Converts multibase text back to bytes and encoding type:

```motoko
let text = "z3mJ"; // Example base58btc encoding
let result = MultiBase.fromText(text);
// Returns: #ok(([0x01, 0x02, 0x03], #base58btc))
```

**`fromTextWithoutPrefix(text: Text, encoding: MultiBase): Result.Result<[Nat8], Text>`**

Converts base text to bytes using a specific encoding type (without prefix):

```motoko
let text = "3mJ"; // Base58 encoded data without prefix
let result = MultiBase.fromTextWithoutPrefix(text, #base58btc);
// Returns: #ok([0x01, 0x02, 0x03])
```

**`fromEncodedBytes(bytes: Iter.Iter<Nat8>): Result.Result<([Nat8], MultiBaseOrIdentity), Text>`**

Converts multibase-encoded bytes to their original bytes with encoding type. Used for CID byte decoding in DAGCBOR:

```motoko
let encodedBytes: [Nat8] = [0x5a, 0x33, 0x6d, 0x4a]; // 'z' prefix + base58 data
let result = MultiBase.fromEncodedBytes(encodedBytes.vals());
// Returns: #ok(([0x01, 0x02, 0x03], #base58btc))

let identityBytes: [Nat8] = [0x00, 0x01, 0x02, 0x03]; // identity prefix + raw data
let result2 = MultiBase.fromEncodedBytes(identityBytes.vals());
// Returns: #ok(([0x01, 0x02, 0x03], #identity))
```

**`toEncodedBytes(bytes: Iter.Iter<Nat8>, encoding: MultiBaseOrIdentity): [Nat8]`**

Converts bytes to multibase-encoded bytes with encoding type prefix. Complement to `fromEncodedBytes`:

```motoko
let bytes: [Nat8] = [0x01, 0x02, 0x03];
let encodedBytes = MultiBase.toEncodedBytes(bytes.vals(), #base58btc);
// Returns: [0x5a, 0x33, 0x6d, 0x4a] ('z' prefix + base58 data as UTF-8)

let identityBytes = MultiBase.toEncodedBytes(bytes.vals(), #identity);
// Returns: [0x00, 0x01, 0x02, 0x03] (identity prefix + raw data)
```

**`baseFromByte(byte: Nat8): ?MultiBaseOrIdentity`**

Converts a byte value to its corresponding MultiBase encoding type:

```motoko
let encoding = MultiBase.baseFromByte(0x5a); // 'z' as byte
// Returns: ?#base58btc

let identity = MultiBase.baseFromByte(0x00); // identity (no encoding)
// Returns: ?#identity
```

**`baseToByte(encoding: MultiBaseOrIdentity): Nat8`**

Converts a MultiBase encoding type to its corresponding byte value:

```motoko
let byte = MultiBase.baseToByte(#base58btc);
// Returns: 0x5a ('z' as byte)

let identityByte = MultiBase.baseToByte(#identity);
// Returns: 0x00
```

**`baseFromChar(char: Char): ?MultiBase`**

Converts a character prefix to its corresponding MultiBase encoding type:

```motoko
let encoding = MultiBase.baseFromChar('z');
// Returns: ?#base58btc

let invalid = MultiBase.baseFromChar('x');
// Returns: null
```

**`baseToChar(encoding: MultiBase): Char`**

Converts a MultiBase encoding type to its corresponding character prefix:

```motoko
let char = MultiBase.baseToChar(#base58btc);
// Returns: 'z'

let base32Char = MultiBase.baseToChar(#base32);
// Returns: 'b'
```

### MultiCodec

MultiCodec provides support for IPFS/IPLD codec identification and cryptographic key formats.

#### Types

**`Codec`**

Represents various codec types used in IPFS/IPLD and cryptographic keys:

```motoko
public type Codec = {
    // Content/Data Codecs
    #raw;          // 0x55 - Raw binary data
    #dagPb;       // 0x70 - DAG-PB (Protocol Buffers)
    #dagCbor;     // 0x71 - DAG-CBOR
    #dagJson;     // 0x0129 - DAG-JSON

    // Cryptographic Key Codecs
    #ed25519Pub;       // 0xed - Ed25519 public key
    #secp256k1Pub;     // 0xe7 - secp256k1 public key
    #p256Pub;          // 0x1200 - P-256 public key
    #p384Pub;          // 0x1201 - P-384 public key
    #p521Pub;          // 0x1202 - P-521 public key
    #ed448Pub;         // 0xee - Ed448 public key
    #x25519Pub;        // 0xec - X25519 public key
    #x448Pub;          // 0xef - X448 public key
    #rsaPub;           // 0x1205 - RSA public key
    #bls12381G1Pub;  // 0xea - BLS12-381 G1 public key
    #bls12381G2Pub;  // 0xeb - BLS12-381 G2 public key

    // Hash Algorithm Codecs (for multihash compatibility)
    #sha2256;     // 0x12 - SHA-256
    #sha2512;     // 0x13 - SHA-512
    #blake2b256;  // 0xb220 - Blake2b-256
    #blake2s256;  // 0xb260 - Blake2s-256
    #sha3256;     // 0x16 - SHA3-256
    #sha3512;     // 0x14 - SHA3-512
};
```

#### Functions

**`toBytes(codec: Codec): [Nat8]`**

Encodes a codec as its multicodec varint representation:

```motoko
let bytes = MultiCodec.toBytes(#ed25519Pub);
// Returns: [0xed] (varint-encoded 237)
```

**`toBytesBuffer(buffer: Buffer.Buffer<Nat8>, codec: Codec)`**

Encodes a codec as its multicodec varint representation into a buffer:

```motoko
let buffer = Buffer.Buffer<Nat8>(10);
MultiCodec.toBytesBuffer(buffer, #ed25519Pub);
// buffer now contains: [0xed]
```

**`fromBytes(bytes: Iter.Iter<Nat8>): Result.Result<Codec, Text>`**

Decodes a multicodec varint from bytes:

```motoko
let bytes: [Nat8] = [0xed];
let result = MultiCodec.fromBytes(bytes.vals());
// Returns: #ok(#ed25519Pub)
```

### MultiHash

MultiHash provides hash algorithm identification and multihash format support.

#### Types

**`Algorithm`**

Represents hash algorithms supported in multihash format:

```motoko
public type Algorithm = {
    #sha2256;     // SHA-256 (32 bytes)
    #sha2512;     // SHA-512 (64 bytes)
    #blake2b256;  // Blake2b-256 (32 bytes)
    #blake2s256;  // Blake2s-256 (32 bytes)
    #sha3256;     // SHA3-256 (32 bytes)
    #sha3512;     // SHA3-512 (64 bytes)
};
```

**`MultiHash`**

Represents a multihash with algorithm and digest:

```motoko
public type MultiHash = {
    algorithm: Algorithm;
    digest: Blob;
};
```

#### Functions

**`toBytes(multihash: MultiHash): [Nat8]`**

Encodes a multihash to its binary representation:

```motoko
let multihash: MultiHash = {
    algorithm = #sha2256;
    digest = "\E3\B0\C4\42...";
};
let bytes = MultiHash.toBytes(multihash);
// Returns: [0x12, 0x20, 0xE3, 0xB0, ...]
```

**`toBytesBuffer(buffer: Buffer.Buffer<Nat8>, multihash: MultiHash)`**

Encodes a multihash to its binary representation into a buffer:

```motoko
let multihash: MultiHash = {
    algorithm = #sha2256;
    digest = "\E3\B0\C4\42...";
};
let buffer = Buffer.Buffer<Nat8>(multihash.digest.size() + 10);
MultiHash.toBytesBuffer(buffer, multihash);
// buffer now contains: [0x12, 0x20, 0xE3, 0xB0, ...]
```

**`fromBytes(bytes: Iter.Iter<Nat8>): Result.Result<MultiHash, Text>`**

Decodes a multihash from bytes:

```motoko
let bytes: [Nat8] = [0x12, 0x20, 0xE3, 0xB0, ...];
let result = MultiHash.fromBytes(bytes.vals());
// Returns: #ok({ algorithm = #sha2256; digest = ... })
```

### VarInt

VarInt provides variable-length integer encoding and decoding.

#### Functions

**`fromBytes(bytes: Iter.Iter<Nat8>): Result.Result<Nat, Text>`**

Decodes a variable-length integer from a byte iterator:

```motoko
let bytes: [Nat8] = [0xAC, 0x02]; // 300 encoded as varint
let result = VarInt.fromBytes(bytes.vals());
// Returns: #ok(300)
```

**`toBytes(n: Nat): [Nat8]`**

Encodes a natural number as a variable-length integer:

```motoko
let encoded = VarInt.toBytes(300);
// Returns: [0xAC, 0x02]
```

**`toBytesBuffer(buffer: Buffer.Buffer<Nat8>, n: Nat)`**

Encodes a natural number as a variable-length integer into a buffer:

```motoko
let buffer = Buffer.Buffer<Nat8>(10);
VarInt.toBytesBuffer(buffer, 300);
// buffer now contains: [0xAC, 0x02]
```

## Testing

```bash
mops test
```

## License

MIT License - see LICENSE file for details.

## Contributing

Contributions are welcome! Please feel free to submit issues and pull requests.
