.PHONY: install
install: release
	@cp .build/release/bazelize /usr/local/bin

.PHONY: build
release:
	swift build -c release
