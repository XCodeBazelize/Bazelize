import Foundation
import PathKit
import Testing
@testable import BazelizeKit

struct BazelizeConfigurationTests {
    @Test
    func usesCompiledDefaultsWhenNoConfigurationExists() throws {
        let root = try scratch()
        defer { try? root.delete() }

        let configuration = try BazelizeConfiguration.load(
            explicitPath: nil,
            inputPath: root + "Package.swift")

        #expect(configuration == .default)
    }

    @Test
    func explicitConfigurationTakesPrecedenceOverAutomaticConfiguration() throws {
        let root = try scratch()
        defer { try? root.delete() }
        try (root + BazelizeConfiguration.fileName).write("""
        schema: 1
        buildifier:
          version: "unsupported"
        """)
        let explicit = root + "custom.yaml"
        try explicit.write("""
        schema: 1
        buildifier:
          version: "8.2.1"
        """)

        let configuration = try BazelizeConfiguration.load(
            explicitPath: explicit,
            inputPath: root)

        #expect(configuration.buildifier.version == "8.2.1")
    }

    @Test
    func automaticConfigurationRejectsDependencyPins() throws {
        let root = try scratch()
        defer { try? root.delete() }
        try (root + BazelizeConfiguration.fileName).write("""
        schema: 1
        buildifier:
          version: "10.1.0"
        bazel:
          dependencies:
            rules_swift: "4.0.1"
        """)

        do {
            _ = try BazelizeConfiguration.load(explicitPath: nil, inputPath: root)
            Issue.record("Expected dependency pins to be rejected.")
        } catch {
            #expect(error.localizedDescription.contains("Unknown property 'bazel'"))
        }
    }

    @Test
    func rejectsUnknownBuildifierProperties() throws {
        let root = try scratch()
        defer { try? root.delete() }
        let path = root + "custom.yaml"
        try path.write("""
        schema: 1
        buildifier:
          version: "10.1.0"
          warnings: all
        """)

        do {
            _ = try BazelizeConfiguration.load(explicitPath: path, inputPath: root)
            Issue.record("Expected an unknown buildifier property to be rejected.")
        } catch {
            #expect(error.localizedDescription.contains("Unknown property 'buildifier.warnings'"))
        }
    }

    @Test
    func rejectsUnsupportedBuildifierVersion() throws {
        let root = try scratch()
        defer { try? root.delete() }
        let path = root + "custom.yaml"
        try path.write("""
        schema: 1
        buildifier:
          version: "9.9.9"
        """)

        do {
            _ = try BazelizeConfiguration.load(explicitPath: path, inputPath: root)
            Issue.record("Expected an unsupported buildifier version to be rejected.")
        } catch {
            #expect(error.localizedDescription.contains("Unsupported buildifier version '9.9.9'"))
        }
    }

    @Test
    func rejectsUnsupportedSchema() throws {
        let root = try scratch()
        defer { try? root.delete() }
        let path = root + "custom.yaml"
        try path.write("""
        schema: 2
        buildifier:
          version: "10.1.0"
        """)

        do {
            _ = try BazelizeConfiguration.load(explicitPath: path, inputPath: root)
            Issue.record("Expected an unsupported schema to be rejected.")
        } catch {
            #expect(error.localizedDescription.contains("Unsupported schema 2; expected 1"))
        }
    }

    @Test
    func missingExplicitConfigurationIsAnError() throws {
        let root = try scratch()
        defer { try? root.delete() }
        let path = root + "missing.yaml"

        do {
            _ = try BazelizeConfiguration.load(explicitPath: path, inputPath: root)
            Issue.record("Expected a missing explicit configuration to be rejected.")
        } catch {
            #expect(error.localizedDescription.contains("Configuration file not found"))
            #expect(error.localizedDescription.contains(path.string))
        }
    }

    @Test
    func createsCanonicalExampleInDestinationDirectory() throws {
        let root = try scratch()
        defer { try? root.delete() }
        let destination = root + "nested/project"

        let path = try BazelizeConfiguration.createExample(in: destination)

        #expect(path == destination + BazelizeConfiguration.fileName)
        #expect(try path.read() == BazelizeConfiguration.example)
        let configuration = try BazelizeConfiguration.load(
            explicitPath: path,
            inputPath: root)
        #expect(configuration == .default)
    }

    @Test
    func creatingExampleDoesNotOverwriteExistingConfiguration() throws {
        let root = try scratch()
        defer { try? root.delete() }
        let existing = root + BazelizeConfiguration.fileName
        try existing.write("keep me\n")

        do {
            _ = try BazelizeConfiguration.createExample(in: root)
            Issue.record("Expected an existing configuration to be preserved.")
        } catch {
            #expect(error.localizedDescription.contains("Configuration file already exists"))
        }
        #expect(try existing.read() == "keep me\n")
    }

    private func scratch() throws -> Path {
        let root = Path(NSTemporaryDirectory()) + "bazelize-config-\(UUID().uuidString)"
        try root.mkpath()
        try (root + "Package.swift").write("// swift-tools-version: 6.0\n")
        return root
    }
}
