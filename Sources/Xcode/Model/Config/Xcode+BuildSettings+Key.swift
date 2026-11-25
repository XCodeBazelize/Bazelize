extension Xcode.BuildSettings {
    /// The build settings Bazelize reads by name. The raw value is the name
    /// Xcode spells in a project file or an xcconfig.
    ///
    /// A key built at runtime — `INFOPLIST_KEY_*`, or one named by a
    /// `$(SETTING)` reference — goes through the `String` subscript instead.
    public enum Key: String, Sendable {
        // MARK: Project

        case targetName = "TARGET_NAME"
        case projectName = "PROJECT_NAME"
        case srcRoot = "SRCROOT"
        case sourceRoot = "SOURCE_ROOT"
        case projectDir = "PROJECT_DIR"

        // MARK: Metadata

        case productBundleIdentifier = "PRODUCT_BUNDLE_IDENTIFIER"
        case productModuleName = "PRODUCT_MODULE_NAME"
        case productName = "PRODUCT_NAME"
        case developmentTeam = "DEVELOPMENT_TEAM"
        case codeSignStyle = "CODE_SIGN_STYLE"
        case codeSignIdentity = "CODE_SIGN_IDENTITY"
        case codeSignEntitlements = "CODE_SIGN_ENTITLEMENTS"

        // MARK: Asset catalog

        case appIconName = "ASSETCATALOG_COMPILER_APPICON_NAME"
        case globalAccentColorName = "ASSETCATALOG_COMPILER_GLOBAL_ACCENT_COLOR_NAME"
        case generateSwiftAssetSymbolExtensions = "ASSETCATALOG_COMPILER_GENERATE_SWIFT_ASSET_SYMBOL_EXTENSIONS"
        case alternateAppIconNames = "ASSETCATALOG_COMPILER_ALTERNATE_APPICON_NAMES"
        case includeAllAppIconAssets = "ASSETCATALOG_COMPILER_INCLUDE_ALL_APPICON_ASSETS"

        // MARK: String catalog

        case stringCatalogGenerateSymbols = "STRING_CATALOG_GENERATE_SYMBOLS"

        // MARK: Info.plist

        case infoPlistFile = "INFOPLIST_FILE"
        case generateInfoPlistFile = "GENERATE_INFOPLIST_FILE"
        case currentProjectVersion = "CURRENT_PROJECT_VERSION"
        case marketingVersion = "MARKETING_VERSION"

        // MARK: Platform

        case sdkRoot = "SDKROOT"
        case supportedPlatforms = "SUPPORTED_PLATFORMS"
        case iphoneOSDeploymentTarget = "IPHONEOS_DEPLOYMENT_TARGET"
        case macOSXDeploymentTarget = "MACOSX_DEPLOYMENT_TARGET"
        case tvOSDeploymentTarget = "TVOS_DEPLOYMENT_TARGET"
        case watchOSDeploymentTarget = "WATCHOS_DEPLOYMENT_TARGET"
        case driverKitDeploymentTarget = "DRIVERKIT_DEPLOYMENT_TARGET"
        case targetedDeviceFamily = "TARGETED_DEVICE_FAMILY"

        // MARK: Swift

        case swiftVersion = "SWIFT_VERSION"
        case swiftDefaultActorIsolation = "SWIFT_DEFAULT_ACTOR_ISOLATION"
        case swiftActiveCompilationConditions = "SWIFT_ACTIVE_COMPILATION_CONDITIONS"
        case swiftApproachableConcurrency = "SWIFT_APPROACHABLE_CONCURRENCY"
        case swiftEnableBareSlashRegex = "SWIFT_ENABLE_BARE_SLASH_REGEX"
        case swiftStrictConcurrency = "SWIFT_STRICT_CONCURRENCY"
        case swiftStrictMemorySafety = "SWIFT_STRICT_MEMORY_SAFETY"
        case swiftObjCBridgingHeader = "SWIFT_OBJC_BRIDGING_HEADER"
        case otherSwiftFlags = "OTHER_SWIFT_FLAGS"

        // MARK: C family

        case otherCFlags = "OTHER_CFLAGS"
        case otherCPlusPlusFlags = "OTHER_CPLUSPLUSFLAGS"
        case gccPrefixHeader = "GCC_PREFIX_HEADER"
        case gccPreprocessorDefinitions = "GCC_PREPROCESSOR_DEFINITIONS"
        case headerSearchPaths = "HEADER_SEARCH_PATHS"
        case userHeaderSearchPaths = "USER_HEADER_SEARCH_PATHS"
        case clangEnableModules = "CLANG_ENABLE_MODULES"

        // MARK: Linking

        case otherLinkerFlags = "OTHER_LDFLAGS"
        case machOType = "MACH_O_TYPE"
        case bundleLoader = "BUNDLE_LOADER"

        // MARK: Testing

        case testTargetName = "TEST_TARGET_NAME"
        case testHost = "TEST_HOST"
    }

    public subscript(key: Key) -> String? {
        self[key.rawValue]
    }
}
