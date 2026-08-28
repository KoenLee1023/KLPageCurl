import KLPageCurl

enum PhotoID: String, CaseIterable, Identifiable, Hashable, Sendable {
    case coast = "photo-coast"
    case canyon = "photo-canyon"
    case forest = "photo-forest"
    case city = "photo-city"
    case garden = "photo-garden"
    case night = "photo-night"

    var id: String { rawValue }
}

enum PhotoRevision: Hashable, Sendable {
    case front(String)
    case back(String)
}

struct PhotoRecord: Equatable, Sendable {
    let id: PhotoID
    var caption: String
    var metadata: String

    var frontRevision: PhotoRevision {
        .front(caption)
    }

    var backRevision: PhotoRevision {
        .back(metadata)
    }
}

struct PhotoSequence: KLPageCurlSequence {
    private let finiteSequence: KLFinitePageCurlSequence<PhotoID>

    init(ids: [PhotoID]) {
        finiteSequence = KLFinitePageCurlSequence(orderedIDs: ids)
    }

    func initialSurface(for selection: PhotoID) -> KLPageCurlSurface<PhotoID> {
        finiteSequence.initialSurface(for: selection)
    }

    func adjacent(
        to surface: KLPageCurlSurface<PhotoID>,
        direction: KLPageCurlDirection
    ) -> KLPageCurlSurface<PhotoID>? {
        finiteSequence.adjacent(to: surface, direction: direction)
    }
}

enum PhotoAlbumEffect: Equatable, Sendable {
    case none
    case settled(KLPageCurlSurface<PhotoID>)
}

struct PhotoAlbumState: Equatable, Sendable {
    private let orderedIDs: [PhotoID]
    private var recordsByID: [PhotoID: PhotoRecord]

    private(set) var selectedID: PhotoID
    private(set) var settledSurface: KLPageCurlSurface<PhotoID>
    private(set) var motionPolicy: KLPageCurlMotionPolicy

    init(
        records: [PhotoRecord],
        selectedID: PhotoID,
        motionPolicy: KLPageCurlMotionPolicy
    ) {
        var recordsByID: [PhotoID: PhotoRecord] = [:]
        var orderedIDs: [PhotoID] = []
        for record in records where recordsByID[record.id] == nil {
            recordsByID[record.id] = record
            orderedIDs.append(record.id)
        }

        let normalizedSelection = recordsByID[selectedID] == nil
            ? orderedIDs.first ?? selectedID
            : selectedID
        self.orderedIDs = orderedIDs
        self.recordsByID = recordsByID
        self.selectedID = normalizedSelection
        settledSurface = .front(normalizedSelection)
        self.motionPolicy = motionPolicy
    }

    var records: [PhotoRecord] {
        orderedIDs.compactMap { recordsByID[$0] }
    }

    func record(for id: PhotoID) -> PhotoRecord? {
        recordsByID[id]
    }

    func revision(
        for surface: KLPageCurlSurface<PhotoID>
    ) -> PhotoRevision? {
        guard let record = recordsByID[surface.id] else { return nil }
        switch surface {
        case .front:
            return record.frontRevision
        case .back:
            return record.backRevision
        }
    }

    mutating func didEditCaption(_ caption: String, for id: PhotoID) {
        recordsByID[id]?.caption = caption
    }

    mutating func didEditMetadata(_ metadata: String, for id: PhotoID) {
        recordsByID[id]?.metadata = metadata
    }

    @discardableResult
    mutating func didSelectPhoto(_ id: PhotoID) -> PhotoAlbumEffect {
        guard recordsByID[id] != nil else { return .none }
        selectedID = id
        settledSurface = .front(id)
        return .none
    }

    @discardableResult
    mutating func didChangeMotionPolicy(
        _ motionPolicy: KLPageCurlMotionPolicy
    ) -> PhotoAlbumEffect {
        self.motionPolicy = motionPolicy
        if KLPageCurlPresentation.resolve(for: motionPolicy) == .staticPager {
            settledSurface = .front(selectedID)
        }
        return .none
    }

    @discardableResult
    mutating func didSettle(
        on surface: KLPageCurlSurface<PhotoID>
    ) -> PhotoAlbumEffect {
        if case .front(let id) = surface, recordsByID[id] != nil {
            selectedID = id
        }
        settledSurface = surface
        return .settled(surface)
    }
}
