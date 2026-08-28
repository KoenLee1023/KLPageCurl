import Testing
@testable import KLPageCurl

@Suite struct KLPageCurlHostLifecycleTests {
    private typealias State = KLPageCurlControllerState<
        Int,
        KLFinitePageCurlSequence<Int>
    >

    private final class Host {
        let surface: KLPageCurlSurface<Int>
        var isActive: Bool

        init(surface: KLPageCurlSurface<Int>, isActive: Bool) {
            self.surface = surface
            self.isActive = isActive
        }
    }

    private let sequence = KLFinitePageCurlSequence(orderedIDs: [1, 2, 3, 4])
    private let allSurfaces: [KLPageCurlSurface<Int>] = [
        .front(1), .back(1),
        .front(2), .back(2),
        .front(3), .back(3),
        .front(4), .back(4),
    ]

    @Test func `static recenter evicts curl hosts without preloading across cycles`() throws {
        var state = makeState()
        var hosts = KLPageCurlHostCache<Int, Host>()
        var hostCreations = 0
        cacheCurlHosts(
            for: 2,
            state: &state,
            hosts: &hosts,
            hostCreations: &hostCreations
        )
        var maximumHostCount = cachedHostCount(in: hosts)
        var currentID = 2

        for nextID in [3, 4, 1, 2, 3] {
            let recenterResult = state.requestRecenter(on: nextID)
            let recenter = try #require(recenterResult)
            let creationsBeforeStaticRecenter = hostCreations

            let staticPreloads = hosts.applyRecenterPlans(
                [recenter],
                presentation: .staticPager
            )

            #expect(hosts.cachedHost(for: .front(currentID)) == nil)
            #expect(hosts.cachedHost(for: .back(currentID)) == nil)
            #expect(cachedHostCount(in: hosts) == 0)
            #expect(staticPreloads.isEmpty)
            #expect(hostCreations == creationsBeforeStaticRecenter)

            let curlPreloads = hosts.applyRecenterPlans(
                [recenter],
                presentation: .curl
            )
            #expect(curlPreloads == [.front(nextID)])

            cacheCurlHosts(
                for: nextID,
                state: &state,
                hosts: &hosts,
                hostCreations: &hostCreations
            )
            let hostCount = cachedHostCount(in: hosts)
            maximumHostCount = max(maximumHostCount, hostCount)
            #expect(hostCount == 2)
            currentID = nextID
        }

        #expect(maximumHostCount == 2)
    }

    @Test func `simultaneous idle selection and policy change commits direct recenter`() throws {
        var state = makeState()
        var hosts = KLPageCurlHostCache<Int, Host>()
        var hostCreations = 0
        cacheCurlHosts(
            for: 2,
            state: &state,
            hosts: &hosts,
            hostCreations: &hostCreations
        )

        let directRecenter = state.requestRecenter(on: 3)
        let transitionAbort = state.abortTransitionForPresentationChange(
            from: .curl,
            to: .staticPager
        )
        let direct = try #require(directRecenter)
        let creationsBeforePolicyChange = hostCreations

        let staticPreloads = hosts.applyRecenterPlans(
            [directRecenter, transitionAbort?.recenter],
            presentation: .staticPager
        )

        #expect(transitionAbort == nil)
        #expect(
            direct.outcome == .recentered(
                surface: .front(3),
                selection: 3
            )
        )
        #expect(hosts.cachedHost(for: .front(2)) == nil)
        #expect(hosts.cachedHost(for: .back(2)) == nil)
        #expect(cachedHostCount(in: hosts) == 0)
        #expect(staticPreloads.isEmpty)
        #expect(hostCreations == creationsBeforePolicyChange)
    }

    @Test func `update evictions precede recenter across repeated presentation cycles`() throws {
        var state = makeState(logicalRadius: 0)
        var hosts = KLPageCurlHostCache<Int, Host>()
        var hostCreations = 0
        cacheCurlHosts(
            for: 2,
            state: &state,
            hosts: &hosts,
            hostCreations: &hostCreations
        )

        for nextID in [3, 2, 3, 2] {
            let previousID = state.currentSelection
            let expansionResult = state.update(
                sequence: sequence,
                cacheConfiguration: .init(logicalRadius: 1)
            )
            let expansionPlan = try #require(expansionResult)
            let expansionPreloads = hosts.applyUpdatePlan(
                expansionPlan,
                presentation: .curl,
                isSupersededByRecenter: false
            )
            #expect(!expansionPreloads.isEmpty)
            cacheCurlSurfaces(
                expansionPlan.retainedSurfaces,
                state: &state,
                hosts: &hosts,
                hostCreations: &hostCreations
            )
            #expect(cachedHostCount(in: hosts) == 6)

            let updateResult = state.update(
                sequence: sequence,
                cacheConfiguration: .init(logicalRadius: 0)
            )
            let updatePlan = try #require(updateResult)
            let recenterResult = state.requestRecenter(on: nextID)
            let recenter = try #require(recenterResult)
            let creationsBeforeStaticUpdate = hostCreations

            var supersededCurlHosts = hosts
            let supersededCurlPreloads = supersededCurlHosts.applyUpdatePlan(
                updatePlan,
                presentation: .curl,
                isSupersededByRecenter: true
            )
            #expect(supersededCurlPreloads.isEmpty)

            let updatePreloads = hosts.applyUpdatePlan(
                updatePlan,
                presentation: .staticPager,
                isSupersededByRecenter: true
            )
            #expect(hosts.cachedHost(for: .front(previousID)) != nil)
            #expect(hosts.cachedHost(for: .back(previousID)) != nil)
            #expect(cachedHostCount(in: hosts) == 2)

            let recenterPreloads = hosts.applyRecenterPlans(
                [recenter],
                presentation: .staticPager
            )

            #expect(updatePreloads.isEmpty)
            #expect(recenterPreloads.isEmpty)
            #expect(cachedHostCount(in: hosts) == 0)
            #expect(hostCreations == creationsBeforeStaticUpdate)

            let returnResult = state.update(
                sequence: sequence,
                cacheConfiguration: .init(logicalRadius: 0)
            )
            let returnPlan = try #require(returnResult)
            let returnPreloads = hosts.applyUpdatePlan(
                returnPlan,
                presentation: .curl,
                isSupersededByRecenter: false
            )
            #expect(returnPreloads == [.front(nextID)])
            cacheCurlHosts(
                for: nextID,
                state: &state,
                hosts: &hosts,
                hostCreations: &hostCreations
            )
            #expect(cachedHostCount(in: hosts) == 2)
        }
    }

    @Test func `static sequence and cache update evicts hosts without recenter or preload`() throws {
        var state = makeState(logicalRadius: 1)
        var hosts = KLPageCurlHostCache<Int, Host>()
        var hostCreations = 0
        cacheCurlSurfaces(
            state.cachePlan().retainedSurfaces,
            state: &state,
            hosts: &hosts,
            hostCreations: &hostCreations
        )
        #expect(cachedHostCount(in: hosts) == 6)

        let reducedSequence = KLFinitePageCurlSequence(orderedIDs: [2, 4])
        let updateResult = state.update(
            sequence: reducedSequence,
            cacheConfiguration: .init(logicalRadius: 0)
        )
        let updatePlan = try #require(updateResult)
        let recenter = state.requestRecenter(on: 2)
        let creationsBeforeStaticUpdate = hostCreations

        let staticPreloads = hosts.applyUpdatePlan(
            updatePlan,
            presentation: .staticPager,
            isSupersededByRecenter: recenter != nil
        )

        #expect(recenter == nil)
        #expect(staticPreloads.isEmpty)
        #expect(hosts.cachedHost(for: .front(1)) == nil)
        #expect(hosts.cachedHost(for: .back(1)) == nil)
        #expect(hosts.cachedHost(for: .front(3)) == nil)
        #expect(hosts.cachedHost(for: .back(3)) == nil)
        #expect(hosts.cachedHost(for: .front(2)) != nil)
        #expect(hosts.cachedHost(for: .back(2)) != nil)
        #expect(cachedHostCount(in: hosts) == 2)
        #expect(hostCreations == creationsBeforeStaticUpdate)
    }

    @Test func `presentation abort replans deferred radius update without static preload`() throws {
        var state = makeState(logicalRadius: 1)
        var hosts = KLPageCurlHostCache<Int, Host>()
        var hostCreations = 0
        cacheCurlSurfaces(
            state.cachePlan().retainedSurfaces,
            state: &state,
            hosts: &hosts,
            hostCreations: &hostCreations
        )
        #expect(cachedHostCount(in: hosts) == 6)

        let didBeginTransition = state.beginTransition(to: .front(3))
        let deferredUpdate = state.update(
            sequence: sequence,
            cacheConfiguration: .init(logicalRadius: 0)
        )
        let unchangedSelection = state.requestRecenter(on: 2)
        let abortResult = state.abortTransitionForPresentationChange(
            from: .curl,
            to: .staticPager
        )
        let abort = try #require(abortResult)
        let replannedResult = state.replanIfIdle()
        let replanned = try #require(replannedResult)
        let creationsBeforeStaticPlan = hostCreations

        let staticPreloads = hosts.applyUpdatePlan(
            replanned,
            presentation: .staticPager,
            isSupersededByRecenter: abort.recenter != nil
        )

        #expect(didBeginTransition)
        #expect(deferredUpdate == nil)
        #expect(unchangedSelection == nil)
        #expect(abort.transitionOutcome == .cancelled(surface: .front(2)))
        #expect(abort.recenter == nil)
        #expect(!state.isTransitioning)
        #expect(
            replanned.surfacesToEvict == Set([
                .front(1), .back(1),
                .front(3), .back(3),
            ])
        )
        #expect(staticPreloads.isEmpty)
        #expect(hosts.cachedHost(for: .front(1)) == nil)
        #expect(hosts.cachedHost(for: .back(1)) == nil)
        #expect(hosts.cachedHost(for: .front(3)) == nil)
        #expect(hosts.cachedHost(for: .back(3)) == nil)
        #expect(hosts.cachedHost(for: .front(2)) != nil)
        #expect(hosts.cachedHost(for: .back(2)) != nil)
        #expect(cachedHostCount(in: hosts) == 2)
        #expect(hostCreations == creationsBeforeStaticPlan)
        #expect(
            state.refreshDecision(
                revision: "current",
                surface: .front(1)
            ) == .create
        )
        #expect(
            state.refreshDecision(
                revision: "current",
                surface: .front(3)
            ) == .create
        )
        #expect(
            state.refreshDecision(
                revision: "current",
                surface: .front(2)
            ) == .keep
        )
    }

    @Test func `presentation abort replans finite sequence removals`() throws {
        var state = makeState(logicalRadius: 1)
        var hosts = KLPageCurlHostCache<Int, Host>()
        var hostCreations = 0
        cacheCurlSurfaces(
            state.cachePlan().retainedSurfaces,
            state: &state,
            hosts: &hosts,
            hostCreations: &hostCreations
        )
        let reducedSequence = KLFinitePageCurlSequence(orderedIDs: [2, 4])

        let didBeginTransition = state.beginTransition(to: .front(3))
        let deferredUpdate = state.update(
            sequence: reducedSequence,
            cacheConfiguration: .init(logicalRadius: 1)
        )
        let abortResult = state.abortTransitionForPresentationChange(
            from: .curl,
            to: .staticPager
        )
        let abort = try #require(abortResult)
        let replannedResult = state.replanIfIdle()
        let replanned = try #require(replannedResult)
        let creationsBeforeStaticPlan = hostCreations

        let staticPreloads = hosts.applyUpdatePlan(
            replanned,
            presentation: .staticPager,
            isSupersededByRecenter: abort.recenter != nil
        )

        #expect(didBeginTransition)
        #expect(deferredUpdate == nil)
        #expect(abort.transitionOutcome == .cancelled(surface: .front(2)))
        #expect(abort.recenter == nil)
        #expect(!state.isTransitioning)
        #expect(replanned.retainedSurfaces == [
            .front(2), .back(2),
            .front(4), .back(4),
        ])
        #expect(replanned.surfacesToPreload == [.front(4)])
        #expect(staticPreloads.isEmpty)
        #expect(hosts.cachedHost(for: .front(1)) == nil)
        #expect(hosts.cachedHost(for: .back(1)) == nil)
        #expect(hosts.cachedHost(for: .front(3)) == nil)
        #expect(hosts.cachedHost(for: .back(3)) == nil)
        #expect(hosts.cachedHost(for: .front(2)) != nil)
        #expect(hosts.cachedHost(for: .back(2)) != nil)
        #expect(hosts.cachedHost(for: .front(4)) == nil)
        #expect(hosts.cachedHost(for: .back(4)) == nil)
        #expect(cachedHostCount(in: hosts) == 2)
        #expect(hostCreations == creationsBeforeStaticPlan)
        #expect(
            state.refreshDecision(
                revision: "current",
                surface: .front(3)
            ) == .create
        )
    }

    private func makeState(logicalRadius: Int = 0) -> State {
        State(
            initialSelection: 2,
            sequence: sequence,
            cacheConfiguration: .init(logicalRadius: logicalRadius)
        )
    }

    private func cacheCurlHosts(
        for id: Int,
        state: inout State,
        hosts: inout KLPageCurlHostCache<Int, Host>,
        hostCreations: inout Int
    ) {
        let surfaces: [KLPageCurlSurface<Int>] = [.front(id), .back(id)]
        cacheCurlSurfaces(
            surfaces,
            state: &state,
            hosts: &hosts,
            hostCreations: &hostCreations
        )
    }

    private func cacheCurlSurfaces(
        _ surfaces: [KLPageCurlSurface<Int>],
        state: inout State,
        hosts: inout KLPageCurlHostCache<Int, Host>,
        hostCreations: inout Int
    ) {
        for surface in surfaces {
            state.didCache(surface, revision: "current")
            _ = hosts.resolve(
                surface: surface,
                isActive: surface == state.currentSurface,
                revisionDecision: .create,
                makeHost: { isActive in
                    hostCreations += 1
                    return Host(surface: surface, isActive: isActive)
                },
                updateRoot: { host, isActive in
                    host.isActive = isActive
                }
            )
        }
    }

    private func cachedHostCount(
        in hosts: KLPageCurlHostCache<Int, Host>
    ) -> Int {
        allSurfaces.count {
            hosts.cachedHost(for: $0) != nil
        }
    }
}
