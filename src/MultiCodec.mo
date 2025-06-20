import Nat "mo:new-base/Nat";
import Iter "mo:new-base/Iter";
import Nat8 "mo:new-base/Nat8";
import Result "mo:new-base/Result";
import Buffer "mo:base/Buffer";
import VarInt "./VarInt";

module {

    /// Represents various codec types used in IPFS/IPLD and cryptographic keys.
    ///
    /// ```motoko
    /// let contentCodec : Codec = #dag_cbor; // IPLD DAG-CBOR
    /// let keyCodec : Codec = #ed25519_pub; // Ed25519 public key
    /// ```
    public type Codec = {
        // Content/Data Codecs
        #raw; // 0x55 - Raw binary data
        #dag_pb; // 0x70 - DAG-PB (Protocol Buffers)
        #dag_cbor; // 0x71 - DAG-CBOR
        #dag_json; // 0x0129 - DAG-JSON

        // Cryptographic Key Codecs
        #ed25519_pub; // 0xed - Ed25519 public key
        #secp256k1_pub; // 0xe7 - secp256k1 public key
        #p256_pub; // 0x1200 - P-256 public key
        #p384_pub; // 0x1201 - P-384 public key
        #p521_pub; // 0x1202 - P-521 public key
        #ed448_pub; // 0xee - Ed448 public key
        #x25519_pub; // 0xec - X25519 public key
        #x448_pub; // 0xef - X448 public key
        #rsa_pub; // 0x1205 - RSA public key
        #bls12_381_g1_pub; // 0xea - BLS12-381 G1 public key
        #bls12_381_g2_pub; // 0xeb - BLS12-381 G2 public key

        // Hash Algorithm Codecs (for multihash compatibility)
        #sha2_256; // 0x12 - SHA-256
        #sha2_512; // 0x13 - SHA-512
        #blake2b_256; // 0xb220 - Blake2b-256
        #blake2s_256; // 0xb260 - Blake2s-256
        #sha3_256; // 0x16 - SHA3-256
        #sha3_512; // 0x14 - SHA3-512
    };

    /// Encodes a codec as its multicodec varint representation.
    ///
    /// ```motoko
    /// let bytes = MultiCodec.toBytes(#ed25519_pub);
    /// // Returns: [0xed] (varint-encoded 237)
    /// ```
    public func toBytes(codec : Codec) : [Nat8] {
        let buffer = Buffer.Buffer<Nat8>(10); // 10 bytes is enough for any varint
        toBytesBuffer(buffer, codec);
        Buffer.toArray(buffer);
    };

    /// Encodes a codec as its multicodec varint representation into a buffer.
    ///
    /// ```motoko
    /// let buffer = Buffer.Buffer<Nat8>(10);
    /// MultiCodec.toBytesBuffer(buffer, #ed25519_pub);
    /// // buffer now contains: [0xed]
    /// ```
    public func toBytesBuffer(buffer : Buffer.Buffer<Nat8>, codec : Codec) {
        let code = toCode(codec);
        VarInt.toBytesBuffer(buffer, code);
    };

    /// Decodes a multicodec varint from bytes.
    ///
    /// ```motoko
    /// let bytes : [Nat8] = [0xed];
    /// let ?codec = MultiCodec.fromBytes(bytes.vals());
    /// // Returns: #ed25519_pub
    /// ```
    public func fromBytes(bytes : Iter.Iter<Nat8>) : Result.Result<Codec, Text> {
        switch (VarInt.fromBytes(bytes)) {
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
            case (#dag_pb) 0x70;
            case (#dag_cbor) 0x71;
            case (#dag_json) 0x0129;

            // Key codecs
            case (#ed25519_pub) 0xed;
            case (#secp256k1_pub) 0xe7;
            case (#p256_pub) 0x1200;
            case (#p384_pub) 0x1201;
            case (#p521_pub) 0x1202;
            case (#ed448_pub) 0xee;
            case (#x25519_pub) 0xec;
            case (#x448_pub) 0xef;
            case (#rsa_pub) 0x1205;
            case (#bls12_381_g1_pub) 0xea;
            case (#bls12_381_g2_pub) 0xeb;

            // Hash algorithms
            case (#sha2_256) 0x12;
            case (#sha2_512) 0x13;
            case (#blake2b_256) 0xb220;
            case (#blake2s_256) 0xb260;
            case (#sha3_256) 0x16;
            case (#sha3_512) 0x14;
        };
    };

    // Convert numeric code to codec
    private func fromCode(code : Nat) : ?Codec {
        switch (code) {
            // Content codecs
            case (0x55) ?#raw;
            case (0x70) ?#dag_pb;
            case (0x71) ?#dag_cbor;
            case (0x0129) ?#dag_json;

            // Key codecs
            case (0xed) ?#ed25519_pub;
            case (0xe7) ?#secp256k1_pub;
            case (0x1200) ?#p256_pub;
            case (0x1201) ?#p384_pub;
            case (0x1202) ?#p521_pub;
            case (0xee) ?#ed448_pub;
            case (0xec) ?#x25519_pub;
            case (0xef) ?#x448_pub;
            case (0x1205) ?#rsa_pub;
            case (0xea) ?#bls12_381_g1_pub;
            case (0xeb) ?#bls12_381_g2_pub;

            // Hash algorithms
            case (0x12) ?#sha2_256;
            case (0x13) ?#sha2_512;
            case (0xb220) ?#blake2b_256;
            case (0xb260) ?#blake2s_256;
            case (0x16) ?#sha3_256;
            case (0x14) ?#sha3_512;

            case (_) null;
        };
    };
};
