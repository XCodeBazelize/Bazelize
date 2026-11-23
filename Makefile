VERSION := 0.1.0

.PHONY: install
install: release
	@sudo cp .build/release/bazelize /usr/local/bin

.PHONY: syncVersion
syncVersion: 
	@sed -i '' 's|\(version = "\)\(.*\)\("\)|\1$(VERSION)\3|' Sources/BazelizeKit/Bazel/Version.swift

.PHONY: release
release: syncVersion
	swift build -c release

.PHONY: coherent
coherent:
	coherent-swift report

.PHONY: format
format:
	python3 scripts/format-swift.py

.PHONY: build
build:
	swift build

.PHONY: test
test:
	swift test

.PHONY: install-hooks
install-hooks:
	git config --local core.hooksPath .githooks

.PHONY: bazelize
bazelize: install
	cd fixture/iOS && make bazelize

.PHONY: update-repo-enums
update-repo-enums:
	swift package plugin --allow-network-connections all --allow-writing-to-package-directory repo-enum
	
.PHONY: replace
replace: update-repo-enums
	cp Generated/*.swift Sources/BazelizeKit/BazelDep/
