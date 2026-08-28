import KLPageCurl

enum Chapter: String, CaseIterable, Identifiable, Hashable, Sendable {
    case one = "chapter-one"
    case two = "chapter-two"
    case three = "chapter-three"

    var id: String { rawValue }
}

struct ChapterSequence: KLPageCurlSequence {
    private let finiteSequence: KLFinitePageCurlSequence<Chapter>

    init(chapters: [Chapter]) {
        finiteSequence = KLFinitePageCurlSequence(orderedIDs: chapters)
    }

    func initialSurface(for selection: Chapter) -> KLPageCurlSurface<Chapter> {
        finiteSequence.initialSurface(for: selection)
    }

    func adjacent(
        to surface: KLPageCurlSurface<Chapter>,
        direction: KLPageCurlDirection
    ) -> KLPageCurlSurface<Chapter>? {
        finiteSequence.adjacent(to: surface, direction: direction)
    }
}
