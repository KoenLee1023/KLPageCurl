# ``KLPageCurl``

KLPageCurl用于描述双面页面序列，并在iOS上提供翻页视图。

每个逻辑项目依次显示`front(id)`和`back(id)`。从背面继续向后会到达
`front(nextID)`，反向移动遵循相反顺序。有限序列在第一个正面之前、最后一个
背面之后返回`nil`。只有正面完成停靠后才会更新选择。背面停靠仍会调用
`onSettled`，但不会写入新的选择。

程序化选择会在分页器空闲时调用`initialSurface(for:)`选择初始表面（通常是所选
项目的正面，但由序列策略定义），状态机会在一次更新中接受该表面。转场进行中时，
请求会被忽略，不会只改动其中一部分。缓存半径按逻辑
项目计算，保留窗口内项目的正反两面；默认半径为1。修订值按页面表面区分。
内容变化后只重载对应表面，转场期间则推迟刷新，直到分页器空闲。

交互式返回由导航宿主管理，包括手势识别器和边缘策略。页面手势只等待宿主
传入的返回手势失败。启用“减弱动态效果”时传入`reducedMotion`，分页器会静态
显示`initialSurface(for:)`选择的初始表面（通常是正面，但由序列策略定义）。
通过`KLPageCurlAccessibility`提供文本后，VoiceOver和
切换控制可以使用可调节操作以及具名的上一页、下一页操作；页面中的控件仍可
访问。

`BookPreviewDemo`演示有限书籍序列。`PhotoAlbumDemo`演示可编辑内容和相互独立
的正反面修订。翻页视图要求iOS 17。序列、状态机、缓存、修订、动态效果和辅助
功能模型支持macOS 14；macOS不提供翻页视图。

## 主题

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
