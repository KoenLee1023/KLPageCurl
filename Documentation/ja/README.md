# ``KLPageCurl``

KLPageCurlは両面ページの並びをモデル化し、iOS向けのページカール表示を提供
します。

各項目は`front(id)`、`back(id)`の順で表示されます。背面から先へ進むと
`front(nextID)`になり、逆方向ではこの順序を逆にたどります。有限シーケンスは
最初の表面より前と最後の裏面より後で`nil`を返します。選択値が変わるのは表面
への遷移が完了したときだけです。裏面への遷移でも`onSettled`は呼ばれますが、
選択値は書き換えません。

プログラムから選択値を変えると、待機中のページャーは`initialSurface(for:)`で
初期表面を選びます。通常は選択項目の表面ですが、これはシーケンスの方針で決まり、
状態機械がその表面を一度に受け入れます。遷移中の要求は無視され、状態の一部
だけが変わることはありません。キャッシュ半径は論理項目単位で、範囲内の表裏
を保持します。既定値は1です。リビジョンは表面ごとに分かれ、内容が変わった
表面だけを待機時に再読み込みします。遷移中の更新は完了まで保留されます。

インタラクティブポップの認識器とエッジ方針はナビゲーション側が所有します。
ページジェスチャーは渡されたポップ認識器の失敗を待つだけです。「視差効果を
減らす」が必要な場合は`reducedMotion`を指定し、`initialSurface(for:)`が選ぶ
初期表面（通常は表面ですが、シーケンスの方針で決まります）を静止表示します。
`KLPageCurlAccessibility`に文言を渡すと、VoiceOverとスイッチコントロールで
調整アクションと名前付きの前後アクションを使えます。ページ内の操作要素も
引き続き利用できます。

`BookPreviewDemo`は有限の書籍を、`PhotoAlbumDemo`は編集可能な表裏別リビジョン
を示します。カール表示にはiOS 17以降が必要です。シーケンス、状態機械、
キャッシュ、リビジョン、モーション、アクセシビリティのモデルはmacOS 14以降
で利用できますが、macOSにはカール表示がありません。

## トピック

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
