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


Apple := bazelbuild/rules_apple
Pod   := pinterest/PodToBUILD
SPM   := cgrindel/rules_spm

REPOS = Apple Pod SPM

# user/repo rule_name output_file_path
# python3 git_release.py bazelbuild/rules_apple Apple Sources/BazelizeKit/Rule/Rule+Apple.swift
$(REPOS):
	python3 git_release.py $($@) $@ Sources/BazelizeKit/Repo/Repo+$@.swift

rules: $(REPOS)
