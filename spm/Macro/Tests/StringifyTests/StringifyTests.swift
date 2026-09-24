import Stringify
import Testing

@Test
func macroExpands() {
    #expect(Stringify.onePlusOne.0 == 2)
    #expect(Stringify.onePlusOne.1 == "1 + 1")
}

@Test
func aMacroOfAnotherPackageExpands() {
    #expect(Stringify.shouted == "ACROSS")
    #expect(Stringify.shoutedThere == "HERE")
}
