VERSION := 0.0.5

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

.PHONY: lint
lint:
	swiftformat --lint . --verbose

.PHONY: format
format:
	swiftformat .

.PHONY: build
build: format
	swift build

.PHONY: test
test:
	swift test -v --skip CocoapodTests 2>&1 | xcpretty
#	COCOAPOD=$(shell which pod) swift test -v 2>&1 | xcbeautify

.PHONY: bazelize
bazelize: install
	cd fixture/iOS && make bazelize

.PHONY: update-repo-enums
update-repo-enums:
	swift package plugin --allow-network-connections all --allow-writing-to-package-directory repo-enum
	
.PHONY: replace
replace: update-repo-enums
	cp Generated/*.swift Sources/BazelizeKit/BazelDep/
