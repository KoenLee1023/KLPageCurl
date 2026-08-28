import Testing
@testable import KLPageCurl

@Suite struct KLPageCurlAccessibilityTests {
    private let sequence = KLFinitePageCurlSequence(orderedIDs: [1, 2, 3])

    @Test func `motion policy resolves explicit presentation`() {
        #expect(KLPageCurlPresentation.resolve(for: .curl) == .curl)
        #expect(KLPageCurlPresentation.resolve(for: .reducedMotion) == .staticPager)
    }

    @Test func `reduced motion constructs neither curl nor feedback`() {
        var curlConstructions = 0
        var staticConstructions = 0
        var feedbackConstructions = 0

        let resources = KLPageCurlPresentationResources.make(
            for: .reducedMotion,
            makeCurl: {
                curlConstructions += 1
                return "curl"
            },
            makeStaticPager: {
                staticConstructions += 1
                return "static"
            },
            makeFeedback: {
                feedbackConstructions += 1
                return "feedback"
            }
        )

        #expect(resources.presentation == "static")
        #expect(resources.feedback == nil)
        #expect(curlConstructions == 0)
        #expect(staticConstructions == 1)
        #expect(feedbackConstructions == 0)
    }

    @Test func `curl policy constructs page curl resources`() {
        var curlConstructions = 0
        var staticConstructions = 0

        let resources = KLPageCurlPresentationResources.make(
            for: .curl,
            makeCurl: {
                curlConstructions += 1
                return "curl"
            },
            makeStaticPager: {
                staticConstructions += 1
                return "static"
            },
            makeFeedback: { "feedback" }
        )

        #expect(resources.presentation == "curl")
        #expect(resources.feedback == "feedback")
        #expect(curlConstructions == 1)
        #expect(staticConstructions == 0)
    }

    @Test func `host contract distinguishes front and back accessibility`() {
        let accessibility = makeAccessibility()

        #expect(accessibility.label(2) == "Item 2")
        #expect(accessibility.value(.front(2)) == "Front")
        #expect(accessibility.value(.back(2)) == "Back")
        #expect(accessibility.previousActionName == "Previous item")
        #expect(accessibility.nextActionName == "Next item")
    }

    @Test func `named actions update logical selection in both presentations`() throws {
        let presentations: [(KLPageCurlMotionPolicy, KLPageCurlPresentation)] = [
            (.curl, .curl),
            (.reducedMotion, .staticPager),
        ]
        for (policy, expectedPresentation) in presentations {
            var state = KLPageCurlControllerState(
                initialSelection: 2,
                sequence: sequence,
                cacheConfiguration: .init(logicalRadius: 1)
            )

            #expect(KLPageCurlPresentation.resolve(for: policy) == expectedPresentation)
            let nextResult = state.performAccessibilityAction(.next)
            let next = try #require(nextResult)
            #expect(next.outcome == .recentered(surface: .front(3), selection: 3))
            #expect(state.currentSelection == 3)

            let previousResult = state.performAccessibilityAction(.previous)
            let previous = try #require(previousResult)
            #expect(previous.outcome == .recentered(surface: .front(2), selection: 2))
            #expect(state.currentSelection == 2)
        }
    }

    @Test func `announcements require a completed settle and preserve side`() {
        let accessibility = makeAccessibility()
        var state = KLPageCurlControllerState(
            initialSelection: 2,
            sequence: sequence,
            cacheConfiguration: .init(logicalRadius: 1)
        )

        state.beginTransition(to: .back(2))
        let cancelled = state.finishTransitionAndReconcile(completed: false)
        #expect(accessibility.announcement(for: cancelled.transitionOutcome) == nil)

        state.beginTransition(to: .back(2))
        let settledBack = state.finishTransitionAndReconcile(completed: true)
        #expect(
            accessibility.announcement(for: settledBack.transitionOutcome) == "Back 2"
        )

        state.beginTransition(to: .front(3))
        let settledFront = state.finishTransitionAndReconcile(completed: true)
        #expect(
            accessibility.announcement(for: settledFront.transitionOutcome) == "Front 3"
        )
        #expect(
            accessibility.announcement(
                for: KLPageCurlTransitionOutcome<Int>.ignored
            ) == nil
        )
    }

    @Test func `only completed settle invokes transition side effects`() throws {
        let accessibility = makeAccessibility()
        var feedbackCount = 0
        var announcements: [String] = []
        var settledSurfaces: [KLPageCurlSurface<Int>] = []
        let applySideEffects = { (outcome: KLPageCurlTransitionOutcome<Int>) in
            KLPageCurlTransitionSideEffects.apply(
                outcome: outcome,
                accessibility: accessibility,
                feedback: { feedbackCount += 1 },
                announce: { announcements.append($0) },
                onSettled: { settledSurfaces.append($0) }
            )
        }

        var recenterState = KLPageCurlControllerState(
            initialSelection: 2,
            sequence: sequence,
            cacheConfiguration: .init(logicalRadius: 1)
        )
        let recenterResult = recenterState.performAccessibilityAction(.next)
        let recenter = try #require(recenterResult)
        applySideEffects(recenter.outcome)

        #expect(feedbackCount == 0)
        #expect(announcements.isEmpty)
        #expect(settledSurfaces.isEmpty)

        var transitionState = KLPageCurlControllerState(
            initialSelection: 2,
            sequence: sequence,
            cacheConfiguration: .init(logicalRadius: 1)
        )
        transitionState.beginTransition(to: .back(2))
        let cancelled = transitionState.finishTransitionAndReconcile(
            completed: false
        )
        applySideEffects(cancelled.transitionOutcome)

        #expect(feedbackCount == 0)
        #expect(announcements.isEmpty)
        #expect(settledSurfaces.isEmpty)

        transitionState.beginTransition(to: .back(2))
        let completed = transitionState.finishTransitionAndReconcile(
            completed: true
        )
        applySideEffects(completed.transitionOutcome)

        #expect(feedbackCount == 1)
        #expect(announcements == ["Back 2"])
        #expect(settledSurfaces == [.back(2)])
    }

    private func makeAccessibility() -> KLPageCurlAccessibility<Int> {
        KLPageCurlAccessibility(
            label: { "Item \($0)" },
            value: { $0.isFront ? "Front" : "Back" },
            frontAnnouncement: { "Front \($0)" },
            backAnnouncement: { "Back \($0)" },
            previousActionName: "Previous item",
            nextActionName: "Next item"
        )
    }
}
