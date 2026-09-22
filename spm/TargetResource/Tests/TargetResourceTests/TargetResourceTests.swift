import Foundation
import TargetResource
import Testing

@Test
func aCopiedResourceKeepsItsDirectory() {
    #expect(TargetResource.copied == "copied")
}

@Test
func aCopiedFileKeepsItsName() {
    #expect(TargetResource.copiedFile == "single file")
}

@Test
func aTestTargetReachesItsOwnBundle() {
    let url = Bundle.module.url(forResource: "sample", withExtension: "txt")
    let contents = url.flatMap { try? String(contentsOf: $0, encoding: .utf8) }

    #expect(contents?.trimmingCharacters(in: .whitespacesAndNewlines) == "test fixture")
}

@Test
func aProcessedResourceIsInTheBundle() {
    #expect(TargetResource.processed == "processed")
}

@Test
func anEmbeddedResourceIsInTheBinary() {
    #expect(TargetResource.embedded == "embedded")
}

@Test
func localizedResourcesAreFiledUnderTheirLocalization() {
    #expect(TargetResource.explicitLocalization == #""explicit" = "explicit localization";"#)
    #expect(TargetResource.lprojLocalization == "from lproj")
}

@Test
func everyLocalizationIsItsOwn() {
    /// Not one answering for both: each `.lproj` is in the bundle, and each
    /// says what it says.
    #expect(TargetResource.lprojLocalization("en") == "from lproj")
    #expect(TargetResource.lprojLocalization("ja") == "lproj から")
}

@Test
func platformResourcesReachTheBundle() {
    let bundled = TargetResource.bundled

    func has(_ names: String...) -> Bool {
        names.contains { name in bundled.contains { $0 == name || $0.hasSuffix("/\(name)") } }
    }

    #expect(has("Assets.car", "Assets.xcassets"))
    #expect(has("Panel.nib", "Panel.xib"))
    #expect(has("Main.storyboardc", "Main.storyboard"))
    #expect(has("Model.momd", "Model.xcdatamodeld"))
    #expect(has("default.metallib", "Shader.metal"))
    #expect(has("Catalog.xcstrings", "Catalog.strings"))
}

@Test
func documentationAndPrivacyAreNotResources() {
    let bundled = TargetResource.bundled

    #expect(!bundled.contains { $0.hasSuffix(".docc") || $0.hasSuffix(".md") })
    #expect(!bundled.contains { $0.hasSuffix(".xcprivacy") })
}
