import PathKit

// MARK: - FileExtension

/// The extensions of the files a compiler reads: sources, headers, and the
/// textual includes between them.
///
/// The raw value is the extension without its dot and is case-sensitive: `.s`
/// is plain assembly while `.S` goes through the preprocessor first.
public enum FileExtension: String, CaseIterable, Sendable {
    case swift

    case c
    case m
    case mm
    case cc
    case cp
    case cpp
    case cxx
    case cPlusPlus = "c++"

    case h
    case hh
    case hpp
    case hxx
    case inc

    case metal

    case assembly = "s"
    case preprocessedAssembly = "S"

    /// The extension of `path`, if it is one of these.
    public init?(path: String) {
        guard let value = Path(path).extension else { return nil }
        self.init(rawValue: value)
    }

    /// The extension of `path` ignoring case, for callers that treat `.H` like
    /// `.h`. `.S` and `.s` are then both plain assembly.
    public init?(caseInsensitivePath path: String) {
        guard let value = Path(path).extension?.lowercased() else { return nil }
        self.init(rawValue: value)
    }

    /// The extension as a path ends with it: `.swift`.
    public var suffix: String {
        ".\(rawValue)"
    }
}
