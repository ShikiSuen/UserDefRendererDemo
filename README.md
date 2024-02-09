# 初證精實案：Interface Builder 廢黜案生效

> 這個範例專案雖然是在講 AppKit，但這些知識也可以類推給 UIKit 使用。

打比方說你需要維護一個 macOS 平台的 AppKit 應用，因為某些原因不方便「僅」使用 SwiftUI、只能同時維護兩套偏好設定介面。通常情況下的操作是這樣：

1. 自己弄個 Enum 管理這一沓 UserDefaults Keys，或者用 SindreSorhus 的 Defaults （下文簡稱 DefaultsSPM）來管理。
2. SwiftUI 用 @AppStorage 單獨寫個在 View 內使用的存取點，或者用 DefaultsSPM 在 View 內佈置存取點。
3. 自己弄的 Enum 需要在專案內有一個中樞 Class 來管理對所有 UserDefaults 的存取操作；DefaultsSPM 本身就帶有這個功能。
4. 非 SwiftUI 用的偏好設定視窗單獨製作，這也是本文這次要涵蓋的話題。

論及非 SwiftUI 用的偏好設定視窗，那一定是用到了 AppKit 的。從常識上來講，在專案剛開始的時候，可能會用 Inteface Builder 畫個 XIB＋綁一下 UserDefaults 然後再連一堆 IBActions。這種「基於圖形介面操作的所見即所得」的工作方式看似簡單，但有不少缺點：

1. 版本管理：用 git 管理 XIB 檔案的 merge conflicts 很難。
2. 本地化成本：與 SwiftUI 版偏好設定介面無法直接共用本地化翻譯資源。你必須要分別維護兩套翻譯資料（XIB 用一套，Localizable.strings 又是一套）。更甚者，Xcode 15 新增了 Localization Catalog 把問題搞得更複雜了，且在 Intel Mac 下 lag 得要命。你不希望這種糟糕的體驗翻倍。
3. 新選項的介面實作成本隨著 UserDefaults Keys 的數量呈雙倍上漲，而且每次都需要你在 Inteface Builder 裡面用滑鼠來調整。XIB 檔案越複雜，Inteface Builder 響應越遲鈍。
4. 更氣人的是，Interface Builder 對某些 AppKit 介面控制項而言的**預設行為**還可能與「你自己純寫扣初期化出來的副本的預設行為」不一致。你在 Interface Builder 裡面看到的樣子，和 App 在某些版本的系統下運行的樣子，可能根本就是兩碼事。

這些都是逐年遞增的隱形成本，讓寫扣的人越來越不想實作新功能給 AppKit UI 用。

於是呢，咱們就用純寫扣的方式來**做精實案、將 Interface Builder 的依賴給廢掉**。不但如此，咱們還要讓這個過程的體驗變得像寫 SwiftUI 那種聲明式介面那樣簡潔。

筆者最近剛剛給威注音輸入法做了這個精實案。截至 3.7.3 版，威注音輸入法有 86 個 UserDefaults Keys，且其中大約有 79 個是需要做到偏好設定畫面當中的，且有繁簡英日四個語系介面的本地化。這就產生了要做精實案的需求。但由於這 Keys 的數量有些過多，直接拿威注音的原始碼全部照搬過來的話有些不切實際。回頭等威注音 3.7.4 版正式發佈之後，各位可以看一下原始碼倉庫的 commit 記錄。

於是乎，就有了這個簡單的範例參考專案來介紹這個實作過程。但這個範例專案並未使用到 DefaultsSPM，而是筆者自己弄了一個 enum 來管理 UserDefaults。各位在使用的時候可以在 DefaultsSPM 的基礎上自行探索實作本文要實作的內容。

> 免責聲明：這個範例不是萬金油。每個讀者可能都有各自的專屬問題、需要各自**單獨自行解決**。

![](./SCREENSHOT.png)

$ EOF.
