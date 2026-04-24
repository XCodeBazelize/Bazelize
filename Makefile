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

Apple     := bazelbuild/rules_apple
Swift     := bazelbuild/rules_swift
XCodeProj := buildbuddy-io/rules_xcodeproj
REPOS     := Apple Swift XCodeProj 

SPM	     := cgrindel/rules_swift_package_manager
REPO_SPM := SPM


# user/repo rule_name output_file_path
# python3 git_release.py bazelbuild/rules_apple Apple Sources/BazelizeKit/Rule/Rule+Apple.swift
$(REPOS):
	python3 git_release.py $($@) $@ Sources/BazelizeKit/Repo/Repo+$@.swift 5 normal

$(REPO_SPM):
	python3 git_release.py $($@) $@ Sources/BazelizeKit/Repo/Repo+$@.swift 5 archive

rules: $(REPOS)

spm: $(REPO_SPM)

.PHONY: bazelize
bazelize: install
	cd fixture/iOS && make bazelize
