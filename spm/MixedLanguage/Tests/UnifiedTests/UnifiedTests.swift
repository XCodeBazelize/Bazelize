import MixedConsumer
import ObjCConsumer
import Testing
import Unified

@Test
func bothLanguagesAreOneModule() {
    #expect(SwiftAPI.value == 42)
    #expect(unified_c_value() == 41)
    #expect(SwiftAPI.cValue == 41)
}

@Test
func perLanguageSettingsReachTheirCompiles() {
    #expect(unified_c_flag() == 1)
    #expect(unified_c_is_c11() == 1)
    #expect(SwiftAPI.cHeaderFlag)
    #expect(SwiftAPI.swiftFlag)
}

@Test
func objectiveCCallsBackIntoSwift() {
    #expect(unified_round_trip(5) == 93)
    #expect(SwiftAPI.roundTrip(5) == 93)
    #expect(SwiftAPI.roundTrip(0) == 83)
}

@Test
func dependentsReachBothInterfaces() {
    #expect(objc_consumer_total(1) == 85)
    #expect(MixedConsumerAPI.total == 83)
    #expect(MixedConsumerAPI.objc(1) == 129)
}
