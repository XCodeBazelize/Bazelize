import Foundation
import PathKit
import Testing
@testable import BazelizeKit

struct PerFileCompilerFlagsTests {
    @Test
    func unsupportedSwiftFlagsNameTheirFileAndStillGenerateWorkspace() async throws {
        let root = Path(NSTemporaryDirectory()) + UUID().uuidString
        defer { try? root.delete() }
        try (root + "Probe.xcodeproj").mkpath()
        try (root + "Sources").mkpath()
        try (root + "Sources/main.swift").write("print(42)")
        let json: [String: Any] = [
            "default-configuration": "Debug", "configurations": ["Debug"],
            "localizations": ["development": "en", "supported": ["en"]],
            "packages": [],
            "files": [
                ["kind": "folder", "path": "Sources", "target-membership": ["Probe"],
                 "membership-exceptions": [["target": "Probe", "compiler-flags": [
                    "main.swift": "-DUNSUPPORTED_PER_FILE -warnings-as-errors",
                 ]]]],
                ["kind": "group", "name": "Products", "children": [
                    ["path": "<PRODUCTS>/Probe.app", "type": "wrapper.application", "id": "000000000000000000000120"],
                ]],
            ],
            "targets": [["name": "Probe", "id": "000000000000000100000000", "product": "Products/Probe.app", "product-type": "application", "build-phases": ["compile-sources"]]],
            "build-settings": ["SDKROOT": "macosx", "MACOSX_DEPLOYMENT_TARGET": "13.0"],
        ]
        try (root + "Probe.xcodeproj/project.xcproj").write(JSONSerialization.data(withJSONObject: json))
        let output = root + "App"
        let kit = try await Kit(root + "Probe.xcodeproj", "Debug", outputPath: output)
        kit.runsBuildToolPlugins = false
        try await kit.run()
        for flag in ["-DUNSUPPORTED_PER_FILE", "-warnings-as-errors"] {
            #expect(kit.projectTips.contains { $0.contains("Sources/main.swift") && $0.contains(flag) })
        }
        #expect((output + "Targets/Probe/BUILD").isFile)
    }
}
