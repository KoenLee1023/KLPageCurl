import Testing
@testable import KLPageCurl

@Suite struct KLPageCurlSurfaceTests {
    private let sequence = KLFinitePageCurlSequence(orderedIDs: [1, 2, 3])

    @Test func `surface exposes logical identity and side`() {
        #expect(KLPageCurlSurface.front(2).id == 2)
        #expect(KLPageCurlSurface.front(2).isFront)
        #expect(KLPageCurlSurface.back(2).id == 2)
        #expect(!KLPageCurlSurface.back(2).isFront)
    }

    @Test func `forward navigation visits own back then next front`() {
        #expect(sequence.adjacent(to: .front(2), direction: .after) == .back(2))
        #expect(sequence.adjacent(to: .back(2), direction: .after) == .front(3))
    }

    @Test func `reverse navigation visits own front then previous back`() {
        #expect(sequence.adjacent(to: .back(2), direction: .before) == .front(2))
        #expect(sequence.adjacent(to: .front(2), direction: .before) == .back(1))
    }

    @Test func `finite boundaries and unknown IDs have no neighbors`() {
        #expect(sequence.adjacent(to: .front(1), direction: .before) == nil)
        #expect(sequence.adjacent(to: .back(3), direction: .after) == nil)
        #expect(sequence.adjacent(to: .front(99), direction: .after) == nil)
        #expect(sequence.adjacent(to: .back(99), direction: .before) == nil)
    }

    @Test func `initial surface is the selected front`() {
        #expect(sequence.initialSurface(for: 2) == .front(2))
    }

    @Test func `duplicate IDs preserve first occurrence without creating a cycle`() {
        let duplicateSequence = KLFinitePageCurlSequence(orderedIDs: [1, 2, 2, 3, 1])
        var visitedSurfaces: Set<KLPageCurlSurface<Int>> = []
        var surface: KLPageCurlSurface<Int>? = .front(1)

        for _ in 0..<7 {
            guard let currentSurface = surface else {
                break
            }
            #expect(visitedSurfaces.insert(currentSurface).inserted)
            surface = duplicateSequence.adjacent(to: currentSurface, direction: .after)
        }

        #expect(duplicateSequence.orderedIDs == [1, 2, 3])
        #expect(surface == nil)
        #expect(
            visitedSurfaces
                == Set([.front(1), .back(1), .front(2), .back(2), .front(3), .back(3)])
        )
    }
}
