import PathKit
import Testing

// MARK: - Corpus

/// The application projects under `app/`.
///
/// They are other people's repositories, cloned beside this one and ignored by
/// it, so a checkout has them only when someone put them there. A test that
/// reads one says so with `.corpus(…)`: without the project it is reported as
/// skipped, by name and with the reason, instead of failing on a missing file
/// or passing without having looked at anything.
enum Corpus {
    static func project(_ path: String) -> Path {
        Path(#filePath).parent().parent().parent() + "app" + path
    }
}

extension Trait where Self == ConditionTrait {
    static func corpus(_ project: String) -> Self {
        .enabled(
            if: Corpus.project(project).exists,
            "app/\(project) is not in this checkout: the corpus is cloned separately")
    }
}
