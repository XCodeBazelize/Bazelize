# TODO（中文版）

英文版：[TODO.md](TODO.md)。兩份內容相同。

bazelize 的 SwiftPM 這一側還沒做的事，以及為什麼。fixture corpus 會把支援的套件
形狀分別透過 SwiftPM 與生成的 Bazel workspace 建置、測試並實際執行。

依「使用者最先踩到什麼」排序。

## A. 產生器行為

### A1. executable target resources —— 已完成

executable 現在會拿到真正的 runfiles bundle，不再只有生成的 `Bundle.module`
accessor。`macos_bundle` 負責 asset catalog、xib、shader 與其他 `.process` 輸入所需
的平台編譯；生成的 `//Packages:swiftpm_resource_bundle.bzl` 規則會把 archive 解成
tree artifact、移除 bundler 合成的空 executable 與失效簽章，再透過 `DefaultInfo`
runfiles 提供純資源 `.bundle`。

`swift_binary` 以 `data` 帶入該 target。accessor 先找一般 Apple bundle 位置，再找
Bazel 的 `RUNFILES_DIR`、`TEST_SRCDIR` 與 executable 旁的 runfiles tree。
`spm/ExecutableResource` 會實際執行結果，檢查 copy 與 process 的檔案、編譯過的
asset catalog，以及未宣告的 privacy manifest。

### A2. 未宣告的 privacy manifest —— 已完成

target source tree 裡的 `PrivacyInfo.xcprivacy` 若尚未被任何已宣告 resource 包含，
現在會自動取得 `.copy` 語意。因此 manifest 以自己的檔名落在 bundle root，與
SwiftPM 預設 build system 一致，也不會和明確宣告的檔案或目錄重複。

`spm/ExecutableResource` 覆蓋未宣告情況；`spm/TargetResource` 保留明確的 `.copy`
宣告並覆蓋去重路徑。這會刻意與忽略未宣告 manifest 的
`--build-system native` 不同。

### A3. 先不修：resource bundle 是扁平而非包裝式

macOS 上 SwiftPM 的 library 與 test resource bundle 是
`Bundle.bundle/Contents/Resources/…`；rules_apple 在所有平台都刻意產扁平的
`Bundle.bundle/…`，那是 iOS 的形狀。實測過：`Bundle.module.infoDictionary` 與
各種 `url(forResource:)` 查找在兩邊答案相同，只有自己手拼
`Contents/Resources` 路徑的程式碼會看見差異。要對齊這些 bundle 形狀就得放棄
`apple_resource_bundle` 自己組 bundle，不划算。

### A4. 先不修：dynamic library product 會變成一般 library

manifest 仍帶著 `{"library": ["dynamic"]}`，但 `PackageProduct.kind` 把所有 library
product 都折成 `.library`。所以生成的 product 與 automatic library 一樣，只是一個
alias 或 `swift_library_group`，也沒有 note 說 SwiftPM 原本要求的是 dynamic library。

目前還沒有決定完整的 dylib rule、product facade、transitive linking 與 packaging
契約。只做一部分仍會讓 product 語意不清楚，因此先留下紀錄、不排程修正。

### A5. 尚未決定：build tool plugin executable 的 resource runfiles 會遺失

`//Packages:plugins` 是一個 `filegroup`，`srcs` 只有 plugin tool binaries，沒有轉發
那些 binary 的 runfiles。帶 resource 的工具可以編得過、也能被 plugin host 找到，
但執行期讀取 bundle 時會失敗。

plugin entry point 與它需要的 runfiles 必須一起傳遞，但 provider 形狀與 fixture
契約都尚未決定；先不過早承諾自訂 forwarding rule。

### A6. 先不修：設定檔不能選 target，也不能關閉生成的功能

v1 `bazelize.yaml` schema 只有 `schema` 與 buildifier release。必須排除某個 target
的人，目前只能 fork input project 或 generator。

保守的 target-selection 契約是精確 target 名稱；若保留的 target 依賴被排除者就報錯。
只有生成 surface 確實造成成本或不相容時才加入 feature switch，key 應描述使用者看得見
的能力，而不是內部 plugin class。Bazel／BCR dependency pin 仍由 generator 管理，
Swift package version 仍由 `Package.resolved` 管理。

### A7. trait selection 已貼齊 SwiftPM —— 已完成

SwiftPM 的 `--traits A` 會讓該 package 以 `-DA` 編譯；沒有選到的其他 trait 不會產生
任何 `-D`。現在的 `--config=<Package>.A` 正是這個行為：打開 A 的 build setting，
其他 trait condition 不成立。false build setting 並不是一個負向 compiler define。

生成的 `<Package>.none` 對應 `--disable-default-traits`；`<Package>.default` 還原
manifest defaults，`<Package>.all` 打開全部。多個 trait 也能用公開的 boolean flags
表示。少一個單一 config 的便利寫法不算 generator 行為缺口，因此不再列為未完成。

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

### B7. asset catalog 的各種變體 —— 已完成

iOS fixture 現在會建 app icon 與自訂 symbol set，也會啟用 Xcode 生成的 Swift
asset symbols，並編譯使用生成 image、symbol image、color API 的原始碼。建出的
IPA 內含 `Assets.car` 與 app icon metadata。

### B8. plugin 生成物還不能錄進 workspace snapshot

生成的 plugin `BUILD` 含有目前 Swift toolchain 的絕對路徑，原樣記錄會讓 snapshot
只適用於一台機器與一個 Xcode 安裝位置。先在 snapshot harness 遮罩該路徑，再把
plugin workspace 加進 `GeneratedWorkspaceSnapshotTests`。

## C. 流程

### C1. 子套件沒有測試 —— 刻意如此

沒有測試的 fixture 不會為了湊數塞入證明不了任何事的斷言。Bazel 這側的 CI 會先問
`bazel query 'tests(//...)'`，有結果才執行 `bazel test //...`；
`spm/ExecutableResource` 這類只有 executable 的套件照常建置，並由專用 program step
實際執行，不再因空的 test selection 讓 lane 失敗。

13 個子套件（`vendor-kit`、`Alt`、`Other`、`Stamping`、`Marking`、`Products`、
`Macro/Provider`、`Trait/Dependency`、`TraitGraph/*Dependency`、
`DependencyCondition/Extras`、`DependencyCondition/LinuxOnly`）同樣沒有自己的內容
需要斷言。

SwiftPM 這側仍有一個缺口：目錄判斷會漏掉自訂 test target path 的套件。
`spm/TargetPath` 把測試放在 `Code/Tests`，所以它的 SwiftPM 測試從未在這條 lane
執行，只有 Bazel 側有跑到。應改用 `swift package dump-package` 判斷 manifest
是否有 test target，而不是假設一定存在頂層 `Tests` 目錄。

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
