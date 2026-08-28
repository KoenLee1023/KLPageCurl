# 開始使用

為每個邏輯項目提供穩定且符合`Hashable`、`Sendable`的ID。固定清單可使用
`KLFinitePageCurlSequence`，其他資料模型可自行實作`KLPageCurlSequence`。
序列應維持`front(id)`、`back(id)`、`front(nextID)`的順序，並在有限邊界回傳
`nil`。

建立`KLPageCurlPager`時，傳入選取繫結、序列、依表面計算的`revision`、正反面
檢視產生器、設定與輔助使用文字。選取繫結只代表已停駐的正面，`onSettled`則會
收到正面與背面。選取項目透過程式變更時，`initialSurface(for:)`會選擇初始表面
（通常是正面，但由序列策略定義），閒置的狀態機會原子地接受該表面；若當時正在
轉場，請在停駐後再次傳送所需選取值。

快取半徑依相鄰ID計算。範圍內保留正反兩面，只預先載入尚未快取的正面。每個
表面應提供穩定修訂值。修訂變更後於閒置時重新載入該表面，轉場期間暫緩更新。

`BookPreviewDemo`展示基本有限序列，`PhotoAlbumDemo`展示依表面修訂。可見翻頁
效果需要iOS 17。模型層支援macOS 14，但不包含翻頁控制項。
