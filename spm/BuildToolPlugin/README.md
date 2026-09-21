# TbCodeGenerater

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
