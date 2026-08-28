# API

## Public types

`KLPageCurlSurface<ID>` identifies the front or back of one logical item. `KLPageCurlSequence` supplies the initial and adjacent items, while `KLFinitePageCurlSequence` adapts a finite ordered collection. Ordering and end-of-list behavior remain with the sequence.

`KLPageCurlStateMachine` is the transition authority. Call `beginTransition(to:)` when navigation starts, `finishTransition` after the visual settle, and `recenter` when the logical center changes. `KLPageCurlTransitionOutcome` distinguishes an in-flight transition from a settled surface.

`KLPageCurlConfiguration` combines motion and cache policy. `KLPageCurlPresentation.resolve(for:)` accounts for the environment, including reduced motion, and can select `staticPager`. `KLPageCurlPager` bridges SwiftUI to the UIKit pager; content factories remain the host's responsibility.

## Cache and refresh

`KLPageCurlCacheConfiguration.logicalRadius` bounds retained neighbors. `plan(around:sequence:cachedSurfaces:)` returns a `KLPageCurlCachePlan` with surfaces to retain, preload, and evict. `KLPageCurlRevisionIndex` stores host revisions per surface: record a revision with `record(_:for:)`, then use `decision(for:currentRevision:)` to receive `keep`, `reload`, `create`, or `deferUntilIdle`. Call `applyEvictions(from:)` after committing eviction.

`KLPageCurlAccessibility` receives localized labels, values, action names, and settle announcements. The package does not provide product vocabulary or persistence.

`KLPageCurl` models a double-sided logical page sequence and presents it through SwiftUI and UIKit on iOS.

`KLPageCurlSurface` identifies a page's `front` or `back`. `KLPageCurlSequence` supplies initial and adjacent surfaces, and `KLFinitePageCurlSequence` implements a finite ordered collection. `KLPageCurlStateMachine` tracks committed selection and transitions through `beginTransition(to:)`, `finishTransition`, and `recenter`.

`KLPageCurlConfiguration` combines `KLPageCurlMotionPolicy` with cache behavior. `KLPageCurlPresentation.resolve(for:)` maps reduced motion to `staticPager`. `KLPageCurlPager` is the SwiftUI bridge to `KLPageCurlViewController`.

`KLPageCurlRevisionIndex` returns a `KLPageCurlRefreshDecision` so a host can refresh only changed surfaces. `KLPageCurlCacheConfiguration` and `KLPageCurlCachePlan` describe retained, preloaded, and evicted surfaces. Content, persistence, revision generation, and image loading remain host responsibilities.
