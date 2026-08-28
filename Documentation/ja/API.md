# API

## 公開型

`KLPageCurlSurface<ID>` は論理項目の表面または裏面を表します。`KLPageCurlSequence` は初期項目と隣接項目を提供し、`KLFinitePageCurlSequence` は有限の順序付きコレクションを適応します。順序と終端の扱いは sequence が担当します。

`KLPageCurlStateMachine` が遷移状態を管理します。開始時に `beginTransition(to:)`、表示が確定した時に `finishTransition`、論理中心を変更した時に `recenter` を呼びます。`KLPageCurlTransitionOutcome` で遷移中と確定後の surface を区別できます。

`KLPageCurlConfiguration` はモーションとキャッシュをまとめます。`KLPageCurlPresentation.resolve(for:)` は「視差効果を減らす」設定を考慮して `staticPager` などを選びます。`KLPageCurlPager` は SwiftUI と UIKit の橋渡しで、内容の生成はアプリ側で行います。

`KLPageCurlCacheConfiguration.logicalRadius` は保持する近傍の範囲を制限します。`plan(around:sequence:cachedSurfaces:)` は保持、先読み、破棄の対象を返します。`KLPageCurlRevisionIndex` の `record(_:for:)` と `decision(for:currentRevision:)` を使えば、変更のない surface を再生成せずに済みます。破棄後は `applyEvictions(from:)` を呼びます。

`KLPageCurlAccessibility` には項目ごとのラベル、値、操作名、確定時の読み上げ文を渡します。製品固有の文言はホストが用意します。

`KLPageCurl` は両面を持つ論理ページ列をモデル化し、iOS では SwiftUI と UIKit で表示します。

`KLPageCurlSurface` は`front`または`back`を識別します。`KLPageCurlSequence`が初期面と隣接面を返し、`KLFinitePageCurlSequence`が有限の順序列を提供します。`KLPageCurlStateMachine`は`beginTransition(to:)`、`finishTransition`、`recenter`で選択と遷移を管理します。

`KLPageCurlConfiguration`は`KLPageCurlMotionPolicy`とキャッシュをまとめます。`KLPageCurlPresentation.resolve(for:)`は reduced motion を`staticPager`に解決します。`KLPageCurlPager`は`KLPageCurlViewController`への SwiftUI ブリッジです。

`KLPageCurlRevisionIndex`は`KLPageCurlRefreshDecision`を返し、変更された面だけを更新できます。内容、永続化、リビジョン生成、画像読み込みはホストが担当します。
