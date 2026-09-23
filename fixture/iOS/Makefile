BAZELIZE = ../../.build/debug/bazelize
OUTPUT = App

# The simulator rules_apple runs unit tests on; override for other Xcode versions.
SIMULATOR_FLAGS = \
	--@build_bazel_rules_apple//apple/build_settings:ios_simulator_device="iPhone 17" \
	--@build_bazel_rules_apple//apple/build_settings:ios_simulator_version=27.0

TESTS = \
	//Targets/ExampleTests \
	//Targets/Framework1Tests \
	//Targets/Framework2Tests \
	//Targets/Framework3Tests

.PHONY: bazelize
bazelize:
	@$(BAZELIZE) --input Example.xcodeproj --output $(OUTPUT)

.PHONY: build
build: bazelize
	cd $(OUTPUT) && bazel build //Targets/Example

.PHONY: run
run: bazelize
	cd $(OUTPUT) && bazel run --config=Debug //Targets/Example

.PHONY: releaseRun
releaseRun: bazelize
	cd $(OUTPUT) && bazel run --config=Release //Targets/Example

.PHONY: test
test:
	cd $(OUTPUT) && bazel test $(SIMULATOR_FLAGS) $(TESTS)

.PHONY: uitest
uitest:
	cd $(OUTPUT) && bazel test $(SIMULATOR_FLAGS) //Targets/ExampleUITests

.PHONY: clear
clear:
	-rm -rf $(OUTPUT)
