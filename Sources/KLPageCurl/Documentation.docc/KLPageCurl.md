# ``KLPageCurl``

Model and present a double-sided page sequence with stable logical selection.

## The model behind the curl

``KLPageCurlSequence`` defines adjacency between stable page IDs. Each logical
item has a front and back surface, so the forward order is
`front(id)`, `back(id)`, then `front(nextID)`. ``KLFinitePageCurlSequence``
implements this order for a finite collection; custom sequences can derive
adjacency from dates, database IDs, or another domain model.

``KLPageCurlStateMachine`` is the transition reducer. The host sends an intent,
then applies the returned ``KLPageCurlTransitionOutcome`` and settled surface
to its UI coordinator. Selection changes when a front surface settles, not
halfway through a turn. Recenter requests during an active transition are
ignored so visible surface and logical selection cannot diverge.

Use ``KLPageCurlRevisionIndex`` to identify which individual surface changed.
An unchanged revision keeps its host, while a changed revision reloads only
that front or back surface. ``KLPageCurlCacheConfiguration`` measures its
radius in logical items and ``KLPageCurlCachePlan`` describes preload and
eviction work. The host owns the actual controllers and media cache.

## Overview

Each logical item has a front and a back. The forward order is `front(id)`,
`back(id)`, then `front(nextID)`. A completed back turn does not change the
selection binding. Selection changes only after a front settles.

Use ``KLFinitePageCurlSequence`` for a fixed list, or implement
``KLPageCurlSequence`` when adjacency comes from another model. Programmatic
selection asks ``KLPageCurlSequence/initialSurface(for:)`` to choose the new
initial surface—normally the front, but defined by the sequence's policy—and
the state machine accepts that surface in one idle update. A recenter request
made during an active transition is ignored, so the transition origin,
pending surface, cache plan, and visible controller cannot diverge.

The UIKit and SwiftUI curl presentation is available on iOS 17 and later. The
sequence, state-machine, cache, revision, motion, and accessibility models are
available on macOS 14 and later. macOS does not provide a curl view.

### Cache and revisions

``KLPageCurlCacheConfiguration`` measures radius in logical items. A retained
item keeps both surfaces; eager preload creates only missing fronts. The
default radius is one. Revisions belong to individual surfaces. An unchanged
revision keeps its host, a changed revision reloads that surface, and refresh
work waits while a transition is active.

### Motion and assistive access

Set the presentation policy to `reducedMotion` when Reduce Motion applies. The
iOS pager then shows the surface chosen by
``KLPageCurlSequence/initialSurface(for:)`` without a curl animation. Supply
``KLPageCurlAccessibility`` with localized labels, values, announcements, and
previous/next action names. The pager exposes adjustable and custom actions
for VoiceOver and Switch Control while preserving hosted accessibility
children.

The navigation host owns its interactive-pop recognizer and passes it to the
iOS page controller. Page gestures wait for that recognizer to fail. The
package does not choose an edge width or navigation policy.

## Topics

### Sequence model

- ``KLPageCurlSurface``
- ``KLPageCurlDirection``
- ``KLPageCurlSequence``
- ``KLFinitePageCurlSequence``

### Transition model

- ``KLPageCurlStateMachine``
- ``KLPageCurlTransitionState``
- ``KLPageCurlTransitionOutcome``

### Cache and refresh

- ``KLPageCurlCacheConfiguration``
- ``KLPageCurlCachePlan``
- ``KLPageCurlRevisionIndex``
- ``KLPageCurlRefreshDecision``

### Configuration

- ``KLPageCurlConfiguration``
- ``KLPageCurlMotionPolicy``
- ``KLPageCurlPresentation``
- ``KLPageCurlAccessibility``
