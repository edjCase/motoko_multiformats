import Result "mo:core/Result";
import Iter "mo:core/Iter";
import Text "mo:core/Text";
import Nat8 "mo:core/Nat8";
import Blob "mo:core/Blob";
import Array "mo:core/Array";
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

  /// Represents the multibase encoding format with its character prefix, including identity.
  ///
  /// ```motoko
  /// let encoding : MultiBaseOrIdentity = #base58btc; // 'z' prefix
  /// let identityEncoding : MultiBaseOrIdentity = #identity; // NUL (0x00) prefix
  /// ```
  public type MultiBaseOrIdentity = MultiBase or {
    #identity; // 0x00 byte only prefix (no encoding)
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

    let bytesResult : Result.Result<[Nat8], Text> = fromTextWithoutPrefix(remainingText, baseEncoding);

    Result.chain(
      bytesResult,
      func(bytes : [Nat8]) : Result.Result<([Nat8], MultiBase), Text> = #ok((bytes, baseEncoding)),
    );
  };

  /// Converts base text representation to bytes using a specific encoding type
  ///
  /// ```motoko
  /// let text = "3mJ"; // Base58 encoded data without prefix
  /// let result = MultiBase.fromTextWithoutPrefix(text, #base58btc);
  /// // Returns: #ok([0x01, 0x02, 0x03])
  /// ```
  public func fromTextWithoutPrefix(text : Text, encoding : MultiBase) : Result.Result<[Nat8], Text> {
    switch (encoding) {
      case (#base58btc) BaseX.fromBase58(text);
      case (#base32) BaseX.fromBase32(text, #standard);
      case (#base32Upper) BaseX.fromBase32(text, #standard);
      case (#base64) BaseX.fromBase64(text);
      case (#base64Url) BaseX.fromBase64(text);
      case (#base64UrlPad) BaseX.fromBase64(text);
      case (#base16) BaseX.fromBase16(text, { prefix = #none });
      case (#base16Upper) BaseX.fromBase16(text, { prefix = #none });
    };
  };

  /// Converts multibase-encoded bytes to their original bytes with encoding type
  ///
  /// This is commonly used for CID byte decoding when there is a prefix before the CID,
  /// such as when used in DAGCBOR where the multibase encoding is stored as bytes rather
  /// than text. The first byte indicates the encoding type, followed by the encoded data.
  ///
  /// ```motoko
  /// let encodedBytes : [Nat8] = [0x5a, 0x33, 0x6d, 0x4a]; // 'z' prefix + base58 data
  /// let result = MultiBase.fromEncodedBytes(encodedBytes.vals());
  /// // Returns: #ok(([0x01, 0x02, 0x03], #base58btc))
  ///
  /// let identityBytes : [Nat8] = [0x00, 0x01, 0x02, 0x03]; // identity prefix + raw data
  /// let result2 = MultiBase.fromEncodedBytes(identityBytes.vals());
  /// // Returns: #ok(([0x01, 0x02, 0x03], #identity))
  /// ```
  public func fromEncodedBytes(bytes : Iter.Iter<Nat8>) : Result.Result<([Nat8], MultiBaseOrIdentity), Text> {
    let iter = bytes;
    let ?firstByte = iter.next() else return #err("Empty multibase bytes");
    let ?baseEncoding = baseFromByte(firstByte) else return #err("Unsupported multibase byte: " # Nat8.toText(firstByte));

    func fromUtf8(iter : Iter.Iter<Nat8>, baseEncoding : MultiBase) : Result.Result<([Nat8], MultiBase), Text> {
      let ?utf8Text = Text.decodeUtf8(Blob.fromArray(Iter.toArray(iter))) else return #err("Invalid UTF-8 encoding");
      let result = fromTextWithoutPrefix(utf8Text, baseEncoding);
      Result.chain(
        result,
        func(bytes : [Nat8]) : Result.Result<([Nat8], MultiBase), Text> = #ok((bytes, baseEncoding)),
      );
    };

    switch (baseEncoding) {
      case (#identity) #ok((Iter.toArray(iter), baseEncoding));
      case (#base58btc) fromUtf8(iter, #base58btc);
      case (#base32) fromUtf8(iter, #base32);
      case (#base32Upper) fromUtf8(iter, #base32Upper);
      case (#base64) fromUtf8(iter, #base64);
      case (#base64Url) fromUtf8(iter, #base64Url);
      case (#base64UrlPad) fromUtf8(iter, #base64UrlPad);
      case (#base16) fromUtf8(iter, #base16);
      case (#base16Upper) fromUtf8(iter, #base16Upper);
    };
  };

  /// Converts bytes to multibase-encoded bytes with encoding type prefix
  ///
  /// This is the complement to fromEncodedBytes, used for encoding data that will be
  /// stored in binary formats like DAGCBOR. The first byte indicates the encoding type,
  /// followed by the encoded data as UTF-8 bytes (except for identity encoding).
  ///
  /// ```motoko
  /// let bytes : [Nat8] = [0x01, 0x02, 0x03];
  /// let encodedBytes = MultiBase.toEncodedBytes(bytes.vals(), #base58btc);
  /// // Returns: [0x5a, 0x33, 0x6d, 0x4a] ('z' prefix + base58 data as UTF-8)
  ///
  /// let identityBytes = MultiBase.toEncodedBytes(bytes.vals(), #identity);
  /// // Returns: [0x00, 0x01, 0x02, 0x03] (identity prefix + raw data)
  /// ```
  public func toEncodedBytes(bytes : Iter.Iter<Nat8>, encoding : MultiBaseOrIdentity) : [Nat8] {
    let prefixByte = baseToByte(encoding);

    switch (encoding) {
      case (#identity) {
        // For identity, just prepend the prefix byte to the raw data
        Array.concat([prefixByte], Iter.toArray(bytes));
      };
      case (_) {
        // For other encodings, encode to text first, then to UTF-8 bytes
        let encodedText = switch (encoding) {
          case (#base58btc) toText(bytes, #base58btc);
          case (#base32) toText(bytes, #base32);
          case (#base32Upper) toText(bytes, #base32Upper);
          case (#base64) toText(bytes, #base64);
          case (#base64Url) toText(bytes, #base64Url);
          case (#base64UrlPad) toText(bytes, #base64UrlPad);
          case (#base16) toText(bytes, #base16);
          case (#base16Upper) toText(bytes, #base16Upper);
          case (#identity) ""; // Should not reach here
        };
        // Remove the first character (the multibase prefix) from the text
        let textWithoutPrefix = Text.trimStart(
          encodedText,
          #char(
            baseToChar(
              switch (encoding) {
                case (#base58btc) #base58btc;
                case (#base32) #base32;
                case (#base32Upper) #base32Upper;
                case (#base64) #base64;
                case (#base64Url) #base64Url;
                case (#base64UrlPad) #base64UrlPad;
                case (#base16) #base16;
                case (#base16Upper) #base16Upper;
                case (#identity) #base58btc; // Should not reach here
              }
            )
          ),
        );
        let encodedBlob = Text.encodeUtf8(textWithoutPrefix);
        Array.concat([prefixByte], Blob.toArray(encodedBlob));
      };
    };
  };

  /// Converts a byte value to its corresponding MultiBase encoding type (including identity)
  ///
  /// ```motoko
  /// let encoding = MultiBase.baseFromByte(0x5a); // 'z' as byte
  /// // Returns: ?#base58btc
  ///
  /// let identity = MultiBase.baseFromByte(0x00); // identity (no encoding)
  /// // Returns: ?#identity
  ///
  /// let invalid = MultiBase.baseFromByte(0xFF); // invalid byte
  /// // Returns: null
  /// ```
  public func baseFromByte(byte : Nat8) : ?MultiBaseOrIdentity {
    switch (byte) {
      case (0x00) ?#identity; // NUL
      case (0x5a) ?#base58btc; // 'z'
      case (0x62) ?#base32; // 'b'
      case (0x42) ?#base32Upper; // 'B'
      case (0x6d) ?#base64; // 'm'
      case (0x75) ?#base64Url; // 'u'
      case (0x55) ?#base64UrlPad; // 'U'
      case (0x66) ?#base16; // 'f'
      case (0x46) ?#base16Upper; // 'F'
      case (_) null;
    };
  };

  /// Converts a MultiBase encoding type (including identity) to its corresponding byte value
  ///
  /// ```motoko
  /// let byte = MultiBase.baseToByte(#base58btc);
  /// // Returns: 0x5a ('z' as byte)
  ///
  /// let identityByte = MultiBase.baseToByte(#identity);
  /// // Returns: 0x00
  /// ```
  public func baseToByte(encoding : MultiBaseOrIdentity) : Nat8 {
    switch (encoding) {
      case (#identity) 0x00; // NUL
      case (#base58btc) 0x5a; // 'z'
      case (#base32) 0x62; // 'b'
      case (#base32Upper) 0x42; // 'B'
      case (#base64) 0x6d; // 'm'
      case (#base64Url) 0x75; // 'u'
      case (#base64UrlPad) 0x55; // 'U'
      case (#base16) 0x66; // 'f'
      case (#base16Upper) 0x46; // 'F'
    };
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
