// MARK: - Starlark.Format + String

extension Starlark.Format {
    private static let namedEscapes: [UInt8: String] = [
        0x07: "\\a",
        0x08: "\\b",
        0x0C: "\\f",
        0x0A: "\\n",
        0x0D: "\\r",
        0x09: "\\t",
        0x0B: "\\v",
    ]

    /// The body of a string literal, escaped the way buildifier escapes one:
    /// backslash and quote, the named control characters, and every other
    /// control or high byte as octal, because a BUILD file is read as Latin-1.
    ///
    /// A triple-quoted string keeps its newlines, and passes a quote through
    /// whenever the two bytes after it cannot close the literal. That is what
    /// buildifier does, and what it would rewrite a file to.
    public static func escaped(_ value: String, triple: Bool = false) -> String {
        let bytes = Array(value.utf8)
        var result = ""
        result.reserveCapacity(bytes.count)

        var index = 0
        while index < bytes.count {
            let byte = bytes[index]
            defer { index += 1 }

            if triple, byte == quote, quoteDoesNotClose(bytes, at: index) {
                result.unicodeScalars.append(Unicode.Scalar(byte))
                if index + 1 < bytes.count, bytes[index + 1] == quote {
                    result.unicodeScalars.append(Unicode.Scalar(byte))
                    index += 1
                }
                continue
            }

            if triple, byte == UInt8(ascii: "\n") {
                result += "\n"
            } else if byte == UInt8(ascii: "\\") {
                result += "\\\\"
            } else if byte == quote {
                result += "\\\""
            } else if let escaped = namedEscapes[byte] {
                result += escaped
            } else if byte < 0x20 || byte >= 0x80 {
                let octal = String(byte, radix: 8)
                result += "\\" + String(repeating: "0", count: 3 - octal.count) + octal
            } else {
                result.unicodeScalars.append(Unicode.Scalar(byte))
            }
        }
        return result
    }

    private static let quote = UInt8(ascii: "\"")

    private static func quoteDoesNotClose(_ bytes: [UInt8], at index: Int) -> Bool {
        (index + 1 < bytes.count && bytes[index + 1] != quote)
            || (index + 2 < bytes.count && bytes[index + 2] != quote)
    }
}
