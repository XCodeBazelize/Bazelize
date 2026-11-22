# TbCodeGenerater

The tool reads `tds/OptParser.td` through `Bundle.module` on every invocation,
including when the build tool plugin runs it. The manifest deliberately lists
`tds` in both `exclude` and `resources`: the explicit resource declaration wins,
as it does under SwiftPM. `Excluded/MustNotCompile.swift` is excluded without a
resource declaration and must never be compiled.

## Not support

* `OptionGroup`
* `Group`
* `class`

```
//def debug_crash_Group : OptionGroup<"<automatic crashing options>">;
//class DebugCrashOpt : Group<debug_crash_Group>;
```

### Skips

* `class`
* `def` without `Flag/Joined/...`

---

## Input

[FrontendOptions.td](https://github.com/swiftlang/swift/blob/main/include/swift/Option/FrontendOptions.td)
[Options.td](https://github.com/swiftlang/swift/blob/c2e36decfe4cb91db53baf01a1daa94c84e7ebcc/include/swift/Option/Options.td)

[llvm/Option/OptParser.td](https://github.com/llvm/llvm-project/blob/f71b83b3593588c56fd4ab3e1347ad9c7bec624f/llvm/include/llvm/Option/OptParser.td)
