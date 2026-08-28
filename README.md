# KLPageCurl

`KLPageCurl` models a double-sided page sequence and presents it through a SwiftUI and UIKit page-curl pager on iOS. The sequence, transition state, revision tracking, cache planning, and accessibility values are separate APIs, so an application can use the model without adopting the pager view.

## Sequence model

Each logical item exposes two surfaces in order: `front(id)` and `back(id)`. `KLFinitePageCurlSequence` also supplies the adjacent surface for the next or previous ID.

```swift
let sequence = KLFinitePageCurlSequence(orderedIDs: ["one", "two", "three"])
let machine = KLPageCurlStateMachine(
    sequence: sequence,
    initialSelection: "one"
)
```

`KLPageCurlSurface` identifies the logical ID and whether the surface is front or back. A completed front transition updates the selection to its ID. A completed back transition calls the settled callback without changing the logical selection. This keeps a double-sided item from being selected twice.

## State and recentering

`KLPageCurlStateMachine` exposes `currentSelection`, `currentSurface`, and a transition state. `beginTransition(to:)` accepts a pending surface only while idle. `finishTransition` commits or cancels the transition. `recenter` synchronizes the state machine with a programmatic selection while it is idle. A recenter request during an active transition is ignored rather than changing the transition origin.

## Cache and revisions

`KLPageCurlCacheConfiguration` defines a logical radius. `KLPageCurlCachePlan` reports retained surfaces, surfaces to preload, and surfaces to evict. `KLPageCurlRevisionIndex` records host revisions and returns a `KLPageCurlRefreshDecision`, which lets the host refresh only a changed front or back surface.

`KLPageCurlConfiguration` combines motion policy, presentation, and cache behavior. `KLPageCurlMotionPolicy` provides the reduced-motion decision. `KLPageCurlAccessibility` supplies labels, values, announcements, and action names without hard-coding application language.

## Pager integration

`KLPageCurlPager` is the SwiftUI bridge. It creates a `KLPageCurlViewController` on iOS and updates the existing controller as selection, revisions, and configuration change. The UIKit controller can give the interactive pop gesture priority through `installInteractivePopPriority(using:)`.

macOS supports the sequence, transition, cache, revision, motion, and accessibility model APIs. It does not provide the iOS page-curl UI.

## Installation

```swift
dependencies: [
    .package(
        url: "https://github.com/KoenLee1023/KLPageCurl.git",
        from: "0.1.0"
    )
]
```

## Demos

- [Book preview demo](Examples/BookPreviewDemo/README.md)
- [Photo album demo](Examples/PhotoAlbumDemo/README.md)

## Boundaries

The package does not own page content, navigation state, persistence, revision generation, or image loading. The integrating application supplies those values and decides what a surface renders.

## Requirements

- iOS 17 or later for SwiftUI and UIKit pager UI
- macOS 14 or later for model APIs
- Swift 6.0 or later
- MIT License

API Documentation: [DocC](https://labs.wondays.space/documentation/en/klpagecurl)
