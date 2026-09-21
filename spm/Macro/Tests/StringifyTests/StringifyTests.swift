import Stringify
import Testing

@Test
func macroExpands() {
    #expect(Stringify.onePlusOne.0 == 2)
    #expect(Stringify.onePlusOne.1 == "1 + 1")
}
