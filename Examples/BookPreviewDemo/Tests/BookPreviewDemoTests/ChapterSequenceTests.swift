import KLPageCurl
import Testing
@testable import BookPreviewDemoApp

@Suite struct ChapterSequenceTests {
    @Test func `chapter IDs remain stable`() {
        #expect(Chapter.one.id == "chapter-one")
        #expect(Chapter.two.id == "chapter-two")
        #expect(Chapter.three.id == "chapter-three")
    }

    @Test func `selection starts on its chapter front`() {
        let sequence = ChapterSequence(chapters: [.one, .two, .three])

        #expect(sequence.initialSurface(for: .two) == .front(.two))
    }

    @Test func `front and back surfaces follow finite chapter order`() {
        let sequence = ChapterSequence(chapters: [.one, .two, .three])

        #expect(sequence.adjacent(to: .front(.one), direction: .after) == .back(.one))
        #expect(sequence.adjacent(to: .back(.one), direction: .after) == .front(.two))
        #expect(sequence.adjacent(to: .front(.two), direction: .after) == .back(.two))
        #expect(sequence.adjacent(to: .back(.two), direction: .after) == .front(.three))
        #expect(sequence.adjacent(to: .back(.three), direction: .before) == .front(.three))
        #expect(sequence.adjacent(to: .front(.three), direction: .before) == .back(.two))
        #expect(sequence.adjacent(to: .front(.two), direction: .before) == .back(.one))
        #expect(sequence.adjacent(to: .back(.one), direction: .before) == .front(.one))
    }

    @Test func `first front and last back are finite boundaries`() {
        let sequence = ChapterSequence(chapters: [.one, .two, .three])

        #expect(sequence.adjacent(to: .front(.one), direction: .before) == nil)
        #expect(sequence.adjacent(to: .back(.three), direction: .after) == nil)
    }

    @Test func `reduced motion recenters a displayed back without settling`() {
        var state = BookPreviewDisplayState(
            selectedChapter: .two,
            settledSurface: .back(.two),
            motionPolicy: .curl
        )

        let effect = state.didChangeMotionPolicy(.reducedMotion)

        #expect(state.selectedChapter == .two)
        #expect(state.settledSurface == .front(.two))
        #expect(state.motionPolicy == .reducedMotion)
        #expect(effect == .none)
    }
}
