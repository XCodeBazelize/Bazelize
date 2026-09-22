import Consumer
import Testing

@Test
func everyDependencyShapeResolves() {
    #expect(Consumer.everything == ["local target", "helper target", "vendor-kit", "other package"])
}

@Test
func aProductNameBelongsToThePackageThatShipsIt() {
    #expect(Consumer.sameNamedProducts == ["vendor-kit", "alt"])
}
