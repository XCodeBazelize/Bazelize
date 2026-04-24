import RuleBuilder
import Testing
@testable import BazelRules

struct RulesPlistTests {
    @Test
    func testPlistModule() {
        #expect(
            Rules.Plist.plist_fragment.module
                == "@Plist//build-system/ios-utils:plist_fragment.bzl")
    }

    @Test
    func testPlistFragmentTypedCall() {
        let call = Rules.Plist.Call.plist_fragment(
            name: "InfoPlist",
            ext: "plist",
            template: .custom("""
            '''
            <key>CFBundleName</key>
            <string>Demo</string>
            '''
            """),
            visibility: .private)

        #expect(
            call.text
                == """
                plist_fragment(
                    name = "InfoPlist",
                    extension = "plist",
                    template = '''
                    <key>CFBundleName</key>
                    <string>Demo</string>
                    ''',
                    visibility = [
                        "//visibility:private",
                    ],
                )
                """)
    }
}
