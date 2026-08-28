import KLPageCurl

enum BookPreviewDisplayEffect: Equatable, Sendable {
    case none
    case settled(KLPageCurlSurface<Chapter>)
}

struct BookPreviewDisplayState: Equatable, Sendable {
    private(set) var selectedChapter: Chapter
    private(set) var settledSurface: KLPageCurlSurface<Chapter>
    private(set) var motionPolicy: KLPageCurlMotionPolicy

    init(
        selectedChapter: Chapter,
        settledSurface: KLPageCurlSurface<Chapter>,
        motionPolicy: KLPageCurlMotionPolicy
    ) {
        self.selectedChapter = selectedChapter
        self.settledSurface = settledSurface
        self.motionPolicy = motionPolicy
    }

    mutating func didSelectChapter(_ chapter: Chapter) {
        selectedChapter = chapter
        settledSurface = .front(chapter)
    }

    @discardableResult
    mutating func didChangeMotionPolicy(
        _ motionPolicy: KLPageCurlMotionPolicy
    ) -> BookPreviewDisplayEffect {
        self.motionPolicy = motionPolicy
        if KLPageCurlPresentation.resolve(for: motionPolicy) == .staticPager {
            settledSurface = .front(selectedChapter)
        }
        return .none
    }

    @discardableResult
    mutating func didSettle(
        on surface: KLPageCurlSurface<Chapter>
    ) -> BookPreviewDisplayEffect {
        settledSurface = surface
        return .settled(surface)
    }
}
