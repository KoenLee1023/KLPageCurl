# Accessibility

The host supplies all user-facing accessibility text through
`KLPageCurlAccessibility`. Give front and back distinct values, separate
settle announcements, and localized previous/next action names.

On iOS 17, the pager provides adjustable increment/decrement and custom
previous/next actions. VoiceOver and Switch Control traverse the same
front/back sequence as page gestures. Selection still changes only on a
settled front, while `onSettled` reports both faces. Hosted buttons, fields,
and other accessibility children remain available.

When Reduce Motion applies, pass `reducedMotion`. The static presentation asks
`initialSurface(for:)` for the initial surface (normally the front, but
policy-defined) and accepts it directly when selection changes; it does not
animate through an intermediate surface. Cache radius and per-surface revisions
retain the same meaning, and revision refresh still waits until transitions are idle.

The navigation host owns interactive pop and passes its recognizer to the page
controller. Page gestures defer to that recognizer; KLPageCurl does not own the
edge threshold. `BookPreviewDemo` shows named page actions. `PhotoAlbumDemo`
shows editable accessibility descendants in curl and static presentations.
macOS 14 can use the accessibility and motion models but has no curl UI.
