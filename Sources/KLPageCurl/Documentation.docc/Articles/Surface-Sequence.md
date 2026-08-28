# Surface Sequence

Define the physical order of front and back surfaces without coupling page IDs
to integers or dates.

## Order both sides

A logical item contributes two surfaces. ``KLFinitePageCurlSequence`` follows
this order:

1. Moving after `front(id)` reaches `back(id)`.
2. Moving after `back(id)` reaches `front(nextID)`.
3. Moving before `front(id)` reaches `back(previousID)`.
4. Moving before `back(id)` reaches `front(id)`.

The first front has no preceding surface, and the last back has no following
surface. A custom ``KLPageCurlSequence`` returns `nil` at its own finite
boundaries.

```swift
enum PageID: String, CaseIterable, Hashable, Sendable {
    case cover, contents, chapter
}

let sequence = KLFinitePageCurlSequence(orderedIDs: PageID.allCases)
let next = sequence.adjacent(to: .front(.cover), direction: .after)
// next == .back(.cover)
```

## Keep selection logical

The current surface and logical selection are related but not identical. A
completed back surface reports `nil` for its selection change. A completed
front reports its ID. This lets a binding represent the current logical item
without changing halfway through a front/back pair.

The iOS pager calls its settled callback for both faces. Use that callback for
surface-specific work, and use the selection binding for the settled front.

## Try the demos

`BookPreviewDemo` shows a finite chapter sequence and the selection contract.
`PhotoAlbumDemo` adds independent front and back revisions to a finite photo
sequence. Both demo packages require iOS 17 for the visible curl. The model APIs
can be built on macOS 14.
