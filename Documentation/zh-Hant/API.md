# API

## 公開型別

`KLPageCurlSurface<ID>` 表示一個邏輯項目的正面或背面。`KLPageCurlSequence` 提供初始項目與相鄰項目，`KLFinitePageCurlSequence` 適配有限的有序集合。順序與首尾行為由 sequence 負責。

`KLPageCurlStateMachine` 負責轉換狀態。開始導覽時呼叫 `beginTransition(to:)`，視覺轉換完成後呼叫 `finishTransition`，邏輯中心變更後呼叫 `recenter`。`KLPageCurlTransitionOutcome` 區分進行中的轉換與已穩定的 surface。

`KLPageCurlConfiguration` 組合動畫與快取策略。`KLPageCurlPresentation.resolve(for:)` 會考慮減少動態效果並可選擇 `staticPager`。`KLPageCurlPager` 連接 SwiftUI 與 UIKit 分頁器，內容生成仍由應用程式負責。

## 快取與更新

`KLPageCurlCacheConfiguration.logicalRadius` 限制保留的鄰居範圍。`plan(around:sequence:cachedSurfaces:)` 回傳 `KLPageCurlCachePlan`，說明需要保留、預載入與移除的 surface。`KLPageCurlRevisionIndex` 為每個 surface 保存應用程式提供的版本。以 `record(_:for:)` 記錄後，用 `decision(for:currentRevision:)` 取得 `keep`、`reload`、`create` 或 `deferUntilIdle`。提交移除後呼叫 `applyEvictions(from:)`。

`KLPageCurlAccessibility` 接收在地化標籤、值、操作名稱與穩定後的播報內容。產品文案與持久化由應用程式負責。

`KLPageCurl` 建模雙面的邏輯頁面序列，並在 iOS 上透過 SwiftUI 與 UIKit 展示。

`KLPageCurlSurface` 識別頁面的`front`或`back`面。`KLPageCurlSequence`提供初始面與相鄰面，`KLFinitePageCurlSequence`實作有序有限集合。`KLPageCurlStateMachine`透過`beginTransition(to:)`、`finishTransition`與`recenter`追蹤已提交選取與轉場。

`KLPageCurlConfiguration`組合`KLPageCurlMotionPolicy`與快取行為。`KLPageCurlPresentation.resolve(for:)`將減少動態解析為`staticPager`。`KLPageCurlPager`連接`KLPageCurlViewController`。

`KLPageCurlRevisionIndex`回傳`KLPageCurlRefreshDecision`，讓宿主只刷新變更的頁面面。`KLPageCurlCacheConfiguration`與`KLPageCurlCachePlan`描述保留、預載與淘汰的頁面面。頁面內容、持久化、版本產生與圖片載入由宿主負責。
