.PHONY: bazelize
bazelize:
	@bazelize --project Example.xcodeproj
	@bazel mod tidy

.PHONY: clear
clear:
	@bazelize --project Example.xcodeproj --clear
	-rm Package.swift
	-rm Package.resolved 
	-rm MODULE.bazel 
	-rm MODULE.bazel.lock

.PHONY: build
build:
	bazel build Example

.PHONY: updatePkg
updatePkg:
	@bazel mod tidy

.PHONY: run
run:
	bazel run --config=Debug Example

.PHONY: releaseRun
releaseRun:
	bazel run --config=Release Example

.PHONY: test
test:
	bazel test \
		--sandbox_debug \
		ExampleTests \
		Framework1Tests \
		Framework2Tests \
		Framework3Tests


.PHONY: uitest
uitest:
	bazel test ExampleUITests


# 
# bazel run //:update_build_files
# bazel test //...
# --experimental_enable_bzlmod