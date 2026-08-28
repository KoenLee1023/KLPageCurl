# 开始使用

为每个逻辑项目提供稳定且符合`Hashable`、`Sendable`的ID。固定列表可使用
`KLFinitePageCurlSequence`，其他数据模型可自行实现`KLPageCurlSequence`。
序列应保持`front(id)`、`back(id)`、`front(nextID)`的顺序，并在有限边界返回
`nil`。

创建`KLPageCurlPager`时传入选择绑定、序列、按表面计算的`revision`、正反面
视图构建器、配置和辅助功能文本。选择绑定只表示已经停靠的正面，`onSettled`
则会收到正面和背面。选择发生程序化变化时，`initialSurface(for:)`会选择初始
表面（通常是正面，但由序列策略定义），空闲状态机会原子地接受该表面；如果当时
正在转场，请在停靠后再次发送所需选择。

缓存半径按相邻ID计算。窗口内保留正反两面，只预加载尚未缓存的正面。每个表面
应提供稳定修订值。修订变化后在空闲时重载该表面，转场期间暂缓刷新。

`BookPreviewDemo`展示基本有限序列，`PhotoAlbumDemo`展示按表面修订。可见翻页
效果要求iOS 17。模型层支持macOS 14，但不包含翻页控件。
