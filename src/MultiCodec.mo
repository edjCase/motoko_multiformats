import Nat "mo:core/Nat";
import Iter "mo:core/Iter";
import Nat8 "mo:core/Nat8";
import Result "mo:core/Result";
import List "mo:core/List";
import Buffer "mo:buffer";
import LEB128 "mo:leb128";

module {

  /// Represents various codec types used in IPFS/IPLD and cryptographic keys.
  ///
  /// ```motoko
  /// let contentCodec : Codec = #dagCbor; // IPLD DAG-CBOR
  /// let keyCodec : Codec = #ed25519Pub; // Ed25519 public key
  /// ```
  public type Codec = {
    // Content/Data Codecs
    #raw; // 0x55 - Raw binary data
    #dagPb; // 0x70 - DAG-PB (Protocol Buffers)
    #dagCbor; // 0x71 - DAG-CBOR
    #dagJson; // 0x0129 - DAG-JSON

    // Cryptographic Key Codecs
    #ed25519Pub; // 0xed - Ed25519 public key
    #secp256k1Pub; // 0xe7 - secp256k1 public key
    #p256Pub; // 0x1200 - P-256 public key
    #p384Pub; // 0x1201 - P-384 public key
    #p521Pub; // 0x1202 - P-521 public key
    #ed448Pub; // 0xee - Ed448 public key
    #x25519Pub; // 0xec - X25519 public key
    #x448Pub; // 0xef - X448 public key
    #rsaPub; // 0x1205 - RSA public key
    #bls12381G1Pub; // 0xea - BLS12-381 G1 public key
    #bls12381G2Pub; // 0xeb - BLS12-381 G2 public key

    // Hash Algorithm Codecs (for multihash compatibility)
    #sha2256; // 0x12 - SHA-256
    #sha2512; // 0x13 - SHA-512
    #blake2b256; // 0xb220 - Blake2b-256
    #blake2s256; // 0xb260 - Blake2s-256
    #sha3256; // 0x16 - SHA3-256
    #sha3512; // 0x14 - SHA3-512
  };

  /// Encodes a codec as its multicodec varint representation.
  ///
  /// ```motoko
  /// let bytes = MultiCodec.toBytes(#ed25519Pub);
  /// // Returns: [0xed] (varint-encoded 237)
  /// ```
  public func toBytes(codec : Codec) : [Nat8] {
    let buffer = List.empty<Nat8>(); // 10 bytes is enough for any varint
    toBytesBuffer(Buffer.fromList(buffer), codec);
    List.toArray(buffer);
  };

  /// Encodes a codec as its multicodec varint representation into a buffer.
  ///
  /// ```motoko
  /// let buffer = Buffer.Buffer<Nat8>(10);
  /// MultiCodec.toBytesBuffer(buffer, #ed25519Pub);
  /// // buffer now contains: [0xed]
  /// ```
  public func toBytesBuffer(buffer : Buffer.Buffer<Nat8>, codec : Codec) {
    let code = toCode(codec);
    LEB128.toUnsignedBytesBuffer(buffer, code);
  };

  /// Decodes a multicodec varint from bytes.
  ///
  /// ```motoko
  /// let bytes : [Nat8] = [0xed];
  /// let ?codec = MultiCodec.fromBytes(bytes.vals());
  /// // Returns: #ed25519Pub
  /// ```
  public func fromBytes(bytes : Iter.Iter<Nat8>) : Result.Result<Codec, Text> {
    switch (LEB128.fromUnsignedBytes(bytes)) {
      case (#ok(code)) switch (fromCode(code)) {
        case (?codec) #ok(codec);
        case (null) #err("Unsupported multicodec code: " # Nat.toText(code));
      };
      case (#err(err)) #err("Failed to decode multicodec Var Int: " # err);
    };
  };

  private func toCode(codec : Codec) : Nat {
    switch (codec) {
      // Content codecs
      case (#raw) 0x55;
      case (#dagPb) 0x70;
      case (#dagCbor) 0x71;
      case (#dagJson) 0x0129;

      // Key codecs
      case (#ed25519Pub) 0xed;
      case (#secp256k1Pub) 0xe7;
      case (#p256Pub) 0x1200;
      case (#p384Pub) 0x1201;
      case (#p521Pub) 0x1202;
      case (#ed448Pub) 0xee;
      case (#x25519Pub) 0xec;
      case (#x448Pub) 0xef;
      case (#rsaPub) 0x1205;
      case (#bls12381G1Pub) 0xea;
      case (#bls12381G2Pub) 0xeb;

      // Hash algorithms
      case (#sha2256) 0x12;
      case (#sha2512) 0x13;
      case (#blake2b256) 0xb220;
      case (#blake2s256) 0xb260;
      case (#sha3256) 0x16;
      case (#sha3512) 0x14;
    };
  };

  // Convert numeric code to codec
  private func fromCode(code : Nat) : ?Codec {
    switch (code) {
      // Content codecs
      case (0x55) ?#raw;
      case (0x70) ?#dagPb;
      case (0x71) ?#dagCbor;
      case (0x0129) ?#dagJson;

      // Key codecs
      case (0xed) ?#ed25519Pub;
      case (0xe7) ?#secp256k1Pub;
      case (0x1200) ?#p256Pub;
      case (0x1201) ?#p384Pub;
      case (0x1202) ?#p521Pub;
      case (0xee) ?#ed448Pub;
      case (0xec) ?#x25519Pub;
      case (0xef) ?#x448Pub;
      case (0x1205) ?#rsaPub;
      case (0xea) ?#bls12381G1Pub;
      case (0xeb) ?#bls12381G2Pub;

      // Hash algorithms
      case (0x12) ?#sha2256;
      case (0x13) ?#sha2512;
      case (0xb220) ?#blake2b256;
      case (0xb260) ?#blake2s256;
      case (0x16) ?#sha3256;
      case (0x14) ?#sha3512;

      case (_) null;
    };
  };
};
