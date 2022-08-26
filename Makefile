.PHONY: install
install: release
	@cp .build/release/bazelize /usr/local/bin

.PHONY: release
release:
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
	COCOAPOD=$(shell which pod) swift test -v 2>&1 | xcpretty
#	COCOAPOD=$(shell which pod) swift test -v 2>&1 | xcbeautify


Apple  := bazelbuild/rules_apple
Pod    := pinterest/PodToBUILD
SPM    := cgrindel/rules_spm
Hammer := pinterest/xchammer

REPOS = Apple Pod SPM Hammer

# user/repo rule_name output_file_path
# python3 git_release.py bazelbuild/rules_apple Apple Sources/BazelizeKit/Rule/Rule+Apple.swift
$(REPOS):
	python3 git_release.py $($@) $@ Sources/BazelizeKit/Repo/Repo+$@.swift 5

rules: $(REPOS)
