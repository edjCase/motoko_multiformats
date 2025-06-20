import Result "mo:new-base/Result";
import Nat "mo:new-base/Nat";
import Iter "mo:new-base/Iter";
import Text "mo:new-base/Text";
import Nat8 "mo:new-base/Nat8";
import Blob "mo:new-base/Blob";
import Buffer "mo:base/Buffer";
import VarInt "./VarInt";

module {

    /// Represents hash algorithms supported in multihash format.
    ///
    /// ```motoko
    /// let hashAlgo : Algorithm = #sha2_256; // Most common
    /// let blakeAlgo : Algorithm = #blake2b_256; // Alternative
    /// ```
    public type Algorithm = {
        #sha2_256; // SHA-256 (32 bytes)
        #sha2_512; // SHA-512 (64 bytes)
        #blake2b_256; // Blake2b-256 (32 bytes)
        #blake2s_256; // Blake2s-256 (32 bytes)
        #sha3_256; // SHA3-256 (32 bytes)
        #sha3_512; // SHA3-512 (64 bytes)
    };

    /// Represents a multihash with algorithm and digest.
    ///
    /// ```motoko
    /// let multihash : MultiHash = {
    ///   algorithm = #sha2_256;
    ///   digest = "\E3\B0\C4\42..."; // 32-byte hash
    /// };
    /// ```
    public type MultiHash = {
        algorithm : Algorithm;
        digest : Blob;
    };

    /// Encodes a multihash to its binary representation.
    ///
    /// ```motoko
    /// let multihash : MultiHash = {
    ///   algorithm = #sha2_256;
    ///   digest = "\E3\B0\C4\42...";
    /// };
    /// let bytes = MultiHash.toBytes(multihash);
    /// // Returns: [0x12, 0x20, 0xE3, 0xB0, ...]
    /// ```
    public func toBytes(multihash : MultiHash) : [Nat8] {
        let buffer = Buffer.Buffer<Nat8>(multihash.digest.size() + 10);
        toBytesBuffer(buffer, multihash);
        Buffer.toArray(buffer);
    };

    /// Encodes a multihash to its binary representation into a buffer.
    ///
    /// ```motoko
    /// let multihash : MultiHash = {
    ///   algorithm = #sha2_256;
    ///   digest = "\E3\B0\C4\42...";
    /// };
    /// let buffer = Buffer.Buffer<Nat8>(multihash.digest.size() + 10);
    /// MultiHash.toBytesBuffer(buffer, multihash);
    /// // buffer now contains: [0x12, 0x20, 0xE3, 0xB0, ...]
    /// ```
    public func toBytesBuffer(buffer : Buffer.Buffer<Nat8>, multihash : MultiHash) {
        // Add algorithm code
        VarInt.toBytesBuffer(buffer, algorithmToCode(multihash.algorithm));

        // Add digest length
        VarInt.toBytesBuffer(buffer, multihash.digest.size());

        // Add digest
        for (byte in multihash.digest.vals()) {
            buffer.add(byte);
        };
    };

    /// Decodes a multihash from bytes.
    ///
    /// ```motoko
    /// let bytes : [Nat8] = [0x12, 0x20, 0xE3, 0xB0, ...];
    /// let result = MultiHash.fromBytes(bytes.vals());
    /// ```
    public func fromBytes(bytes : Iter.Iter<Nat8>) : Result.Result<MultiHash, Text> {
        // Decode algorithm
        let algoCode = switch (VarInt.fromBytes(bytes)) {
            case (#ok(code)) code;
            case (#err(err)) return #err("Failed to decode algorithm code Var Int: " # err);
        };
        let ?algorithm = codeToAlgorithm(algoCode) else return #err("Unknown hash algorithm: " # Nat.toText(algoCode));

        // Decode length
        let length = switch (VarInt.fromBytes(bytes)) {
            case (#ok(length)) length;
            case (#err(err)) return #err("Failed to decode digest length Var Int: " # err);
        };
        let expectedLength = getDigestLength(algorithm);
        if (length != expectedLength) {
            return #err("Invalid digest length: expected " # Nat.toText(expectedLength) # ", got " # Nat.toText(length));
        };

        // Decode digest
        let digestBytes = Iter.toArray(bytes);
        if (digestBytes.size() != expectedLength) {
            return #err("Insufficient digest bytes: expected " # Nat.toText(expectedLength) # ", got " # Nat.toText(digestBytes.size()));
        };

        #ok({
            algorithm = algorithm;
            digest = Blob.fromArray(digestBytes);
        });
    };

    private func getDigestLength(algorithm : Algorithm) : Nat {
        switch (algorithm) {
            case (#sha2_256) 32;
            case (#sha2_512) 64;
            case (#blake2b_256) 32;
            case (#blake2s_256) 32;
            case (#sha3_256) 32;
            case (#sha3_512) 64;
        };
    };

    // Convert algorithm to code
    private func algorithmToCode(algorithm : Algorithm) : Nat {
        switch (algorithm) {
            case (#sha2_256) 0x12;
            case (#sha2_512) 0x13;
            case (#blake2b_256) 0xb220;
            case (#blake2s_256) 0xb260;
            case (#sha3_256) 0x16;
            case (#sha3_512) 0x14;
        };
    };

    // Convert code to algorithm
    private func codeToAlgorithm(code : Nat) : ?Algorithm {
        switch (code) {
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
