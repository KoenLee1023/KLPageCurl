import Testing
@testable import KLPageCurl

@Suite struct KLPageCurlStateMachineTests {
    private let sequence = KLFinitePageCurlSequence(orderedIDs: [1, 2, 3, 4])

    @Test func `completed back keeps logical selection while completed front commits it`() {
        var machine = KLPageCurlStateMachine(initialSelection: 2, sequence: sequence)

        let didBeginBack = machine.beginTransition(to: .back(2))
        #expect(didBeginBack)
        #expect(
            machine.finishTransition(completed: true)
                == .settled(surface: .back(2), selection: nil)
        )
        #expect(machine.currentSurface == .back(2))
        #expect(machine.currentSelection == 2)

        let didBeginFront = machine.beginTransition(to: .front(3))
        #expect(didBeginFront)
        #expect(
            machine.finishTransition(completed: true)
                == .settled(surface: .front(3), selection: 3)
        )
        #expect(machine.currentSelection == 3)
    }

    @Test func `cancelled transition restores the displayed surface and selection`() {
        var machine = KLPageCurlStateMachine(initialSelection: 2, sequence: sequence)

        let didBegin = machine.beginTransition(to: .back(2))
        #expect(didBegin)
        #expect(machine.finishTransition(completed: false) == .cancelled(surface: .front(2)))
        #expect(machine.currentSurface == .front(2))
        #expect(machine.currentSelection == 2)
    }

    @Test func `completed back with different pending ID keeps selected ID`() {
        var machine = KLPageCurlStateMachine(initialSelection: 2, sequence: sequence)

        let didBegin = machine.beginTransition(to: .back(4))
        let outcome = machine.finishTransition(completed: true)

        #expect(didBegin)
        #expect(outcome == .settled(surface: .back(4), selection: nil))
        #expect(machine.currentSurface == .back(4))
        #expect(machine.currentSelection == 2)
    }

    @Test func `cancelled front with different pending ID restores selected front`() {
        var machine = KLPageCurlStateMachine(initialSelection: 2, sequence: sequence)

        let didBegin = machine.beginTransition(to: .front(4))
        let outcome = machine.finishTransition(completed: false)

        #expect(didBegin)
        #expect(outcome == .cancelled(surface: .front(2)))
        #expect(machine.currentSurface == .front(2))
        #expect(machine.currentSelection == 2)
    }

    @Test func `recenter replaces stale center atomically`() {
        var machine = KLPageCurlStateMachine(initialSelection: 1, sequence: sequence)

        #expect(
            machine.recenter(on: 4, sequence: sequence)
                == .recentered(surface: .front(4), selection: 4)
        )
        #expect(machine.currentSurface == .front(4))
        #expect(machine.currentSelection == 4)
    }

    @Test func `recenter and duplicate begin are ignored during a transition`() {
        var machine = KLPageCurlStateMachine(initialSelection: 1, sequence: sequence)

        let didBegin = machine.beginTransition(to: .back(1))
        let didBeginAgain = machine.beginTransition(to: .front(2))
        #expect(didBegin)
        #expect(!didBeginAgain)
        #expect(machine.recenter(on: 4, sequence: sequence) == .ignored)
        #expect(machine.currentSurface == .front(1))
        #expect(machine.currentSelection == 1)
        #expect(machine.finishTransition(completed: false) == .cancelled(surface: .front(1)))
    }

    @Test func `finishing while idle is ignored`() {
        var machine = KLPageCurlStateMachine(initialSelection: 1, sequence: sequence)

        #expect(machine.finishTransition(completed: true) == .ignored)
    }
}
