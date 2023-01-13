.PHONY: bazelize
bazelize:
	@bazelize --project Example.xcodeproj

.PHONY: clear
clear:
	@bazelize --project Example.xcodeproj --clear

.PHONY: build
build:
	bazel build Example

.PHONY: run
run:
	bazel run --config=Debug Example

.PHONY: releaseRun
releaseRun:
	bazel run --config=Release Example

.PHONY: test
test:
	bazel test ExampleTests Framework1Tests Framework2Tests

.PHONY: uitest
uitest:
	bazel test ExampleUITests
