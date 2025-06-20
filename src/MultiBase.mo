import Result "mo:new-base/Result";
import Iter "mo:new-base/Iter";
import Text "mo:new-base/Text";
import Nat8 "mo:new-base/Nat8";
import BaseX "mo:base-x-encoder";
import Buffer "mo:base/Buffer";

module {

    /// Represents the multibase encoding format with its character prefix.
    ///
    /// ```motoko
    /// let encoding : MultiBase = #base58btc; // 'z' prefix
    /// let base32Encoding : MultiBase = #base32; // 'b' prefix
    /// ```
    public type MultiBase = {
        #base58btc; // 'z' prefix
        #base32; // 'b' prefix
        #base32Upper; // 'B' prefix
        #base64; // 'm' prefix
        #base64Url; // 'u' prefix
        #base64UrlPad; // 'U' prefix
        #base16; // 'f' prefix
        #base16Upper; // 'F' prefix
    };

    /// Converts bytes to its base text prefix representation
    ///
    /// ```motoko
    /// let bytes : [Nat8] = [0x01, 0x02, 0x03];
    /// let text = MultiBase.fromBytes(bytes.vals(), #base58btc);
    /// // Returns: "z3mJ" (example base58btc encoding)
    /// ```
    public func fromBytes(bytes : Iter.Iter<Nat8>, encoding : MultiBase) : Text {
        let baseXText = switch (encoding) {
            case (#base58btc) BaseX.toBase58(bytes);
            case (#base32) BaseX.toBase32(bytes, #standard({ isUpper = false; includePadding = false }));
            case (#base32Upper) BaseX.toBase32(bytes, #standard({ isUpper = true; includePadding = false }));
            case (#base64) BaseX.toBase64(bytes, #standard({ includePadding = false }));
            case (#base64Url) BaseX.toBase64(bytes, #url({ includePadding = false }));
            case (#base64UrlPad) BaseX.toBase64(bytes, #url({ includePadding = true }));
            case (#base16) BaseX.toBase16(bytes, { isUpper = false; prefix = #none });
            case (#base16Upper) BaseX.toBase16(bytes, { isUpper = true; prefix = #none });
        };
        let prefix = getPrefix(encoding);
        prefix # baseXText;
    };

    /// Converts base text representation to bytes with its encoding type
    ///
    /// ```motoko
    /// let text : Text = "z3mJ"; // Example base58btc encoding
    /// let result = MultiBase.toBytes(text);
    /// // Returns: #ok(([0x01, 0x02, 0x03], #base58btc))
    /// ```
    public func toBytes(text : Text) : Result.Result<([Nat8], MultiBase), Text> {
        let iter = text.chars();
        let ?firstChar = iter.next() else return #err("Empty multibase string");
        let remainingText = Text.fromIter(iter);

        let (bytesResult, encoding) : (Result.Result<[Nat8], Text>, MultiBase) = switch (firstChar) {
            case ('z') (BaseX.fromBase58(remainingText), #base58btc);
            case ('b') (BaseX.fromBase32(remainingText, #standard), #base32);
            case ('B') (BaseX.fromBase32(remainingText, #standard), #base32Upper);
            case ('m') (BaseX.fromBase64(remainingText), #base64);
            case ('u') (BaseX.fromBase64(remainingText), #base64Url);
            case ('U') (BaseX.fromBase64(remainingText), #base64UrlPad);
            case ('f') (BaseX.fromBase16(remainingText, { prefix = #none }), #base16);
            case ('F') (BaseX.fromBase16(remainingText, { prefix = #none }), #base16Upper);
            case (_) return #err("Unsupported multibase prefix: " # Text.fromChar(firstChar));
        };

        Result.chain(
            bytesResult,
            func(bytes : [Nat8]) : Result.Result<([Nat8], MultiBase), Text> = #ok((bytes, encoding)),
        );
    };

    /// Converts base text representation to bytes and adds it to a buffer
    ///
    /// ```motoko
    /// let buffer = Buffer.Buffer<Nat8>(100);
    /// let text : Text = "z3mJ"; // Example base58btc encoding
    /// let result = MultiBase.toBytesBuffer(buffer, text);
    /// // buffer now contains the decoded bytes
    /// ```
    public func toBytesBuffer(buffer : Buffer.Buffer<Nat8>, text : Text) : Result.Result<MultiBase, Text> {
        // TODO optimize by having BaseX use buffers
        Result.chain(
            toBytes(text),
            func(result : ([Nat8], MultiBase)) : Result.Result<MultiBase, Text> {
                let (bytes, base) = result;
                for (byte in bytes.vals()) {
                    buffer.add(byte);
                };
                #ok(base);
            },
        );
    };

    private func getPrefix(encoding : MultiBase) : Text {
        switch (encoding) {
            case (#base58btc) "z";
            case (#base32) "b";
            case (#base32Upper) "B";
            case (#base64) "m";
            case (#base64Url) "u";
            case (#base64UrlPad) "U";
            case (#base16) "f";
            case (#base16Upper) "F";
        };
    };
};
