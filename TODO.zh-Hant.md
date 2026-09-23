# TODO（中文版）

英文版：[TODO.md](TODO.md)。兩份內容相同。

bazelize 的 SwiftPM 這一側還沒做的事，以及為什麼。寫於 `spm/` fixture 增到 24
個套件之後 —— 這 24 個在兩邊都建得起來也測得過（`swift build`／`swift test`，
以及 `bazelize` + `bazel test //...`）。

依「使用者最先踩到什麼」排序。

## A. 產生器行為

### A1. executable target 的 resources 不會被打包

`swift_binary` 建出來的程式拿得到產生的 `Bundle.module` accessor，卻拿不到
bundle：`apple_resource_bundle` 是把資源交給「組 bundle 的人」—— app 或
test —— 而程式兩者都不是，所以那條規則產出的東西沒有人會放到任何地方。二進位
檔編得過，跑起來 `fatalError`。

證據：對那個 bundle 下 `cquery --output=files` 是空的，`OutputGroupInfo` 是空
depset，所以就算在執行檔上掛 `data = [":XResources"]`，runfiles 裡也不會多出
任何東西。

目前的做法是在產生階段就明講（`SwiftPM+Resources.swift` 的 `.executable`
分支），而不是留給使用者用 crash 去發現。

要修的話，得把 bundle 目錄寫進產生的 workspace ——
`Generated/<Package>_<Target>.bundle`，裡面放 Info.plist 與每個資源的
symlink —— 用 `data` 帶進 runfiles，再教 accessor 認得 runfiles 的候選路徑。
代價是 `.process` 不再編譯：程式的資源裡若有 asset catalog、xib 或 shader，
會變成原樣複製而不是編譯，這與 SwiftPM 有落差，該在發生的地方回報。

SwiftPM 會把那個 bundle 寫在程式旁邊，所以「CLI 工具帶資源」這種套件在
SwiftPM 能跑、在這裡不能。

### A2. 未宣告的 privacy manifest 不會進 bundle

`PrivacyInfo.xcprivacy` 放在 target 原始碼旁邊時，SwiftPM 的預設 build system
會把它打包，這裡不會 —— 產生器的「自動辨識資源類型」清單裡沒有它。有明確宣告
（`.copy`）的套件兩邊都正常，`spm/TargetResource` 就是這樣做的。

把 `xcprivacy` 加進自動辨識清單會對齊預設 build system，但會與
`--build-system native` 不一致（後者忽略它）。改之前要先決定哪一個才是我們的
契約。

### A3. resource bundle 是扁平而非包裝式 —— 不打算做

macOS 上 SwiftPM 產的是 `Bundle.bundle/Contents/Resources/…`；rules_apple 在
所有平台都刻意產扁平的 `Bundle.bundle/…`，那是 iOS 的形狀。實測過：
`Bundle.module.infoDictionary` 與各種 `url(forResource:)` 查找在兩邊答案相同，
只有自己手拼 `Contents/Resources` 路徑的程式碼會看見差異。要對齊就得放棄
`apple_resource_bundle` 自己組 bundle，不划算。

## B. 覆蓋率

### B1. `spm/` 裡沒有任何東西是為 iOS 建的

所有 fixture 都是 macOS。`spm/Platform` 有宣告 `.iOS(.v16)`，但測試仍在 macOS
上跑，所以 iOS 的 bundle 形狀、iOS 規則上的 `minimum_os_version`、以及 package
規則被建立時所經過的 platform transition，都只有 `fixture/iOS`（Xcode 那側）
間接覆蓋。**這是最大的一個洞。**

### B2. `.xcmappingmodel` —— 不打算做

它的原始檔是 Core Data 的 XML persistent store，只有 Xcode 的 modeler 寫得
出來；手寫的 `xcmapping.xml` 會被 `mapc` 拒絕（`Unknown store type, format,
or version`），而且在一台裝了 Xcode 的機器上也找不到任何範本可以照抄格式。
它對 bazelize 來說也沒有特別之處：glob 與分組的路徑與 `.xcdatamodeld` 完全
相同，而後者有 fixture 也有斷言；真正會編譯它的是 rules_apple 自己的 action。

migration 真正立足的東西 —— 有版本的 `.xcdatamodeld`、兩個版本都在 bundle 裡、
兩版之間能推導出 mapping —— 已經覆蓋了。

### B3. 用 branch、revision 或精確版本釘住的依賴

所有 fixture 都用 `from:`。對產生器而言這幾種是同一條路：SwiftPM 解析完，產生
器讀 checkout。價值低。

### B4. 沒有 product 的套件，以及只有 plugin 的套件 —— 已完成

兩個都不需要自己的 lane。`spm/TargetExclude` 完全不宣告 product —— 一個只有
target 的套件，建得起來、測得過、沒有人依賴它；`spm/PluginDependency/Marking`
則是只有一個 plugin 與對應的 plugin product，由隔壁的套件使用。

第二點有件事值得記住：**屬於別的套件的 plugin 是由 bazelize 自己編的，不是
Bazel 建的**。`Packages/Marking/BUILD` 產出來是空檔，因為建 plugin 的規則是寫給
「使用它的套件」，而 Marking 誰也沒用。那個空檔是刻意的：它讓那個目錄成為獨立的
Bazel package，父層的 glob 就抓不進去。

### B5. 原始碼直接放在套件根目錄的 target

`sourceDirectory(of:in:)` 有一個 fallback 會找 `package.root + target.name`，
但 SwiftPM 只會在 `Sources`、`Source`、`src`、`srcs` 裡找（除非 target 自己寫了
`path:`）。要查的是那個 fallback 到底走不走得到：如果走不到，**刪掉**比補
fixture 好。

### B6. 跨套件使用 macro —— 已完成

`spm/Macro/Provider` 提供一個 macro 與宣告它的 library；root 套件透過那個
product 使用它，與它自己原本就有的同套件 macro 並存。

產生器**一行都不用改**，而這正是值得記住的地方：consumer 的規則裡只列自己套件的
plugin，隔壁套件那個之所以生效，是因為宣告該 macro 的 library 帶著
`plugins = [":ProviderMacros"]`，而 rules_swift 會把 compiler plugin 傳播給
依賴那個 library 的人 —— 經過 product facade 也一樣。

### B7. asset catalog 的各種變體

只建過 colorset。app icon set、symbol set 與產生的 asset symbols 都沒有。

## C. 流程

### C1. 子套件沒有測試 —— 刻意如此

fixture 底下有 11 個套件（`vendor-kit`、`Alt`、`Other`、`Stamping`、
`Products`、`Trait/Dependency`、`TraitGraph/*Dependency`、
`DependencyCondition/Extras`、`DependencyCondition/LinuxOnly`）是給人依賴用的，
本身沒有東西好斷言。CI 對每一個都跑 `swift build`，只有存在 `Tests` 目錄的才跑
`swift test` —— 不會為了讓指令回 0 而塞一堆證明不了任何事的測試。

### C2. fixture lane 不會因為產生器的提醒而失敗

`IntegrateIOS` 會在產生的 log 裡 grep `did not run the`；套件的 lane 什麼都沒
檢查。像 A1 那種提醒不會讓 CI 變紅。補起來很便宜：把產生輸出寫進 log，對在意的
提醒讓 lane 失敗。

### C3. `TargetEmbed` 需要 `--build-system native`

在這個工具鏈上，預設 build system 完全不產 `.embedInCode` 需要的
`PackageResources`，那是 SwiftPM 自己的缺口。它是唯一需要這個 flag 的 fixture
—— 這也正是那條規則被拆成獨立套件的原因。
