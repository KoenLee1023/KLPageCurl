import Testing
@testable import KLPageCurl

@Suite struct KLPageCurlCoordinatorTests {
    private final class Host {
        var isActive: Bool

        init(isActive: Bool) {
            self.isActive = isActive
        }
    }

    private let sequence = KLFinitePageCurlSequence(orderedIDs: [1, 2, 3, 4])

    @Test func `presentation change aborts transition before static actions`() throws {
        var state = KLPageCurlControllerState(
            initialSelection: 2,
            sequence: sequence,
            cacheConfiguration: .init(logicalRadius: 1)
        )

        state.beginTransition(to: .front(3))
        #expect(state.requestRecenter(on: 4) == nil)

        let abortResult = state.abortTransitionForPresentationChange(
            from: .curl,
            to: .staticPager
        )
        let abort = try #require(abortResult)
        let externalRecenter = try #require(abort.recenter)

        #expect(abort.transitionOutcome == .cancelled(surface: .front(2)))
        #expect(!state.isTransitioning)
        #expect(
            externalRecenter.outcome == .recentered(
                surface: .front(4),
                selection: 4
            )
        )

        let previousResult = state.performAccessibilityAction(.previous)
        let previous = try #require(previousResult)
        #expect(previous.outcome == .recentered(surface: .front(3), selection: 3))

        let nextResult = state.performAccessibilityAction(.next)
        let next = try #require(nextResult)
        #expect(next.outcome == .recentered(surface: .front(4), selection: 4))

        let programmaticResult = state.requestRecenter(on: 1)
        let programmatic = try #require(programmaticResult)
        #expect(
            programmatic.outcome == .recentered(
                surface: .front(1),
                selection: 1
            )
        )
        #expect(!state.isTransitioning)
    }

    @Test func `radius zero reverse turn retains visible back and navigation`() throws {
        var state = KLPageCurlControllerState(
            initialSelection: 2,
            sequence: sequence,
            cacheConfiguration: .init(logicalRadius: 0)
        )
        var hosts = KLPageCurlHostCache<Int, Host>()
        for surface in [
            KLPageCurlSurface.front(2),
            .back(2),
            .back(1),
        ] {
            state.didCache(surface, revision: "current")
            _ = hosts.resolve(
                surface: surface,
                isActive: surface == .front(2),
                revisionDecision: .create,
                makeHost: Host.init,
                updateRoot: { host, isActive in host.isActive = isActive }
            )
        }
        let visibleHost = try #require(hosts.cachedHost(for: .back(1)))

        state.beginTransition(to: .back(1))
        _ = state.finishTransition(completed: true)
        let plan = state.cachePlan()
        state.applyCachePlan(plan)
        hosts.apply(plan: plan)

        #expect(plan.retainedSurfaces == [.front(1), .back(1)])
        #expect(hosts.cachedHost(for: .back(1)) === visibleHost)
        #expect(state.surface(before: .back(1)) == .front(1))
        #expect(state.surface(after: .back(1)) == .front(2))
    }

    @Test func `external selection during cancelled turn recenters after cancellation`() throws {
        var state = KLPageCurlControllerState(
            initialSelection: 2,
            sequence: sequence,
            cacheConfiguration: .init(logicalRadius: 1)
        )

        state.beginTransition(to: .back(2))
        #expect(state.requestRecenter(on: 4) == nil)
        let finish = state.finishTransitionAndReconcile(completed: false)
        let recenter = try #require(finish.recenter)

        #expect(finish.transitionOutcome == .cancelled(surface: .front(2)))
        #expect(finish.selectionToCommit == nil)
        #expect(recenter.outcome == .recentered(surface: .front(4), selection: 4))
        #expect(state.currentSurface == .front(4))
        #expect(state.currentSelection == 4)
    }

    @Test func `external selection wins over completed gesture selection`() throws {
        var state = KLPageCurlControllerState(
            initialSelection: 2,
            sequence: sequence,
            cacheConfiguration: .init(logicalRadius: 1)
        )

        state.beginTransition(to: .front(3))
        #expect(state.requestRecenter(on: 4) == nil)
        let finish = state.finishTransitionAndReconcile(completed: true)
        let recenter = try #require(finish.recenter)

        #expect(
            finish.transitionOutcome == .settled(
                surface: .front(3),
                selection: 3
            )
        )
        #expect(finish.selectionToCommit == nil)
        #expect(recenter.outcome == .recentered(surface: .front(4), selection: 4))
        #expect(state.currentSurface == .front(4))
        #expect(state.currentSelection == 4)
    }

    @Test func `latest external selection may return to current during gesture`() throws {
        var state = KLPageCurlControllerState(
            initialSelection: 2,
            sequence: sequence,
            cacheConfiguration: .init(logicalRadius: 1)
        )

        state.beginTransition(to: .front(3))
        #expect(state.requestRecenter(on: 4) == nil)
        #expect(state.requestRecenter(on: 2) == nil)
        let finish = state.finishTransitionAndReconcile(completed: true)
        let recenter = try #require(finish.recenter)

        #expect(
            finish.transitionOutcome == .settled(
                surface: .front(3),
                selection: 3
            )
        )
        #expect(finish.selectionToCommit == nil)
        #expect(recenter.outcome == .recentered(surface: .front(2), selection: 2))
        #expect(state.currentSurface == .front(2))
        #expect(state.currentSelection == 2)
    }

    @Test func `unchanged observed selection does not cancel completed gesture`() {
        var state = KLPageCurlControllerState(
            initialSelection: 2,
            sequence: sequence,
            cacheConfiguration: .init(logicalRadius: 1)
        )

        state.beginTransition(to: .front(3))
        #expect(state.requestRecenter(on: 2) == nil)
        let finish = state.finishTransitionAndReconcile(completed: true)

        #expect(finish.recenter == nil)
        #expect(finish.selectionToCommit == 3)
        #expect(state.currentSurface == .front(3))
        #expect(state.currentSelection == 3)
    }

    @Test func `settled callback reset is recognized as new external intent`() throws {
        var state = KLPageCurlControllerState(
            initialSelection: 2,
            sequence: sequence,
            cacheConfiguration: .init(logicalRadius: 1)
        )
        var binding = 2
        var events: [String] = []

        state.beginTransition(to: .front(3))
        let finish = state.finishTransitionAndReconcile(completed: true)
        let committedSelection = try #require(finish.selectionToCommit)
        binding = committedSelection
        events.append("binding 3")

        let onSettled = { (surface: KLPageCurlSurface<Int>) in
            #expect(surface == .front(3))
            events.append("settled front 3")
            binding = 2
            events.append("binding 2")
        }
        onSettled(.front(3))

        let recenter = state.requestRecenter(on: binding)
        let update = try #require(recenter)

        #expect(events == ["binding 3", "settled front 3", "binding 2"])
        #expect(update.outcome == .recentered(surface: .front(2), selection: 2))
        #expect(binding == 2)
        #expect(state.currentSurface == .front(2))
        #expect(state.currentSelection == 2)
    }

    @Test func `preloaded front becomes active without replacing its host`() {
        var hosts = KLPageCurlHostCache<Int, Host>()
        let preloaded = hosts.resolve(
            surface: .front(2),
            isActive: false,
            revisionDecision: .create,
            makeHost: Host.init,
            updateRoot: { host, isActive in host.isActive = isActive }
        )

        let current = hosts.resolve(
            surface: .front(2),
            isActive: true,
            revisionDecision: .keep,
            makeHost: Host.init,
            updateRoot: { host, isActive in host.isActive = isActive }
        )

        #expect(current === preloaded)
        #expect(current.isActive)
    }

    @Test func `retained previous front becomes inactive without host replacement`() throws {
        var state = KLPageCurlControllerState(
            initialSelection: 2,
            sequence: sequence,
            cacheConfiguration: .init(logicalRadius: 1)
        )
        var hosts = KLPageCurlHostCache<Int, Host>()
        let first = hosts.resolve(
            surface: .front(1),
            isActive: false,
            revisionDecision: .create,
            makeHost: Host.init,
            updateRoot: { host, isActive in host.isActive = isActive }
        )
        let previous = hosts.resolve(
            surface: .front(2),
            isActive: true,
            revisionDecision: .create,
            makeHost: Host.init,
            updateRoot: { host, isActive in host.isActive = isActive }
        )
        let current = hosts.resolve(
            surface: .front(3),
            isActive: false,
            revisionDecision: .create,
            makeHost: Host.init,
            updateRoot: { host, isActive in host.isActive = isActive }
        )

        state.beginTransition(to: .back(2))
        _ = state.finishTransition(completed: true)
        _ = hosts.synchronizeFrontActivity(
            activeFront: nil,
            updateRoot: { _, host, isActive in host.isActive = isActive }
        )
        state.beginTransition(to: .front(3))
        _ = state.finishTransition(completed: true)
        _ = hosts.synchronizeFrontActivity(
            activeFront: .front(3),
            updateRoot: { _, host, isActive in host.isActive = isActive }
        )

        let retainedPrevious = try #require(hosts.cachedHost(for: .front(2)))
        let retainedCurrent = try #require(hosts.cachedHost(for: .front(3)))
        #expect(retainedPrevious === previous)
        #expect(retainedCurrent === current)
        #expect(!retainedPrevious.isActive)
        #expect(retainedCurrent.isActive)
        #expect(
            [first, retainedPrevious, retainedCurrent].count(where: \.isActive) == 1
        )
    }

    @Test func `idle sequence and cache update evicts stale state immediately`() throws {
        var state = KLPageCurlControllerState(
            initialSelection: 2,
            sequence: sequence,
            cacheConfiguration: .init(logicalRadius: 1)
        )
        var hosts = KLPageCurlHostCache<Int, Host>()
        let cachedSurfaces: [KLPageCurlSurface<Int>] = [
            .front(1), .back(1),
            .front(2), .back(2),
            .front(3), .back(3),
            .front(4),
        ]
        for surface in cachedSurfaces {
            state.didCache(surface, revision: "current")
            _ = hosts.resolve(
                surface: surface,
                isActive: surface == .front(2),
                revisionDecision: .create,
                makeHost: Host.init,
                updateRoot: { host, isActive in host.isActive = isActive }
            )
        }
        let visibleHost = try #require(hosts.cachedHost(for: .front(2)))

        let update = state.update(
            sequence: KLFinitePageCurlSequence(orderedIDs: [2, 3, 4]),
            cacheConfiguration: .init(logicalRadius: 0)
        )
        let plan = try #require(update)
        hosts.apply(plan: plan)

        #expect(plan.retainedSurfaces == [.front(2), .back(2)])
        #expect(hosts.cachedHost(for: .front(2)) === visibleHost)
        #expect(hosts.cachedHost(for: .front(1)) == nil)
        #expect(hosts.cachedHost(for: .front(4)) == nil)
        #expect(
            state.refreshDecision(
                revision: "current",
                surface: .front(1)
            ) == .create
        )
        #expect(
            state.refreshDecision(
                revision: "current",
                surface: .front(2)
            ) == .keep
        )
        #expect(state.currentSurface == .front(2))
        #expect(state.currentSelection == 2)
        #expect(state.surface(before: .front(2)) == nil)
    }

    @Test func `programmatic recenter evicts controller revisions before refresh`() throws {
        var state = KLPageCurlControllerState(
            initialSelection: 2,
            sequence: sequence,
            cacheConfiguration: .init(logicalRadius: 1)
        )
        for surface in state.cachePlan().retainedSurfaces {
            state.didCache(surface, revision: "current")
        }

        let recenter = state.recenter(on: 3)
        let update = try #require(recenter)

        #expect(update.cachePlan.surfacesToEvict == Set([.front(1), .back(1)]))
        #expect(
            state.refreshDecision(
                revision: "current",
                surface: .front(1)
            ) == .create
        )
        #expect(
            state.refreshDecision(
                revision: "current",
                surface: .front(2)
            ) == .keep
        )
    }

    @Test func `programmatic selection recenters before next neighbor lookup`() throws {
        var state = KLPageCurlControllerState(
            initialSelection: 1,
            sequence: sequence,
            cacheConfiguration: .init(logicalRadius: 1)
        )

        let recenter = state.recenter(on: 4)
        let update = try #require(recenter)

        #expect(update.outcome == .recentered(surface: .front(4), selection: 4))
        #expect(state.currentSurface == .front(4))
        #expect(state.surface(after: .front(4)) == .back(4))
    }

    @Test func `controller transitions preserve cancellation and front commit semantics`() {
        var state = KLPageCurlControllerState(
            initialSelection: 2,
            sequence: sequence,
            cacheConfiguration: .init(logicalRadius: 1)
        )

        let didBeginCancelledTurn = state.beginTransition(to: .back(2))
        let cancelled = state.finishTransition(completed: false)
        #expect(didBeginCancelledTurn)
        #expect(cancelled == .cancelled(surface: .front(2)))
        #expect(state.currentSurface == .front(2))

        let didBeginBack = state.beginTransition(to: .back(2))
        let settledBack = state.finishTransition(completed: true)
        #expect(didBeginBack)
        #expect(settledBack == .settled(surface: .back(2), selection: nil))
        #expect(state.currentSelection == 2)

        let didBeginFront = state.beginTransition(to: .front(3))
        let settledFront = state.finishTransition(completed: true)
        #expect(didBeginFront)
        #expect(settledFront == .settled(surface: .front(3), selection: 3))
        #expect(state.currentSelection == 3)
    }

    @Test func `every page gesture yields to interactive pop`() {
        var pageGestures: [Int] = []

        KLPageCurlGesturePriority.install(
            pageGestures: [1, 2, 3],
            popGesture: 9,
            requireFailure: { pageGesture, popGesture in
                #expect(popGesture == 9)
                pageGestures.append(pageGesture)
            }
        )

        #expect(pageGestures == [1, 2, 3])
    }
}
