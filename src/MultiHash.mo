import Result "mo:core/Result";
import Nat "mo:core/Nat";
import Iter "mo:core/Iter";
import Text "mo:core/Text";
import Nat8 "mo:core/Nat8";
import Blob "mo:core/Blob";
import List "mo:core/List";
import Buffer "mo:buffer";
import LEB128 "mo:leb128";

module {

  /// Represents hash algorithms supported in multihash format.
  ///
  /// ```motoko
  /// let hashAlgo : Algorithm = #sha2256; // Most common
  /// let blakeAlgo : Algorithm = #blake2b256; // Alternative
  /// ```
  public type Algorithm = {
    #none; // Identity (no hashing)
    #sha2256; // SHA-256 (32 bytes)
    #sha2512; // SHA-512 (64 bytes)
    #blake2b256; // Blake2b-256 (32 bytes)
    #blake2s256; // Blake2s-256 (32 bytes)
    #sha3256; // SHA3-256 (32 bytes)
    #sha3512; // SHA3-512 (64 bytes)
  };

  /// Represents a multihash with algorithm and digest.
  ///
  /// ```motoko
  /// let multihash : MultiHash = {
  ///   algorithm = #sha2256;
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
  ///   algorithm = #sha2256;
  ///   digest = "\E3\B0\C4\42...";
  /// };
  /// let bytes = MultiHash.toBytes(multihash);
  /// // Returns: [0x12, 0x20, 0xE3, 0xB0, ...]
  /// ```
  public func toBytes(multihash : MultiHash) : [Nat8] {
    let buffer = List.empty<Nat8>();
    toBytesBuffer(Buffer.fromList(buffer), multihash);
    List.toArray(buffer);
  };

  /// Encodes a multihash to its binary representation into a buffer.
  ///
  /// ```motoko
  /// let multihash : MultiHash = {
  ///   algorithm = #sha2256;
  ///   digest = "\E3\B0\C4\42...";
  /// };
  /// let buffer = Buffer.Buffer<Nat8>(multihash.digest.size() + 10);
  /// MultiHash.toBytesBuffer(buffer, multihash);
  /// // buffer now contains: [0x12, 0x20, 0xE3, 0xB0, ...]
  /// ```
  public func toBytesBuffer(buffer : Buffer.Buffer<Nat8>, multihash : MultiHash) {
    // Add algorithm code
    LEB128.toUnsignedBytesBuffer(buffer, algorithmToCode(multihash.algorithm));

    // Add digest length
    LEB128.toUnsignedBytesBuffer(buffer, multihash.digest.size());

    // Add digest
    for (byte in multihash.digest.vals()) {
      buffer.write(byte);
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
    let algoCode = switch (LEB128.fromUnsignedBytes(bytes)) {
      case (#ok(code)) code;
      case (#err(err)) return #err("Failed to decode algorithm code Var Int: " # err);
    };
    let ?algorithm = codeToAlgorithm(algoCode) else return #err("Unknown hash algorithm: " # Nat.toText(algoCode));

    // Decode length
    let length = switch (LEB128.fromUnsignedBytes(bytes)) {
      case (#ok(length)) length;
      case (#err(err)) return #err("Failed to decode digest length Var Int: " # err);
    };
    let digestBytes = switch (getDigestLength(algorithm)) {
      case (?expectedLength) {
        if (length != expectedLength) {
          return #err("Invalid digest length: expected " # Nat.toText(expectedLength) # ", got " # Nat.toText(length));
        };

        // Decode digest
        let digestBytes = Iter.toArray(Iter.take(bytes, expectedLength));
        if (digestBytes.size() != expectedLength) {
          return #err("Insufficient digest bytes: expected " # Nat.toText(expectedLength) # ", got " # Nat.toText(digestBytes.size()));
        };
        digestBytes;
      };
      case (null) Iter.toArray(bytes); // Identity, no length check needed
    };

    #ok({
      algorithm = algorithm;
      digest = Blob.fromArray(digestBytes);
    });
  };

  private func getDigestLength(algorithm : Algorithm) : ?Nat {
    switch (algorithm) {
      case (#none) null; // Identity
      case (#sha2256) ?32;
      case (#sha2512) ?64;
      case (#blake2b256) ?32;
      case (#blake2s256) ?32;
      case (#sha3256) ?32;
      case (#sha3512) ?64;
    };
  };

  // Convert algorithm to code
  private func algorithmToCode(algorithm : Algorithm) : Nat {
    switch (algorithm) {
      case (#none) 0x00; // Identity
      case (#sha2256) 0x12;
      case (#sha2512) 0x13;
      case (#blake2b256) 0xb220;
      case (#blake2s256) 0xb260;
      case (#sha3256) 0x16;
      case (#sha3512) 0x14;
    };
  };

  // Convert code to algorithm
  private func codeToAlgorithm(code : Nat) : ?Algorithm {
    switch (code) {
      case (0x00) ?#none; // Identity
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
