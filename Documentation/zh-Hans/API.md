# API

## 公开类型

`KLPageCurlSurface<ID>` 表示一个逻辑项目的正面或背面。`KLPageCurlSequence` 提供初始项目和相邻项目，`KLFinitePageCurlSequence` 适配有限的有序集合。顺序和首尾行为由 sequence 负责。

`KLPageCurlStateMachine` 负责转换状态。开始导航时调用 `beginTransition(to:)`，视觉过渡完成后调用 `finishTransition`，逻辑中心改变后调用 `recenter`。`KLPageCurlTransitionOutcome` 区分进行中的转换和已稳定的 surface。

`KLPageCurlConfiguration` 组合动画与缓存策略。`KLPageCurlPresentation.resolve(for:)` 会考虑减弱动态效果并可选择 `staticPager`。`KLPageCurlPager` 负责连接 SwiftUI 与 UIKit 分页器，内容生成仍由应用负责。

## 缓存与刷新

`KLPageCurlCacheConfiguration.logicalRadius` 限制保留的邻居范围。`plan(around:sequence:cachedSurfaces:)` 返回 `KLPageCurlCachePlan`，说明需要保留、预加载和移除的 surface。`KLPageCurlRevisionIndex` 为每个 surface 保存应用提供的版本。用 `record(_:for:)` 记录后，用 `decision(for:currentRevision:)` 获取 `keep`、`reload`、`create` 或 `deferUntilIdle`。提交移除后调用 `applyEvictions(from:)`。

`KLPageCurlAccessibility` 接收本地化标签、值、操作名称和稳定后的播报内容。产品文案和持久化由应用负责。

`KLPageCurl` 建模双面的逻辑页面序列，并在 iOS 上通过 SwiftUI 和 UIKit 展示。

`KLPageCurlSurface` 标识页面的`front`或`back`面。`KLPageCurlSequence`提供初始面和相邻面，`KLFinitePageCurlSequence`实现有序的有限集合。`KLPageCurlStateMachine`通过`beginTransition(to:)`、`finishTransition`和`recenter`追踪已提交选择与转场。

`KLPageCurlConfiguration`组合`KLPageCurlMotionPolicy`与缓存行为。`KLPageCurlPresentation.resolve(for:)`把减弱动画解析为`staticPager`。`KLPageCurlPager`连接`KLPageCurlViewController`。

`KLPageCurlRevisionIndex`返回`KLPageCurlRefreshDecision`，让宿主只刷新发生变化的页面面。`KLPageCurlCacheConfiguration`和`KLPageCurlCachePlan`描述保留、预加载和淘汰的页面面。页面内容、持久化、版本生成和图片加载由宿主负责。
