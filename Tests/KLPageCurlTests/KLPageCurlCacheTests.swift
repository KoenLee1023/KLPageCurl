import Testing
@testable import KLPageCurl

private func requireSendable<Value: Sendable>(_: Value.Type) {}

@Suite struct KLPageCurlCacheTests {
    private let sequence = KLFinitePageCurlSequence(orderedIDs: [1, 2, 3, 4])

    @Test func `radius zero retains both current surfaces and preloads only front`() {
        let cache = KLPageCurlCacheConfiguration(logicalRadius: 0)

        let plan = cache.plan(around: 2, sequence: sequence)

        #expect(plan.retainedSurfaces == [.front(2), .back(2)])
        #expect(plan.surfacesToPreload == [.front(2)])
        #expect(plan.surfacesToEvict.isEmpty)
    }

    @Test func `radius one retains current logical item and one neighbor each side`() {
        let cache = KLPageCurlCacheConfiguration(logicalRadius: 1)

        let plan = cache.plan(around: 2, sequence: sequence)

        #expect(
            plan.retainedSurfaces
                == [.front(1), .back(1), .front(2), .back(2), .front(3), .back(3)]
        )
        #expect(plan.surfacesToPreload == [.front(1), .front(2), .front(3)])
    }

    @Test func `cache planning follows generic sequence IDs and finite edges`() {
        let cache = KLPageCurlCacheConfiguration(logicalRadius: 1)
        let chapters = KLFinitePageCurlSequence(orderedIDs: ["opening", "middle", "ending"])

        let firstPlan = cache.plan(around: "opening", sequence: chapters)
        let middlePlan = cache.plan(around: "middle", sequence: chapters)

        #expect(
            firstPlan.retainedSurfaces
                == [.front("opening"), .back("opening"), .front("middle"), .back("middle")]
        )
        #expect(
            middlePlan.retainedSurfaces
                == [
                    .front("opening"), .back("opening"),
                    .front("middle"), .back("middle"),
                    .front("ending"), .back("ending"),
                ]
        )
    }

    @Test func `programmatic jump evicts old window and preloads new fronts`() {
        let cache = KLPageCurlCacheConfiguration(logicalRadius: 1)
        let oldPlan = cache.plan(around: 1, sequence: sequence)

        let newPlan = cache.plan(
            around: 4,
            sequence: sequence,
            cachedSurfaces: Set(oldPlan.retainedSurfaces)
        )

        #expect(
            newPlan.retainedSurfaces
                == [.front(3), .back(3), .front(4), .back(4)]
        )
        #expect(newPlan.surfacesToPreload == [.front(3), .front(4)])
        #expect(
            newPlan.surfacesToEvict
                == Set([.front(1), .back(1), .front(2), .back(2)])
        )
    }

    @Test func `cached fronts are not preloaded twice`() {
        let cache = KLPageCurlCacheConfiguration(logicalRadius: 1)

        let plan = cache.plan(
            around: 2,
            sequence: sequence,
            cachedSurfaces: [.front(1), .front(2)]
        )

        #expect(plan.surfacesToPreload == [.front(3)])
    }

    @Test func `revision decisions distinguish create keep reload and transition deferral`() {
        var revisions = KLPageCurlRevisionIndex<Int>()

        #expect(
            revisions.refreshDecision(
                revision: "initial",
                surface: .front(2),
                isTransitioning: false
            ) == .create
        )

        revisions.record("initial", for: .front(2))

        #expect(
            revisions.refreshDecision(
                revision: "initial",
                surface: .front(2),
                isTransitioning: false
            ) == .keep
        )
        #expect(
            revisions.refreshDecision(
                revision: "updated",
                surface: .front(2),
                isTransitioning: false
            ) == .reload
        )
        #expect(
            revisions.refreshDecision(
                revision: "initial",
                surface: .back(2),
                isTransitioning: false
            ) == .create
        )
        #expect(
            revisions.refreshDecision(
                revision: "updated",
                surface: .front(2),
                isTransitioning: true
            ) == .deferUntilIdle
        )
    }

    @Test func `applying cache evictions removes stale revision decisions`() {
        let cache = KLPageCurlCacheConfiguration(logicalRadius: 1)
        let oldPlan = cache.plan(around: 2, sequence: sequence)
        let newPlan = cache.plan(
            around: 3,
            sequence: sequence,
            cachedSurfaces: Set(oldPlan.retainedSurfaces)
        )
        var revisions = KLPageCurlRevisionIndex<Int>()
        for surface in oldPlan.retainedSurfaces {
            revisions.record("current", for: surface)
        }

        revisions.applyEvictions(from: newPlan)

        #expect(revisions.recordedSurfaceCount == 4)
        #expect(
            revisions.refreshDecision(
                revision: "current",
                surface: .front(1),
                isTransitioning: false
            ) == .create
        )
        #expect(
            revisions.refreshDecision(
                revision: "current",
                surface: .front(2),
                isTransitioning: false
            ) == .keep
        )
    }

    @Test func `revision storage remains bounded across programmatic cache windows`() {
        let cache = KLPageCurlCacheConfiguration(logicalRadius: 0)
        var revisions = KLPageCurlRevisionIndex<Int>()
        var cachedSurfaces: Set<KLPageCurlSurface<Int>> = []

        for selection in [1, 2, 3, 4] {
            let plan = cache.plan(
                around: selection,
                sequence: sequence,
                cachedSurfaces: cachedSurfaces
            )
            revisions.applyEvictions(from: plan)
            for surface in plan.retainedSurfaces {
                revisions.record(selection, for: surface)
            }
            cachedSurfaces = Set(plan.retainedSurfaces)

            #expect(revisions.recordedSurfaceCount == 2)
        }
    }

    @Test func `revision index satisfies checked Sendable requirements`() {
        requireSendable(KLPageCurlRevisionIndex<Int>.self)
    }

    @Test func `configuration defaults to curl with radius one`() {
        let configuration = KLPageCurlConfiguration()

        #expect(configuration.motionPolicy == .curl)
        #expect(configuration.cache.logicalRadius == 1)
        #expect(KLPageCurlCacheConfiguration.maximumLogicalRadius == 8)
    }
}
