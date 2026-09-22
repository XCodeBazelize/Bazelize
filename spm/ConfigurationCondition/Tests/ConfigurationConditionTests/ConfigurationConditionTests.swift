import ConfigurationCondition
import Testing

@Test
func onlyTheCurrentBuildConfigurationsSettingApplies() {
    #if DEBUG_ONLY
    #expect(ConfigurationCondition.name == "debug")
    #elseif RELEASE_ONLY
    #expect(ConfigurationCondition.name == "release")
    #else
    #error("one build configuration must be selected")
    #endif
}
