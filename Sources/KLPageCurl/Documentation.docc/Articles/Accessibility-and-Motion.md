# Accessibility and Motion

Choose presentation policy in the host and provide localized assistive text.

## Respect Reduce Motion

``KLPageCurlMotionPolicy`` does not inspect system settings. The host reads its
environment and passes `reducedMotion` when a curl is inappropriate. On iOS 17
and later, reduced motion displays the surface chosen by
``KLPageCurlSequence/initialSurface(for:)`` as a static presentation. That
surface is normally the front, but sequence policy defines it. Programmatic
selection accepts it directly without animating through an intermediate surface.

The curl UI is iOS-only. On macOS 14 and later, use the sequence, transition,
cache, revision, and policy models without a visible page-curl control.

## Supply accessibility content

Create ``KLPageCurlAccessibility`` with host-localized content for each ID and
surface. Front and back values should remain distinguishable. Provide separate
settle announcements and names for the logical previous and next actions.

On iOS, the pager exposes adjustable increment/decrement and custom previous
and next actions. VoiceOver and Switch Control can therefore move through the
same sequence without performing a curl gesture. Hosted controls remain in the
accessibility hierarchy.

## Leave navigation ownership with the host

The navigation controller owns interactive pop. Pass its recognizer to the
iOS page controller so every page gesture requires that recognizer to fail.
KLPageCurl does not define an edge threshold, install a navigation recognizer,
or decide when the navigation stack may pop.

`BookPreviewDemo` shows localized action wiring for a finite book.
`PhotoAlbumDemo` also keeps editable descendants available in curl and static
presentations.
