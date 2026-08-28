# ``KLPageCurl``

KLPageCurl models a double-sided sequence and provides an iOS page-curl view.

Each logical item appears as `front(id)` followed by `back(id)`. Moving forward
from that back reaches `front(nextID)`; reverse movement follows the same order
backward. Finite sequences return `nil` before the first front and after the
last back. Selection changes only when a front has finished settling. A settled
back still calls `onSettled`, but it does not write a new selection.

A programmatic selection asks `initialSurface(for:)` for its initial surface
(normally the selected front, but defined by sequence policy); the idle state
machine accepts that surface in one update. If a transition is active, the request is ignored without partly
changing transition or cache state. Cache radius counts logical items and keeps
both faces in the retained window; the default radius is one. Revisions are
surface-specific. Changed content reloads only that surface after the pager is
idle, while an active transition defers refresh work.

The navigation host owns interactive pop, including its recognizer and edge
policy. Page gestures only wait for the supplied pop recognizer. For Reduce
Motion, pass `reducedMotion`; the pager shows the surface chosen by
`initialSurface(for:)` statically (normally the front, but policy-defined).
Provide `KLPageCurlAccessibility` text so VoiceOver and Switch Control can use
adjustable and named previous/next actions. Hosted controls remain accessible.

`BookPreviewDemo` shows a finite book. `PhotoAlbumDemo` shows independent front
and back revisions with editable content. The curl view requires iOS 17. The
sequence, state-machine, cache, revision, motion, and accessibility models are
available on macOS 14; macOS has no curl view.

## Topics

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
