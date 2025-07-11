import Result "mo:new-base/Result";
import Iter "mo:new-base/Iter";
import Text "mo:new-base/Text";
import Nat8 "mo:new-base/Nat8";
import BaseX "mo:base-x-encoder";

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
    /// let text = MultiBase.toText(bytes.vals(), #base58btc);
    /// // Returns: "z3mJ" (example base58btc encoding)
    /// ```
    public func toText(bytes : Iter.Iter<Nat8>, encoding : MultiBase) : Text {
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
        let prefix = Text.fromChar(baseToChar(encoding));
        prefix # baseXText;
    };

    /// Converts base text representation to bytes with its encoding type
    ///
    /// ```motoko
    /// let text : Text = "z3mJ"; // Example base58btc encoding
    /// let result = MultiBase.fromText(text);
    /// // Returns: #ok(([0x01, 0x02, 0x03], #base58btc))
    /// ```
    public func fromText(text : Text) : Result.Result<([Nat8], MultiBase), Text> {
        let iter = text.chars();
        let ?firstChar = iter.next() else return #err("Empty multibase string");
        let ?baseEncoding = baseFromChar(firstChar) else return #err("Unsupported multibase prefix: " # Text.fromChar(firstChar));
        //
        let remainingText = Text.fromIter(iter);

        let bytesResult : Result.Result<[Nat8], Text> = switch (baseEncoding) {
            case (#base58btc) BaseX.fromBase58(remainingText);
            case (#base32) BaseX.fromBase32(remainingText, #standard);
            case (#base32Upper) BaseX.fromBase32(remainingText, #standard);
            case (#base64) BaseX.fromBase64(remainingText);
            case (#base64Url) BaseX.fromBase64(remainingText);
            case (#base64UrlPad) BaseX.fromBase64(remainingText);
            case (#base16) BaseX.fromBase16(remainingText, { prefix = #none });
            case (#base16Upper) BaseX.fromBase16(remainingText, { prefix = #none });
        };

        Result.chain(
            bytesResult,
            func(bytes : [Nat8]) : Result.Result<([Nat8], MultiBase), Text> = #ok((bytes, baseEncoding)),
        );
    };

    /// Converts a character prefix to its corresponding MultiBase encoding type
    ///
    /// ```motoko
    /// let encoding = MultiBase.baseFromChar('z');
    /// // Returns: ?#base58btc
    ///
    /// let invalid = MultiBase.baseFromChar('x');
    /// // Returns: null
    /// ```
    public func baseFromChar(char : Char) : ?MultiBase {
        switch (char) {
            case ('z') ?#base58btc;
            case ('b') ?#base32;
            case ('B') ?#base32Upper;
            case ('m') ?#base64;
            case ('u') ?#base64Url;
            case ('U') ?#base64UrlPad;
            case ('f') ?#base16;
            case ('F') ?#base16Upper;
            case (_) null;
        };
    };

    /// Converts a MultiBase encoding type to its corresponding character prefix
    ///
    /// ```motoko
    /// let char = MultiBase.baseToChar(#base58btc);
    /// // Returns: 'z'
    ///
    /// let base32Char = MultiBase.baseToChar(#base32);
    /// // Returns: 'b'
    /// ```
    public func baseToChar(encoding : MultiBase) : Char {
        switch (encoding) {
            case (#base58btc) 'z';
            case (#base32) 'b';
            case (#base32Upper) 'B';
            case (#base64) 'm';
            case (#base64Url) 'u';
            case (#base64UrlPad) 'U';
            case (#base16) 'f';
            case (#base16Upper) 'F';
        };
    };
};
