# Generated using Bazelize 0.0.5 - https://github.com/XCodeBazelize/Bazelize

load("@Plist//build-system/ios-utils:plist_fragment.bzl", "plist_fragment")
load("@build_bazel_rules_apple//apple:ios.bzl", "ios_application")
load("@build_bazel_rules_swift//swift:swift_library.bzl", "swift_library")

genrule(
    name = "AssetSymbols",
    srcs = glob([
        "Sources/Example/Assets.xcassets/**",
        "Sources/Example/Preview Content/Preview Assets.xcassets/**",
    ]),
    outs = [
        "GeneratedAssetSymbols.swift",
    ],
    cmd = """set -e
    catalogs=$$(for src in $(SRCS); do echo "$${src%%.xcassets/*}.xcassets"; done | sort -u)
    compile=$$(mktemp -d)
    xcrun actool $$catalogs --compile "$$compile" --platform iphoneos --minimum-deployment-target 16.2 --bundle-identifier com.bazel.Example --output-format human-readable-text --generate-swift-asset-symbol-extensions YES --generate-swift-asset-symbols $@ > /dev/null""",
    visibility = [
        "//visibility:private",
    ],
)
filegroup(
    name = "Assets",
    srcs = glob([
        "Sources/Example/Assets.xcassets/**",
        "Sources/Example/Preview Content/Preview Assets.xcassets/**",
    ], exclude = [
        "Sources/Example/Assets.xcassets/*.appiconset/**",
        "Sources/Example/Preview Content/Preview Assets.xcassets/*.appiconset/**",
    ]),
    visibility = [
        "//visibility:private",
    ],
)
swift_library(
    name = "Example_swift",
    alwayslink = True,
    copts = [
        "-swift-version",
        "5",
        "-enable-bare-slash-regex",
    ],
    module_name = "Example",
    srcs = [
        "Sources/Derived/Sources/TuistAssets+Example.swift",
        "Sources/Derived/Sources/TuistBundle+Example.swift",
        "Sources/Derived/Sources/TuistStrings+Example.swift",
        "Sources/Example/ContentView.swift",
        "Sources/Example/ExampleApp.swift",
        "Sources/Example/Test.swift",
        ":AssetSymbols",
    ],
    deps = [
        "//Prebuilt:SVProgressHUD",
        "//Targets/Framework1:Framework1_library",
        "//Targets/Framework3:Framework3_library",
        "//Targets/Static2:Static2_library",
        "//Targets/StaticFramework1:StaticFramework1_library",
        "//Packages/AnyCodable:AnyCodable",
        "//Packages/Local1:LocalLib1",
        "//Packages/Local1:LocalLib2",
    ],
    data = [
        ":Assets",
    ],
    defines = select({
        "//:Debug": [
            "DEBUG",
            "YDebug",
            "A",
        ],
        "//:Release": [
            "YDebug",
            "A",
        ],
    }),
    linkopts = [
        "-L$$(DT_TOOLCHAIN_DIR)/usr/lib/swift/iphoneos",
    ],
    # swiftc_inputs = None,
    tags = [
        "manual",
    ],
    testonly = False,
    visibility = [
        "//visibility:private",
    ],
)
alias(
    name = "Example_library",
    actual = "Example_swift",
    tags = [
        "manual",
    ],
    visibility = [
        "//visibility:public",
    ],
)
plist_fragment(
    name = "plist_file",
    extension = "plist",
    template = '''
    <key>CFBundleDevelopmentRegion</key>
    <string>$(DEVELOPMENT_LANGUAGE)</string>
    <key>CFBundleExecutable</key>
    <string>$(EXECUTABLE_NAME)</string>
    <key>CFBundleIdentifier</key>
    <string>$(PRODUCT_BUNDLE_IDENTIFIER)</string>
    <key>CFBundleInfoDictionaryVersion</key>
    <string>6.0</string>
    <key>CFBundleName</key>
    <string>$(PRODUCT_NAME)</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>CFBundleShortVersionString</key>
    <string>1.0</string>
    <key>CFBundleVersion</key>
    <string>1</string>
    <key>LSRequiresIPhoneOS</key>
    <true/>
    <key>UIApplicationSceneManifest</key>
    <dict>
    <key>UIApplicationSupportsMultipleScenes</key>
    <false/>
    <key>UISceneConfigurations</key>
    <dict/>
    </dict>
    <key>UIRequiredDeviceCapabilities</key>
    <array>
    <string>armv7</string>
    </array>
    <key>UISupportedInterfaceOrientations</key>
    <array>
    <string>UIInterfaceOrientationPortrait</string>
    <string>UIInterfaceOrientationLandscapeLeft</string>
    <string>UIInterfaceOrientationLandscapeRight</string>
    </array>
    <key>UISupportedInterfaceOrientations~ipad</key>
    <array>
    <string>UIInterfaceOrientationPortrait</string>
    <string>UIInterfaceOrientationPortraitUpsideDown</string>
    <string>UIInterfaceOrientationLandscapeLeft</string>
    <string>UIInterfaceOrientationLandscapeRight</string>
    </array>
    ''',
    visibility = [
        "//visibility:private",
    ],
)
filegroup(
    name = "Strings",
    srcs = [
        "Sources/Example/en.lproj/Localizable.strings",
        "Sources/Example/zh-Hant.lproj/Localizable.strings",
    ],
    visibility = [
        "//visibility:private",
    ],
)
ios_application(
    name = "Example",
    app_icons = glob([
        "Sources/Example/Assets.xcassets/AppIcon.appiconset/**",
    ]),
    bundle_id = "com.bazel.Example",
    deps = [
        ":Example_library",
        "//Prebuilt:SVProgressHUD",
        "//Targets/Framework1:Framework1",
        "//Targets/Framework3:Framework3",
        "//Targets/Static2:Static2",
        "//Targets/StaticFramework1:StaticFramework1",
    ],
    # extensions = None,
    frameworks = [
        "//Targets/Framework1:Framework1",
        "//Targets/Framework2:Framework2",
        "//Targets/Framework3:Framework3",
    ],
    families = [
        "iphone",
        "ipad",
    ],
    infoplists = [
        ":plist_file",
    ],
    minimum_os_version = "16.2",
    resources = [
        ":Assets",
    ],
    # sdk_frameworks = None,
    strings = [
        ":Strings",
    ],
    visibility = [
        "//visibility:public",
    ],
)