import Foundation
import PathKit
import Xcode

// MARK: - OwnedTarget

// This is a field-for-field experimental model, not a replacement for the
// public Xcode.Target. Its native owning container requires macOS 27.
private struct OwnedTarget: ~Copyable {
    let name: String
    let productName: String?
    let productType: String?
    let preferConfig: String?
    let configs: [String: Xcode.BuildSettings]
    let metadata: Xcode.TargetMetadata
    let buildPhases: [Xcode.BuildPhase]
    let files: Xcode.Files
    let dependencies: Xcode.Dependencies

    init(_ source: consuming Xcode.Target) {
        name = source.name
        productName = source.productName
        productType = source.productType
        preferConfig = source.preferConfig
        configs = source.configs
        metadata = source.metadata
        buildPhases = source.buildPhases
        files = source.files
        dependencies = source.dependencies
    }

    borrowing func matches(_ source: borrowing Xcode.Target) throws -> Bool {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys]
        return try name == source.name
            && productName == source.productName
            && productType == source.productType
            && preferConfig == source.preferConfig
            && encoder.encode(configs) == encoder.encode(source.configs)
            && encoder.encode(metadata) == encoder.encode(source.metadata)
            && encoder.encode(buildPhases) == encoder.encode(source.buildPhases)
            && encoder.encode(files) == encoder.encode(source.files)
            && encoder.encode(files.missing) == encoder.encode(source.files.missing)
            && encoder.encode(dependencies) == encoder.encode(source.dependencies)
    }
}

@inline(never)
private func defaultChecksum(_ target: Xcode.Target) -> Int {
    target.name.utf8.count + (target.productName?.utf8.count ?? 0)
        + (target.productType?.utf8.count ?? 0) + (target.preferConfig?.utf8.count ?? 0)
        + target.configs.count + target.metadata.deploymentTargets.count
        + target.buildPhases.count + target.files.sources.count + target.files.headers.count
        + target.files.resources.count + target.files.frameworks.count + target.files.copyFiles.count
        + target.files.others.count + target.files.missing.count + target.dependencies.targets.count
        + target.dependencies.packageProducts.count + target.dependencies.frameworks.count
        + target.dependencies.sdkDylibs.count + target.dependencies.sdkFrameworks.count
        + target.dependencies.sdkFrameworkSearchPaths.count + target.dependencies.weakSDKFrameworks.count
}

@inline(never)
private func borrowedChecksum(_ target: borrowing Xcode.Target) -> Int {
    target.name.utf8.count + (target.productName?.utf8.count ?? 0)
        + (target.productType?.utf8.count ?? 0) + (target.preferConfig?.utf8.count ?? 0)
        + target.configs.count + target.metadata.deploymentTargets.count
        + target.buildPhases.count + target.files.sources.count + target.files.headers.count
        + target.files.resources.count + target.files.frameworks.count + target.files.copyFiles.count
        + target.files.others.count + target.files.missing.count + target.dependencies.targets.count
        + target.dependencies.packageProducts.count + target.dependencies.frameworks.count
        + target.dependencies.sdkDylibs.count + target.dependencies.sdkFrameworks.count
        + target.dependencies.sdkFrameworkSearchPaths.count + target.dependencies.weakSDKFrameworks.count
}

@inline(never)
private func ownedChecksum(_ target: borrowing OwnedTarget) -> Int {
    target.name.utf8.count + (target.productName?.utf8.count ?? 0)
        + (target.productType?.utf8.count ?? 0) + (target.preferConfig?.utf8.count ?? 0)
        + target.configs.count + target.metadata.deploymentTargets.count
        + target.buildPhases.count + target.files.sources.count + target.files.headers.count
        + target.files.resources.count + target.files.frameworks.count + target.files.copyFiles.count
        + target.files.others.count + target.files.missing.count + target.dependencies.targets.count
        + target.dependencies.packageProducts.count + target.dependencies.frameworks.count
        + target.dependencies.sdkDylibs.count + target.dependencies.sdkFrameworks.count
        + target.dependencies.sdkFrameworkSearchPaths.count + target.dependencies.weakSDKFrameworks.count
}

// MARK: - Mode

private enum Mode: String, CaseIterable {
    case arrayDefault = "array-default"
    case arrayBorrowing = "array-borrowing"
    case uniqueCopyable = "unique-copyable"
    case uniqueNoncopyable = "unique-noncopyable"
}

@inline(never)
private func walkArray(_ targets: borrowing [Xcode.Target], iterations: Int, explicitBorrow: Bool) -> Int {
    var checksum = 0
    if explicitBorrow {
        for _ in 0..<iterations {
            for index in targets.indices { checksum &+= borrowedChecksum(targets[index]) }
        }
    } else {
        for _ in 0..<iterations {
            for index in targets.indices { checksum &+= defaultChecksum(targets[index]) }
        }
    }
    return checksum
}

@inline(never)
private func walkCopyable(_ targets: borrowing UniqueArray<Xcode.Target>, iterations: Int) -> Int {
    var checksum = 0
    for _ in 0..<iterations {
        for index in 0..<targets.count { checksum &+= borrowedChecksum(targets[index]) }
    }
    return checksum
}

@inline(never)
private func walkNoncopyable(_ targets: borrowing UniqueArray<OwnedTarget>, iterations: Int) -> Int {
    var checksum = 0
    for _ in 0..<iterations {
        for index in 0..<targets.count { checksum &+= ownedChecksum(targets[index]) }
    }
    return checksum
}

private func seconds(_ duration: Duration) -> Double {
    let parts = duration.components
    return Double(parts.seconds) + Double(parts.attoseconds) / 1e18
}

// MARK: - ExperimentError

private struct ExperimentError: Error, CustomStringConvertible {
    let description: String
}

// MARK: - Benchmark

@main
private enum Benchmark {
    static func main() throws {
        let arguments = CommandLine.arguments
        guard
            arguments.count == 4,
            let iterations = Int(arguments[2]), iterations > 0,
            let samples = Int(arguments[3]), samples >= 4
        else {
            throw ExperimentError(description: "usage: benchmark PROJECT ITERATIONS SAMPLES (SAMPLES >= 4)")
        }
        let start = ContinuousClock.now
        let project = try Xcode.Project.load(path: Path(arguments[1]), preferConfig: nil)
        let loadSeconds = seconds(start.duration(to: .now))
        let targets = project.targets
        guard let first = targets.first else { throw ExperimentError(description: "project has no targets") }
        let fieldNames = Mirror(reflecting: first).children.compactMap(\.label)
        guard
            fieldNames == [
                "name",
                "productName",
                "productType",
                "preferConfig",
                "configs",
                "metadata",
                "buildPhases",
                "files",
                "dependencies",
            ],
            MemoryLayout<Xcode.Target>.size == MemoryLayout<OwnedTarget>.size
        else { throw ExperimentError(description: "the real target layout changed; update the experimental model") }

        let setup = ContinuousClock.now
        var copyable = UniqueArray<Xcode.Target>()
        var owned = UniqueArray<OwnedTarget>()
        for target in targets {
            copyable.append(target)
            owned.append(OwnedTarget(target))
        }
        for index in targets.indices {
            guard try owned[index].matches(targets[index]) else {
                throw ExperimentError(description: "noncopyable projection differs at target \(index)")
            }
        }
        let setupSeconds = seconds(setup.duration(to: .now))
        let modes = Mode.allCases
        let expected = targets.reduce(0) { $0 &+ defaultChecksum($1) } &* iterations
        var measurements: [String: [Double]] = [:]
        // One warmup, then rotate first position to avoid always favoring one mode.
        for round in -1..<samples {
            for offset in modes.indices {
                let mode = modes[(offset + max(round, 0)) % modes.count]
                let began = ContinuousClock.now
                let checksum: Int
                switch mode {
                case .arrayDefault:
                    checksum = walkArray(targets, iterations: iterations, explicitBorrow: false)
                case .arrayBorrowing:
                    checksum = walkArray(targets, iterations: iterations, explicitBorrow: true)
                case .uniqueCopyable:
                    checksum = walkCopyable(copyable, iterations: iterations)
                case .uniqueNoncopyable:
                    checksum = walkNoncopyable(owned, iterations: iterations)
                }
                let elapsed = seconds(began.duration(to: .now))
                guard checksum == expected else { throw ExperimentError(description: "checksum differs for \(mode.rawValue)") }
                if round >= 0 { measurements[mode.rawValue, default: []].append(elapsed) }
            }
        }
        let result: [String: Any] = [
            "project": arguments[1], "target_count": targets.count,
            "iterations": iterations, "samples": samples, "checksum": expected,
            "target_size_bytes": MemoryLayout<Xcode.Target>.size,
            "owned_size_bytes": MemoryLayout<OwnedTarget>.size,
            "load_seconds": loadSeconds, "projection_and_validation_seconds": setupSeconds,
            "seconds": measurements,
        ]
        let data = try JSONSerialization.data(withJSONObject: result, options: [.prettyPrinted, .sortedKeys])
        FileHandle.standardOutput.write(data)
        FileHandle.standardOutput.write(Data("\n".utf8))
    }
}
