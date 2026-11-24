import Foundation
import PathKit
import Testing
@testable import Xcode

struct JSONProjectLoaderTests {
    @Test
    func jsonProjectPreservesConfigurationsAndPackageReferences() throws {
        let root = try fixture()
        defer { try? root.delete() }
        let project = try Xcode.Project.load(path: root + "Project.xcodeproj", preferConfig: "Debug")
        let probeIndex = project.targetIndex(named: "Probe")
        let probe = try #require(probeIndex)

        #expect(project.targets[probe].productType == "com.apple.product-type.application")
        #expect(project.targets[probe].configs["Debug"]?.swiftVersion == "6.0")
        #expect(project.targets[probe].configs["Release"]?.swiftVersion == "5.0")
        #expect(project.targets[probe].prefer(\.platform.iOS) == "16.0")
        #expect(project.packages.remote.map(\.repositoryURL) == ["https://github.com/apple/swift-collections"])
        #expect(project.packages.local.map(\.relativePath) == ["Packages/Local"])
        #expect(project.targets[probe].dependencies.packageProducts.map(\.productName) == ["Collections"])
    }

    @Test
    func jsonMembershipAndInferredFileTypesReachTheConsumerModel() throws {
        let root = try fixture()
        defer { try? root.delete() }
        let project = try Xcode.Project.load(path: root + "Project.xcodeproj", preferConfig: nil)
        let probeFiles = project.withTarget(named: "Probe") { $0.files }
        let probeFrameworks = project.withTarget(named: "Probe") { $0.dependencies.frameworks }
        let files = try #require(probeFiles)
        let frameworks = try #require(probeFrameworks)

        #expect(Set(files.sources.compactMap(\.path)) == [
            "Sources/Main.swift", "Sources/Interop.m", "Synced/Included.swift", "Synced/Legacy.m",
        ])
        #expect(Set(files.resources.compactMap(\.path)) == [
            "Resources/Greeting.txt", "Synced/Localizable.strings",
        ])
        #expect(files.headers.compactMap(\.path) == ["Sources/Public.h"])
        let header = try #require(files.headers.first)
        #expect(header.attributes.contains("Public"))
        #expect(header.fileType == "sourcecode.c.h")
        let interop = try #require(files.sources.first { $0.path == "Sources/Interop.m" })
        #expect(interop.fileType == "sourcecode.cpp.objcpp")
        #expect(frameworks == ["//Prebuilt:Vendor"])
        let legacy = try #require(files.sources.first { $0.path == "Synced/Legacy.m" })
        #expect(legacy.compilerFlags == "-fno-objc-arc")
    }

    @Test
    func sdkFrameworkPathsLinkByFrameworkName() throws {
        let path = "<DEVELOPER>/Platforms/MacOSX.platform/Developer/SDKs/MacOSX.sdk/System/Library/Frameworks/Foundation.framework"
        let root = try fixture()
        defer { try? root.delete() }
        var model = try #require(JSONSerialization.jsonObject(with: Data(projectJSON.utf8)) as? [String: Any])
        var files = try #require(model["files"] as? [[String: Any]])
        files.append(["path": path, "target-membership": ["Probe/frameworks"]])
        model["files"] = files
        try (root + "Project.xcodeproj/project.xcproj").write(
            String(decoding: JSONSerialization.data(withJSONObject: model), as: UTF8.self))

        let project = try Xcode.Project.load(path: root + "Project.xcodeproj", preferConfig: nil)
        let probeSDKFrameworks = project.withTarget(named: "Probe") { $0.dependencies.sdkFrameworks }
        let sdkFrameworks = try #require(probeSDKFrameworks)
        #expect(sdkFrameworks == ["Foundation"])
    }

    private func fixture() throws -> Path {
        let root = Path(NSTemporaryDirectory()) + UUID().uuidString
        try (root + "Project.xcodeproj").mkpath()
        try (root + "Project.xcodeproj/project.xcproj").write(projectJSON)
        for path in [
            "Sources/Main.swift", "Sources/Interop.m", "Sources/Public.h", "Sources/NotAMember.swift",
            "Resources/Greeting.txt", "Synced/Included.swift", "Synced/Excluded.swift", "Synced/Legacy.m",
            "Synced/Localizable.strings", "Vendor.xcframework/Info.plist",
        ] {
            let file = root + path
            try file.parent().mkpath()
            try file.write("")
        }
        return root
    }

    private var projectJSON: String {
        #"""
        {
          "default-configuration": "Release",
          "configurations": ["Debug", "Release"],
          "localizations": { "development": "en", "supported": ["en"] },
          "packages": [
            {
              "kind": "remote",
              "repository": "https://github.com/apple/swift-collections",
              "version": { "up-to-next-major-version": "1.0.0" }
            },
            { "kind": "local", "path": "Packages/Local" }
          ],
          "files": [
            {
              "kind": "group",
              "path": "Sources",
              "children": [
                { "path": "Main.swift", "target-membership": ["Probe/compile-sources"] },
                {
                  "path": "Interop.m", "type": "sourcecode.cpp.objcpp",
                  "target-membership": ["Probe/compile-sources"]
                },
                {
                  "path": "Public.h",
                  "target-membership": [{ "build-phase": "Probe/headers", "header-role": "public" }]
                },
                { "path": "NotAMember.swift" }
              ]
            },
            { "path": "Resources/Greeting.txt", "target-membership": ["Probe/resources"] },
            { "path": "Vendor.xcframework", "target-membership": ["Probe/frameworks"] },
            {
              "kind": "folder",
              "path": "Synced",
              "target-membership": ["Probe"],
              "membership-exceptions": [{
                "target": "Probe",
                "exclusions": ["Excluded.swift"],
                "compiler-flags": { "Legacy.m": "-fno-objc-arc" }
              }]
            },
            {
              "kind": "group", "name": "Products",
              "children": [{
                "path": "<PRODUCTS>/Probe.app", "type": "wrapper.application",
                "id": "000000000000000000000120"
              }]
            }
          ],
          "targets": [{
            "name": "Probe",
            "id": "000000000000000100000000",
            "product": "Products/Probe.app",
            "product-type": "application",
            "build-phases": ["compile-sources", "headers", "frameworks", "resources"],
            "package-product-members": [{
              "package": "swift-collections",
              "product-name": "Collections",
              "build-phase": { "build-phase": "frameworks" }
            }],
            "build-settings": { "SWIFT_VERSION[config=Debug]": "6.0" }
          }],
          "build-settings": {
            "SDKROOT": "iphoneos",
            "IPHONEOS_DEPLOYMENT_TARGET": "16.0",
            "SWIFT_VERSION": "5.0"
          }
        }
        """#
    }
}
