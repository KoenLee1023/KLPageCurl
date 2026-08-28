/// A bounded logical-page cache policy.
public struct KLPageCurlCacheConfiguration: Hashable, Sendable {
    /// The largest supported number of logical neighbors retained on each side.
    public static let maximumLogicalRadius = 8

    /// The number of logical neighbors retained before and after the center.
    public let logicalRadius: Int

    /// Creates a cache policy with a radius from zero through eight.
    ///
    /// - Parameter logicalRadius: The number of logical neighbors to retain on
    ///   each available side of the center.
    /// - Precondition: `logicalRadius` is nonnegative and no greater than
    ///   ``maximumLogicalRadius``.
    public init(logicalRadius: Int) {
        precondition(logicalRadius >= 0, "logicalRadius must be nonnegative")
        precondition(
            logicalRadius <= Self.maximumLogicalRadius,
            "logicalRadius exceeds the supported maximum"
        )
        self.logicalRadius = logicalRadius
    }

    /// Plans retained, preloaded, and evicted surfaces around a logical center.
    ///
    /// Navigation walks the supplied sequence rather than deriving identifiers.
    /// Both surfaces are retained for each logical item, while only uncached front
    /// surfaces are proposed for eager preload.
    ///
    /// - Parameters:
    ///   - center: The logical item at the center of the retained window.
    ///   - sequence: The source of neighboring logical items and finite ends.
    ///   - cachedSurfaces: Existing cached surfaces. The default is empty.
    /// - Returns: A deterministic retain, preload, and eviction plan.
    public func plan<ID: Hashable & Sendable>(
        around center: ID,
        sequence: some KLPageCurlSequence<ID>,
        cachedSurfaces: Set<KLPageCurlSurface<ID>> = []
    ) -> KLPageCurlCachePlan<ID> {
        let logicalIDs = logicalWindow(around: center, sequence: sequence)
        var retainedSurfaces: [KLPageCurlSurface<ID>] = []
        retainedSurfaces.reserveCapacity(logicalIDs.count * 2)

        for id in logicalIDs {
            retainedSurfaces.append(.front(id))
            retainedSurfaces.append(.back(id))
        }

        let retainedSet = Set(retainedSurfaces)
        let surfacesToPreload = logicalIDs.compactMap { id in
            let front = KLPageCurlSurface.front(id)
            return cachedSurfaces.contains(front) ? nil : front
        }

        return KLPageCurlCachePlan(
            retainedSurfaces: retainedSurfaces,
            surfacesToPreload: surfacesToPreload,
            surfacesToEvict: cachedSurfaces.subtracting(retainedSet)
        )
    }

    private func logicalWindow<ID: Hashable & Sendable>(
        around center: ID,
        sequence: some KLPageCurlSequence<ID>
    ) -> [ID] {
        var seen: Set<ID> = [center]
        var precedingIDs: [ID] = []
        var cursor = center

        for _ in 0..<logicalRadius {
            guard
                let preceding = sequence.adjacent(to: .front(cursor), direction: .before),
                seen.insert(preceding.id).inserted
            else {
                break
            }
            precedingIDs.append(preceding.id)
            cursor = preceding.id
        }

        var followingIDs: [ID] = []
        cursor = center
        for _ in 0..<logicalRadius {
            guard
                let following = sequence.adjacent(to: .back(cursor), direction: .after),
                seen.insert(following.id).inserted
            else {
                break
            }
            followingIDs.append(following.id)
            cursor = following.id
        }

        return precedingIDs.reversed() + [center] + followingIDs
    }
}

/// A deterministic cache-membership decision for one logical center.
public struct KLPageCurlCachePlan<ID: Hashable & Sendable>: Sendable {
    /// Both surfaces for every logical item inside the configured window.
    public let retainedSurfaces: [KLPageCurlSurface<ID>]

    /// Uncached front surfaces eligible for eager creation.
    public let surfacesToPreload: [KLPageCurlSurface<ID>]

    /// Previously cached surfaces outside the new retained window.
    public let surfacesToEvict: Set<KLPageCurlSurface<ID>>

    init(
        retainedSurfaces: [KLPageCurlSurface<ID>],
        surfacesToPreload: [KLPageCurlSurface<ID>],
        surfacesToEvict: Set<KLPageCurlSurface<ID>>
    ) {
        self.retainedSurfaces = retainedSurfaces
        self.surfacesToPreload = surfacesToPreload
        self.surfacesToEvict = surfacesToEvict
    }
}

/// The action required when comparing a surface's cached and current revisions.
public enum KLPageCurlRefreshDecision: Hashable, Sendable {
    /// Keep the cached surface because its revision is unchanged.
    case keep

    /// Rebuild the cached surface because its revision changed.
    case reload

    /// Create the surface because no revision has been recorded.
    case create

    /// Delay revision work until the active transition becomes idle.
    case deferUntilIdle
}

/// Tracks opaque, host-supplied revisions independently for each cached surface.
public struct KLPageCurlRevisionIndex<ID: Hashable & Sendable>: Sendable {
    private var revisions: [KLPageCurlSurface<ID>: KLPageCurlRevisionValue] = [:]

    var recordedSurfaceCount: Int {
        revisions.count
    }

    /// Creates an empty revision index with no recorded surfaces.
    public init() {}

    /// Records the revision represented by a newly created or reloaded surface.
    ///
    /// - Parameters:
    ///   - revision: The host's stable revision value.
    ///   - surface: The surface whose host now represents that revision.
    public mutating func record<Revision: Hashable & Sendable>(
        _ revision: Revision,
        for surface: KLPageCurlSurface<ID>
    ) {
        revisions[surface] = KLPageCurlRevisionValue(revision)
    }

    /// Removes revision entries for every surface evicted by a cache plan.
    ///
    /// Apply this operation when committing the corresponding controller-cache
    /// eviction so a later recreation cannot reuse a stale revision decision.
    ///
    /// - Parameter plan: The cache plan whose eviction set was applied.
    public mutating func applyEvictions(from plan: KLPageCurlCachePlan<ID>) {
        for surface in plan.surfacesToEvict {
            revisions.removeValue(forKey: surface)
        }
    }

    /// Compares a host revision with the cached revision for one surface.
    ///
    /// Active transitions always defer refresh work, preventing a visible host
    /// controller from being replaced in flight. Revisions match only when both
    /// their concrete types and values are equal.
    ///
    /// - Parameters:
    ///   - revision: The revision currently supplied by the host.
    ///   - surface: The surface being compared.
    ///   - isTransitioning: Whether a page transition is active.
    /// - Returns: Whether to keep, reload, create, or defer the surface.
    public func refreshDecision<Revision: Hashable & Sendable>(
        revision: Revision,
        surface: KLPageCurlSurface<ID>,
        isTransitioning: Bool
    ) -> KLPageCurlRefreshDecision {
        guard !isTransitioning else {
            return .deferUntilIdle
        }
        guard let existing = revisions[surface] else {
            return .create
        }
        return existing.matches(revision) ? .keep : .reload
    }
}

private struct KLPageCurlRevisionValue: Sendable {
    private let matchesValue: @Sendable (any Sendable) -> Bool

    init<Revision: Hashable & Sendable>(_ revision: Revision) {
        matchesValue = { candidate in
            guard let candidate = candidate as? Revision else {
                return false
            }
            return candidate == revision
        }
    }

    func matches<Revision: Hashable & Sendable>(_ revision: Revision) -> Bool {
        matchesValue(revision)
    }
}
