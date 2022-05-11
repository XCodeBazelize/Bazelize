.PHONY: install
install: release
	@cp .build/release/bazelize /usr/local/bin

.PHONY: release
release:
	swift build -c release

.PHONY: build
build:
	swift build -v

.PHONY: test
test:
	COCOAPOD=$(shell which pod) swift test -v 2>&1 | xcpretty

	