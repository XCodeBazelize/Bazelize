.PHONY: bazelize
bazelize:
	@bazelize --project Example.xcodeproj

.PHONY: clear
clear:
	@bazelize --project Example.xcodeproj --clear

.PHONY: build
build:
	bazel build Example

.PHONY: updatePkg
updatePkg:
	bazel run //:swift_update_pkgs

.PHONY: run
run: updatePkg
	bazel run --config=Debug Example

.PHONY: releaseRun
releaseRun: updatePkg
	bazel run --config=Release Example

.PHONY: test
test:
	bazel test ExampleTests Framework1Tests Framework2Tests

.PHONY: uitest
uitest:
	bazel test ExampleUITests


# 
# bazel run //:update_build_files
# bazel test //...
# --experimental_enable_bzlmod