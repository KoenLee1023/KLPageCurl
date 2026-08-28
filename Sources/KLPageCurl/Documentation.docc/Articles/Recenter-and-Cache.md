# Recenter and Cache

Keep programmatic selection, visible controllers, and cached content on the
same logical center.

## Recenter in one idle update

``KLPageCurlStateMachine`` recenters only while idle. A successful recenter
asks ``KLPageCurlSequence/initialSurface(for:)`` for the selected item's
initial surface. That is normally `front(selection)`, but a sequence defines
the policy and may choose another surface. The state machine accepts the
returned surface and commits the selection in one reducer call. The iOS
coordinator replans its cache and replaces the visible controller before
another neighbor lookup.

If a transition is active, recenter returns `ignored` and leaves the origin,
pending surface, and selection unchanged. Send the desired selection again
after the transition settles if the host still needs it.

## Set the cache radius

``KLPageCurlCacheConfiguration`` accepts a logical radius from zero through
eight. The default ``KLPageCurlConfiguration`` uses radius one. Radius one
retains the center item and one available neighbor on each side. Both fronts
and backs are retained for every item in that window. Only missing fronts are
listed for preload, and cached surfaces outside the window are listed for
eviction.

The planner walks ``KLPageCurlSequence`` adjacency, so IDs need no arithmetic
relationship.

## Revise one surface

Pass a stable, hashable revision for each surface. ``KLPageCurlRevisionIndex``
returns:

- `create` when the surface has no recorded revision;
- `keep` when the recorded type and value match;
- `reload` when either the revision type or value changed;
- `deferUntilIdle` while a transition is active.

Record a revision after creating or reloading its host. Apply cache evictions
to the revision index at the same time as controller eviction. A front edit can
therefore reload only the front while leaving the back host intact, as shown in
`PhotoAlbumDemo`.
