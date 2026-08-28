# ``KLPageCurl``

KLPageCurl用來描述雙面頁面序列，並在iOS上提供翻頁檢視。

每個邏輯項目依序顯示`front(id)`和`back(id)`。從背面繼續向後會到達
`front(nextID)`，反向移動則依相反順序進行。有限序列在第一個正面之前與最後
一個背面之後回傳`nil`。只有正面完成停駐後才會更新選取項目。背面停駐仍會呼叫
`onSettled`，但不會寫入新的選取值。

程式化選取會在分頁器閒置時呼叫`initialSurface(for:)`選擇初始表面（通常是所選
項目的正面，但由序列策略定義），狀態機會在一次更新中接受該表面。轉場進行中時，
要求會被忽略，不會只變更其中一部分。快取半徑以邏輯項目
計算，保留範圍內項目的正反兩面；預設半徑是1。修訂值依頁面表面區分。內容
變更後只重新載入對應表面，轉場期間則延後更新，直到分頁器閒置。

互動式返回由導覽宿主管理，包括手勢辨識器與邊緣規則。頁面手勢只會等待宿主
傳入的返回手勢失敗。啟用「減少動態效果」時傳入`reducedMotion`，分頁器會靜態
顯示`initialSurface(for:)`選擇的初始表面（通常是正面，但由序列策略定義）。
透過`KLPageCurlAccessibility`提供文字後，VoiceOver與
切換控制可使用可調整操作，以及具名的上一頁、下一頁操作；頁面內的控制項仍可
存取。

`BookPreviewDemo`示範有限書籍序列。`PhotoAlbumDemo`示範可編輯內容，以及彼此
獨立的正反面修訂。翻頁檢視需要iOS 17。序列、狀態機、快取、修訂、動態效果與
輔助使用模型支援macOS 14；macOS不提供翻頁檢視。

## 主題

- ``KLPageCurlSurface``
- ``KLPageCurlSequence``
- ``KLPageCurlStateMachine``
- ``KLPageCurlCacheConfiguration``
- ``KLPageCurlRevisionIndex``
- ``KLPageCurlAccessibility``
- ``KLPageCurlDirection``
- ``KLFinitePageCurlSequence``
- ``KLPageCurlTransitionState``
- ``KLPageCurlTransitionOutcome``
- ``KLPageCurlCachePlan``
- ``KLPageCurlRefreshDecision``
- ``KLPageCurlConfiguration``
- ``KLPageCurlMotionPolicy``
- ``KLPageCurlPresentation``
