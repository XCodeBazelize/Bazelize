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

### A4. dynamic library product 會靜默變成一般 library

manifest 仍帶著 `{"library": ["dynamic"]}`，但 `PackageProduct.kind` 把所有 library
product 都折成 `.library`。所以生成的 product 與 automatic library 一樣，只是一個
alias 或 `swift_library_group`，也沒有 note 說 SwiftPM 原本要求的是 dynamic library。

第一個可獨立交付的修正，是解析 `automatic`、`static`、`dynamic`，並對尚未支援的
dynamic case 發出回報，先停止靜默降級。完整支援還需要產生 dylib 的規則、穩定的
product facade、正確的 link／packaging 行為、fixture 與 CI coverage。

### A5. build tool plugin executable 的 resource runfiles 會遺失

`//Packages:plugins` 是一個 `filegroup`，`srcs` 只有 plugin tool binaries，沒有轉發
那些 binary 的 runfiles。帶 resource 的工具可以編得過、也能被 plugin host 找到，
但執行期讀取 bundle 時會失敗。

plugin entry point 與它需要的 runfiles 必須一起傳遞。要加一個 tool 在 plugin 執行時
實際讀 resource 的 fixture；只驗證 executable 建得起來抓不到這個問題。

### A6. 設定檔不能選 target，也不能關閉生成的功能

v1 `bazelize.yaml` schema 只有 `schema` 與 buildifier release。必須排除某個 target
的人，目前只能 fork input project 或 generator。

保守的 target-selection 契約是精確 target 名稱；若保留的 target 依賴被排除者就報錯。
只有生成 surface 確實造成成本或不相容時才加入 feature switch，key 應描述使用者看得見
的能力，而不是內部 plugin class。Bazel／BCR dependency pin 仍由 generator 管理，
Swift package version 仍由 `Package.resolved` 管理。

### A7. 多個 trait 的選擇沒有單一 Bazel configuration

SwiftPM 的 `--traits A,B` 是一次 replacement selection。生成的 rc 對每個 trait
各提供一個 config，另外有 `none`、`all`、`default` 三種具名選擇。公開的 boolean
flag 能表示組合，但沒有一個 `--config` 就能拼出同樣的選擇。

支援逗號分隔的便利寫法需要累加式 selection 語意，不能直接組合現有的 replacement
configs。這項先延後；目前的 escape hatch 是直接指定各 flag。

## B. 覆蓋率

### B1. `spm/` 裡沒有任何東西在 iOS 上**測**

`spm/Platform` 現在會為 iOS 建：它那條 lane 用
`--platforms=@apple_support//platforms:ios_sim_arm64` 建 package 規則，並斷言那個
configuration 選到哪些 setting 與 dependency。還是只有 macOS 的，是所有「需要真的
有一個 bundle」的東西 —— iOS 的 bundle 形狀、iOS 規則上的 `minimum_os_version`
—— 因為套件的測試是 `macos_unit_test`。把 fixture 的測試跑在模擬器上，是剩下的
那個洞。

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

### B5. 裸的來源目錄 —— 已完成，而且它不是死碼、是缺口

原本的 fallback 找的是 `<套件根目錄>/<target 名稱>`。SwiftPM 對那種佈局會發警告，
而且編出來是**空模組**（import 不到）—— 所以任何合法的套件都走不到那個 fallback。

SwiftPM 真正允許、而那個 fallback 漏掉的，是**來源目錄本身**：檔案直接放在
`Sources`、沒有屬於 target 的子目錄，在沒有其他 target 會來搶的情況下是合法的。
這種套件以前會被**靜默丟掉** —— 產出一個空的 `BUILD`、沒有任何規則。

`sourceDirectory` 現在會找那裡，條件與 SwiftPM 相同：該套件只有一個同類型的
target。`spm/ConfigurationCondition` 就是這樣的佈局，所以之後有東西會叫。

### B6. 跨套件使用 macro —— 已完成

`spm/Macro/Provider` 提供一個 macro 與宣告它的 library；root 套件透過那個
product 使用它，與它自己原本就有的同套件 macro 並存。

產生器**一行都不用改**，而這正是值得記住的地方：consumer 的規則裡只列自己套件的
plugin，隔壁套件那個之所以生效，是因為宣告該 macro 的 library 帶著
`plugins = [":ProviderMacros"]`，而 rules_swift 會把 compiler plugin 傳播給
依賴那個 library 的人 —— 經過 product facade 也一樣。

### B7. asset catalog 的各種變體

只建過 colorset。app icon set、symbol set 與產生的 asset symbols 都沒有。

### B8. plugin 生成物還不能錄進 workspace snapshot

生成的 plugin `BUILD` 含有目前 Swift toolchain 的絕對路徑，原樣記錄會讓 snapshot
只適用於一台機器與一個 Xcode 安裝位置。先在 snapshot harness 遮罩該路徑，再把
plugin workspace 加進 `GeneratedWorkspaceSnapshotTests`。

## C. 流程

### C1. 子套件沒有測試 —— 刻意如此

fixture 底下有 13 個套件（`vendor-kit`、`Alt`、`Other`、`Stamping`、`Marking`、
`Products`、`Macro/Provider`、`Trait/Dependency`、`TraitGraph/*Dependency`、
`DependencyCondition/Extras`、`DependencyCondition/LinuxOnly`）是給人依賴用的，
本身沒有東西好斷言。CI 對每一個都跑 `swift build` —— 只有 plugin 的那個除外，
SwiftPM 根本拒絕建它 —— 而只有存在 `Tests` 目錄的才跑 `swift test`，不會為了讓
指令回 0 而塞一堆證明不了任何事的測試。

這個目錄判斷會漏掉自訂 test target path 的套件。`spm/TargetPath` 把測試放在
`Code/Tests`，所以它的 SwiftPM 測試從未在這條 lane 執行，只有 Bazel 側有跑到。
應改用 `swift package dump-package` 判斷 manifest 是否有 test target，而不是假設
一定存在頂層 `Tests` 目錄。

### C2. lane 會因為沒人預期的 note 而失敗 —— 已完成

note 是產生器在說「這個 build 與套件要求的不一樣」：plugin 沒跑起來、程式的
resources 沒有東西可以打包、`pkg-config` 不認識那個函式庫。這些情況 build 與
test 都是綠的、錯在執行期，而 package lane 以前直接把產生器的輸出丟掉。

現在 lane 會留下輸出，**只要有話說就失敗**，除非該 lane 在 `notes` 裡指名它本來
就是為那句話存在的。目前沒有任何 fixture 會說話，所以這道閘門是預設關著的：出現
note 等於 lane 變紅，而不是多一行沒人看的字。

### C3. `TargetEmbed` 用 `--build-system native` 跑

在當初寫那條 lane 的工具鏈上，`swiftbuild` 完全不產 `.embedInCode` 需要的
`PackageResources` —— Xcode 27 的會 —— 而 `native` 一直都會產。那條 lane 指名
實作了這條規則的 build system，而不是繼承 runner 當下附的那個；這也正是那條規則
被拆成獨立套件的原因。

### C4. generated Starlark lint 還沒有真正擋住 CI

兩個 `Check Generated Starlark` step 都以 `continue-on-error: true` 執行
`bazel run //:lint`，所以新 lint warning 只會被顯示，仍然放行。應移到一條便宜的
lane：每個 fixture 只做 `generate` 再 `lint`，不 build、不 test；昂貴 integration
lane 裡重複的檢查則移除。第一階段只擋 lint warning，格式類 `# reformat` 仍放過。

### C5. 決定 generation 是否能 opt in 自動格式化

目前契約是使用者顯式執行 `bazel run //:format`，generation 本身不格式化。若要讓
generation 代跑，需在 `--format` flag 與持久設定鍵之間擇一。實作必須呼叫 workspace
自己的 `//:format`：它會下載設定檔指定的 buildifier release 並驗 checksum；不可直接
使用 `PATH` 上任意版本的 executable。

採用格式化後的生成物，需要重錄全部 generated workspace snapshots。完成後 lint gate
才能同時擋格式差異與 lint warning。
