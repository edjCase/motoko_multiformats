import Nat "mo:new-base/Nat";
import Iter "mo:new-base/Iter";
import Nat8 "mo:new-base/Nat8";
import Nat64 "mo:new-base/Nat64";
import Result "mo:new-base/Result";
import Buffer "mo:base/Buffer";

module {

    /// Decodes a variable-length integer from a byte iterator.
    ///
    /// ```motoko
    /// let bytes : [Nat8] = [0xAC, 0x02]; // 300 encoded as varint
    /// let ?value = VarInt.decode(bytes.vals()); // Returns: 300
    /// ```
    public func decode(bytes : Iter.Iter<Nat8>) : Result.Result<Nat, Text> {
        var result : Nat64 = 0;
        var shift : Nat64 = 0;
        var bytesRead = 0;

        for (byte in bytes) {
            let byte32 = Nat64.fromNat(Nat8.toNat(byte));
            result := result + ((byte32 % 128) << shift);
            bytesRead += 1;

            if (byte32 < 128) {
                return #ok(Nat64.toNat(result));
            };
            shift += 7;
        };
        #err("Unexpected end of bytes"); // Not enough bytes to complete varint
    };

    /// Encodes a natural number as a variable-length integer.
    ///
    /// ```motoko
    /// let encoded = VarInt.encode(300);
    /// // Returns: [0xAC, 0x02]
    /// ```
    public func encode(n : Nat) : [Nat8] {
        let buffer = Buffer.Buffer<Nat8>(5);
        var value = n;

        while (value >= 128) {
            buffer.add(Nat8.fromNat((value % 128) + 128));
            value := value / 128;
        };
        buffer.add(Nat8.fromNat(value));

        Buffer.toArray(buffer);
    };
};
