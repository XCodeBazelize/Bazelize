import Platform
import Testing

@Test
func theDeclaredDeploymentTargetIsWhatTheTargetIsBuiltFor() {
    #expect(Platform.deploymentTargetIsDeclared)
}
