# 封存

CocoaPods 的研究筆記：讀 `Podfile`／`Podfile.lock`、把 pod 依賴對應到 Bazel
規則、以及 [PodToBUILD](https://github.com/pinterest/PodToBUILD) 的產物長什麼
樣子。

**bazelize 沒有實作其中任何一項**，程式碼裡沒有任何 CocoaPods 的處理路徑。筆記
留著是因為真要做的時候，`pod ipc podfile-json` 的輸出形狀與 pod 來源／版本的
對應關係不必重查一次。寫下它們時的 Bazel workspace 還是 `WORKSPACE`，現在產生
的是 `MODULE.bazel`，所以裡面的 `new_pod_repository` 之類的寫法只能當成語意參考。

| 檔案 | 內容 |
|---|---|
| `Podfile.md` | `Podfile` 的語法與 `pod ipc podfile-json` 的輸出 |
| `Podfile.lock.md` | `Podfile.lock` 怎麼對應到當時的 `Pods.WORKSPACE` |
| `Podfile+PodToBUILD.md` | 依賴如何映射成 `//Vendor/...` 標籤 |
| `RxSwift+PodToBUILD.md` | PodToBUILD 對 RxSwift 產出的規則樣本 |
| `Cocoapod_ZH.md` | 原本在 `docs/Dependecy_ZH.md` 裡的 Cocoapod 一節 |
