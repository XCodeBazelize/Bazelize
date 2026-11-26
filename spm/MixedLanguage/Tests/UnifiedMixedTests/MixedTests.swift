import Testing
import Unified

@Test
func aMixedTestTargetKeepsItsCSource() {
    #expect(unified_test_probe() == 7)
    #expect(unified_test_probe() + unified_c_value() == 48)
}
