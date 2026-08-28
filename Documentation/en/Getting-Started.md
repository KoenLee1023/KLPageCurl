# Getting Started

Use a stable, hashable, sendable ID for each logical item. A finite list can use
`KLFinitePageCurlSequence`; a custom `KLPageCurlSequence` can derive neighbors
from another model. Preserve the order `front(id)`, `back(id)`,
`front(nextID)`, and return `nil` at finite boundaries.

```swift
let sequence = KLFinitePageCurlSequence(orderedIDs: Chapter.allCases)

KLPageCurlPager(
    selection: $selection,
    sequence: sequence,
    revision: revision,
    front: { id, isActive in ChapterFront(id: id, isActive: isActive) },
    back: { id in ChapterNotes(id: id) },
    configuration: .init(
        motionPolicy: reduceMotion ? .reducedMotion : .curl,
        cache: .init(logicalRadius: 1)
    ),
    accessibility: accessibility,
    onSettled: didSettle
)
```

The selection binding represents a settled front, not every visible face.
`onSettled` receives both fronts and backs. Changing the binding asks
`initialSurface(for:)` to choose the initial surface (normally the front, but
policy-defined), and the idle state machine accepts it atomically. Send another
change after settling if a transition was active.

Cache radius counts neighboring IDs. Both faces are retained, but only missing
fronts are preloaded. Give each surface a stable revision. A revision change
reloads that surface when idle; refresh waits during a transition.

Run `BookPreviewDemo` for the basic finite sequence and `PhotoAlbumDemo` for
per-surface revision behavior. Visible curl presentation requires iOS 17. The
model layer supports macOS 14 without a curl control.
