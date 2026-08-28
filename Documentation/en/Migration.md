# Migration

Map the existing logical page identity to `ID`, then describe both faces with a
`KLPageCurlSequence`. Do not update application selection when the back settles.
Wait for the next front. Move surface-specific content versions into the
`revision` closure so a front edit does not rebuild its back.

Replace delayed controller resets with one programmatic selection update.
While idle, KLPageCurl asks `initialSurface(for:)` for the initial surface
(normally the front, but policy-defined); the state machine accepts it while
the visible controller and cache plan are updated together. It ignores a
recenter during an active transition, leaving the current transition intact.

Choose a logical cache radius from zero through eight. Radius one is the
default and retains both faces for the center and one available neighbor on
each side. Controllers outside the new window are evicted; revision refreshes
wait until the transition is idle.

Keep navigation policy in the host. Pass the navigation controller's
interactive-pop recognizer to the page controller. The package makes page
gestures wait for it but does not choose an edge width.

Translate the host's Reduce Motion setting to `reducedMotion`, which displays
the surface chosen by `initialSurface(for:)` (normally the front, but
policy-defined) without a curl. Supply localized accessibility labels,
values, announcements, and previous/next names for VoiceOver and Switch
Control. Compare `BookPreviewDemo` for finite migration and `PhotoAlbumDemo`
for revision-driven content. Curl UI starts at iOS 17; macOS 14 exposes only
the model APIs.
