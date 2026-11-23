Describe the observable change and the issue it fixes. Preserve each issue's acceptance criteria.

Validation:

- [ ] Run relevant local tests and runtime/build checks.
- [ ] Run `make format` before committing Swift changes; before opening the PR, run `python3 scripts/format-swift.py --base origin/master` using the actual base, review, and stage the intended result. CI does not run SwiftFormat.
- [ ] For loader, SwiftPM, plugin, codegen, or toolchain/rules changes, manually run [Compatibility](https://github.com/XCodeBazelize/Bazelize/actions/workflows/compatibility.yml) on this PR's branch and include the run link, or explain why it is not applicable. External apps/packages run only manually and on version tags; there is no nightly schedule.

Link resolved issues with a closing keyword, for example `Closes #44`.
