import ProductShapes
import Testing

@Test
func groupedProductsExposeEveryTarget() {
    #expect(ProductShapes.combinedValue == 42)
}

@Test
func packageAccessReachesTheTargetsOfThatPackage() {
    #expect(ProductShapes.sharedValue == 42)
}
