struct KLPageCurlControllerRecenter<ID: Hashable & Sendable>: Sendable {
    let outcome: KLPageCurlTransitionOutcome<ID>
    let cachePlan: KLPageCurlCachePlan<ID>
}

struct KLPageCurlControllerFinish<ID: Hashable & Sendable>: Sendable {
    let transitionOutcome: KLPageCurlTransitionOutcome<ID>
    let recenter: KLPageCurlControllerRecenter<ID>?

    var selectionToCommit: ID? {
        guard recenter == nil else {
            return nil
        }
        guard case .settled(surface: _, selection: let selection) = transitionOutcome else {
            return nil
        }
        return selection
    }
}

struct KLPageCurlControllerState<
    ID: Hashable & Sendable,
    PageSequence: KLPageCurlSequence<ID>
>: Sendable {
    private var sequence: PageSequence
    private var cacheConfiguration: KLPageCurlCacheConfiguration
    private var machine: KLPageCurlStateMachine<ID>
    private var revisionIndex = KLPageCurlRevisionIndex<ID>()
    private var observedSelection: ID
    private var requestedSelection: ID?
    private(set) var cachedSurfaces: Set<KLPageCurlSurface<ID>> = []

    var currentSurface: KLPageCurlSurface<ID> {
        machine.currentSurface
    }

    var currentSelection: ID {
        machine.currentSelection
    }

    var isTransitioning: Bool {
        if case .transitioning = machine.state {
            return true
        }
        return false
    }

    init(
        initialSelection: ID,
        sequence: PageSequence,
        cacheConfiguration: KLPageCurlCacheConfiguration
    ) {
        self.sequence = sequence
        self.cacheConfiguration = cacheConfiguration
        observedSelection = initialSelection
        machine = KLPageCurlStateMachine(
            initialSelection: initialSelection,
            sequence: sequence
        )
    }

    func surface(
        after surface: KLPageCurlSurface<ID>
    ) -> KLPageCurlSurface<ID>? {
        sequence.adjacent(to: surface, direction: .after)
    }

    func surface(
        before surface: KLPageCurlSurface<ID>
    ) -> KLPageCurlSurface<ID>? {
        sequence.adjacent(to: surface, direction: .before)
    }

    func cachePlan() -> KLPageCurlCachePlan<ID> {
        cacheConfiguration.plan(
            around: currentSurface.id,
            sequence: sequence,
            cachedSurfaces: cachedSurfaces
        )
    }

    mutating func didCache<Revision: Hashable & Sendable>(
        _ surface: KLPageCurlSurface<ID>,
        revision: Revision
    ) {
        cachedSurfaces.insert(surface)
        revisionIndex.record(revision, for: surface)
    }

    mutating func didCache(
        _ surface: KLPageCurlSurface<ID>,
        recordRevision: (
            inout KLPageCurlRevisionIndex<ID>,
            KLPageCurlSurface<ID>
        ) -> Void
    ) {
        cachedSurfaces.insert(surface)
        recordRevision(&revisionIndex, surface)
    }

    func refreshDecision<Revision: Hashable & Sendable>(
        revision: Revision,
        surface: KLPageCurlSurface<ID>
    ) -> KLPageCurlRefreshDecision {
        revisionIndex.refreshDecision(
            revision: revision,
            surface: surface,
            isTransitioning: isTransitioning
        )
    }

    func refreshDecision(
        surface: KLPageCurlSurface<ID>,
        decideRevision: (
            KLPageCurlRevisionIndex<ID>,
            KLPageCurlSurface<ID>,
            Bool
        ) -> KLPageCurlRefreshDecision
    ) -> KLPageCurlRefreshDecision {
        decideRevision(revisionIndex, surface, isTransitioning)
    }

    mutating func recenter(
        on selection: ID
    ) -> KLPageCurlControllerRecenter<ID>? {
        let outcome = machine.recenter(on: selection, sequence: sequence)
        guard case .recentered = outcome else {
            return nil
        }

        requestedSelection = nil
        observedSelection = selection
        let plan = cachePlan()
        applyCachePlan(plan)
        return KLPageCurlControllerRecenter(outcome: outcome, cachePlan: plan)
    }

    mutating func requestRecenter(
        on selection: ID
    ) -> KLPageCurlControllerRecenter<ID>? {
        guard selection != observedSelection else {
            return nil
        }
        observedSelection = selection
        guard !isTransitioning else {
            requestedSelection = selection
            return nil
        }
        guard selection != currentSelection else {
            requestedSelection = nil
            return nil
        }
        return recenter(on: selection)
    }

    mutating func applyCachePlan(_ plan: KLPageCurlCachePlan<ID>) {
        revisionIndex.applyEvictions(from: plan)
        cachedSurfaces.subtract(plan.surfacesToEvict)
    }

    @discardableResult
    mutating func update(
        sequence: PageSequence,
        cacheConfiguration: KLPageCurlCacheConfiguration
    ) -> KLPageCurlCachePlan<ID>? {
        self.sequence = sequence
        self.cacheConfiguration = cacheConfiguration

        return replanIfIdle()
    }

    @discardableResult
    mutating func replanIfIdle() -> KLPageCurlCachePlan<ID>? {
        guard !isTransitioning else {
            return nil
        }

        let plan = cachePlan()
        applyCachePlan(plan)
        return plan
    }

    @discardableResult
    mutating func beginTransition(to pending: KLPageCurlSurface<ID>) -> Bool {
        machine.beginTransition(to: pending)
    }

    mutating func finishTransition(
        completed: Bool
    ) -> KLPageCurlTransitionOutcome<ID> {
        machine.finishTransition(completed: completed)
    }

    mutating func finishTransitionAndReconcile(
        completed: Bool
    ) -> KLPageCurlControllerFinish<ID> {
        let transitionOutcome = machine.finishTransition(completed: completed)
        guard case .ignored = transitionOutcome else {
            let selection = requestedSelection
            requestedSelection = nil
            let pendingRecenter: KLPageCurlControllerRecenter<ID>?
            if let selection {
                pendingRecenter = recenter(on: selection)
            } else {
                pendingRecenter = nil
            }
            let finish = KLPageCurlControllerFinish(
                transitionOutcome: transitionOutcome,
                recenter: pendingRecenter
            )
            if let committedSelection = finish.selectionToCommit {
                observedSelection = committedSelection
            }
            return finish
        }

        return KLPageCurlControllerFinish(
            transitionOutcome: transitionOutcome,
            recenter: nil
        )
    }

    mutating func abortTransitionForPresentationChange(
        from currentPresentation: KLPageCurlPresentation?,
        to nextPresentation: KLPageCurlPresentation
    ) -> KLPageCurlControllerFinish<ID>? {
        guard currentPresentation != nextPresentation, isTransitioning else {
            return nil
        }
        return finishTransitionAndReconcile(completed: false)
    }

    mutating func performAccessibilityAction(
        _ action: KLPageCurlAccessibilityAction
    ) -> KLPageCurlControllerRecenter<ID>? {
        let adjacentSurface: KLPageCurlSurface<ID>?
        switch action {
        case .previous:
            adjacentSurface = sequence.adjacent(
                to: .front(currentSelection),
                direction: .before
            )
        case .next:
            adjacentSurface = sequence.adjacent(
                to: .back(currentSelection),
                direction: .after
            )
        }
        guard let adjacentSurface else {
            return nil
        }
        return recenter(on: adjacentSurface.id)
    }
}

struct KLPageCurlHostCache<ID: Hashable & Sendable, Host: AnyObject> {
    private struct Entry {
        let host: Host
        var isActive: Bool
    }

    private var entries: [KLPageCurlSurface<ID>: Entry] = [:]

    mutating func resolve(
        surface: KLPageCurlSurface<ID>,
        isActive: Bool,
        revisionDecision: KLPageCurlRefreshDecision,
        makeHost: (Bool) -> Host,
        updateRoot: (Host, Bool) -> Void,
        didRefresh: () -> Void = {}
    ) -> Host {
        if var entry = entries[surface] {
            let activityChanged = entry.isActive != isActive
            let shouldUpdateRoot: Bool
            switch revisionDecision {
            case .keep:
                shouldUpdateRoot = activityChanged
            case .reload, .create:
                shouldUpdateRoot = true
            case .deferUntilIdle:
                shouldUpdateRoot = false
            }

            if shouldUpdateRoot {
                updateRoot(entry.host, isActive)
                entry.isActive = isActive
                entries[surface] = entry
                didRefresh()
            }
            return entry.host
        }

        let host = makeHost(isActive)
        entries[surface] = Entry(host: host, isActive: isActive)
        didRefresh()
        return host
    }

    func cachedHost(for surface: KLPageCurlSurface<ID>) -> Host? {
        entries[surface]?.host
    }

    func surface(for host: Host) -> KLPageCurlSurface<ID>? {
        entries.first { $0.value.host === host }?.key
    }

    @discardableResult
    mutating func synchronizeFrontActivity(
        activeFront: KLPageCurlSurface<ID>?,
        updateRoot: (KLPageCurlSurface<ID>, Host, Bool) -> Void
    ) -> [KLPageCurlSurface<ID>] {
        let frontSurfaces = entries.keys.filter(\.isFront)
        var refreshedSurfaces: [KLPageCurlSurface<ID>] = []

        for surface in frontSurfaces {
            guard var entry = entries[surface] else {
                continue
            }
            let isActive = surface == activeFront
            guard entry.isActive != isActive else {
                continue
            }

            updateRoot(surface, entry.host, isActive)
            entry.isActive = isActive
            entries[surface] = entry
            refreshedSurfaces.append(surface)
        }

        return refreshedSurfaces
    }

    mutating func apply(plan: KLPageCurlCachePlan<ID>) {
        for surface in plan.surfacesToEvict {
            entries.removeValue(forKey: surface)
        }
    }

    mutating func applyUpdatePlan(
        _ updatePlan: KLPageCurlCachePlan<ID>?,
        presentation: KLPageCurlPresentation,
        isSupersededByRecenter: Bool
    ) -> [KLPageCurlSurface<ID>] {
        guard let updatePlan else {
            return []
        }
        apply(plan: updatePlan)
        guard presentation == .curl, !isSupersededByRecenter else {
            return []
        }
        return updatePlan.surfacesToPreload
    }

    mutating func applyRecenterPlans(
        _ recenters: [KLPageCurlControllerRecenter<ID>?],
        presentation: KLPageCurlPresentation
    ) -> [KLPageCurlSurface<ID>] {
        var surfacesToPreload: [KLPageCurlSurface<ID>] = []
        var scheduledSurfaces: Set<KLPageCurlSurface<ID>> = []
        for case let recenter? in recenters {
            apply(plan: recenter.cachePlan)
            guard presentation == .curl else {
                continue
            }
            for surface in recenter.cachePlan.surfacesToPreload {
                guard scheduledSurfaces.insert(surface).inserted else {
                    continue
                }
                surfacesToPreload.append(surface)
            }
        }
        return surfacesToPreload
    }
}

enum KLPageCurlGesturePriority {
    static func install<PageGesture, PopGesture>(
        pageGestures: [PageGesture],
        popGesture: PopGesture,
        requireFailure: (PageGesture, PopGesture) -> Void
    ) {
        for pageGesture in pageGestures {
            requireFailure(pageGesture, popGesture)
        }
    }
}
