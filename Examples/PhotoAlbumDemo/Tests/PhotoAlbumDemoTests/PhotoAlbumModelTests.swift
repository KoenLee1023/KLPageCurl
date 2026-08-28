import KLPageCurl
import Testing
@testable import PhotoAlbumDemoApp

@Suite struct PhotoAlbumModelTests {
    @Test func `album exposes six stable photo IDs`() {
        #expect(
            PhotoID.allCases.map(\.rawValue) == [
                "photo-coast",
                "photo-canyon",
                "photo-forest",
                "photo-city",
                "photo-garden",
                "photo-night",
            ]
        )
    }

    @Test func `album sequence stops at first front and last back`() {
        let sequence = PhotoSequence(ids: PhotoID.allCases)

        #expect(sequence.initialSurface(for: .forest) == .front(.forest))
        #expect(sequence.adjacent(to: .front(.coast), direction: .before) == nil)
        #expect(sequence.adjacent(to: .back(.night), direction: .after) == nil)
        #expect(sequence.adjacent(to: .back(.coast), direction: .after) == .front(.canyon))
        #expect(sequence.adjacent(to: .front(.night), direction: .before) == .back(.garden))
    }

    @Test func `caption edit changes only selected front revision`() throws {
        var state = PhotoAlbumState(
            records: makeRecords(),
            selectedID: .forest,
            motionPolicy: .curl
        )
        let frontBefore = try #require(state.revision(for: .front(.forest)))
        let backBefore = try #require(state.revision(for: .back(.forest)))

        state.didEditCaption("A quieter forest", for: .forest)

        #expect(state.revision(for: .front(.forest)) != frontBefore)
        #expect(state.revision(for: .back(.forest)) == backBefore)
    }

    @Test func `metadata edit changes only selected back revision`() throws {
        var state = PhotoAlbumState(
            records: makeRecords(),
            selectedID: .forest,
            motionPolicy: .curl
        )
        let frontBefore = try #require(state.revision(for: .front(.forest)))
        let backBefore = try #require(state.revision(for: .back(.forest)))

        state.didEditMetadata("Synthetic study · revised", for: .forest)

        #expect(state.revision(for: .front(.forest)) == frontBefore)
        #expect(state.revision(for: .back(.forest)) != backBefore)
    }

    @Test func `picker selection recenters by stable identity`() {
        var state = PhotoAlbumState(
            records: makeRecords(),
            selectedID: .coast,
            motionPolicy: .curl
        )

        let effect = state.didSelectPhoto(.city)

        #expect(state.selectedID == .city)
        #expect(state.settledSurface == .front(.city))
        #expect(effect == .none)
    }

    @Test func `reduced motion recenters displayed back to selected front`() {
        var state = PhotoAlbumState(
            records: makeRecords(),
            selectedID: .garden,
            motionPolicy: .curl
        )
        state.didSettle(on: .back(.garden))

        let effect = state.didChangeMotionPolicy(.reducedMotion)

        #expect(state.selectedID == .garden)
        #expect(state.settledSurface == .front(.garden))
        #expect(state.motionPolicy == .reducedMotion)
        #expect(effect == .none)
    }

    @Test func `only pager completion produces settled effect`() {
        var state = PhotoAlbumState(
            records: makeRecords(),
            selectedID: .coast,
            motionPolicy: .curl
        )

        let selectionEffect = state.didSelectPhoto(.city)
        let motionEffect = state.didChangeMotionPolicy(.reducedMotion)
        let settleEffect = state.didSettle(on: .back(.city))

        #expect(selectionEffect == .none)
        #expect(motionEffect == .none)
        #expect(settleEffect == .settled(.back(.city)))
    }
}

private func makeRecords() -> [PhotoRecord] {
    PhotoID.allCases.enumerated().map { index, id in
        PhotoRecord(
            id: id,
            caption: "Caption \(index + 1)",
            metadata: "Synthetic study · frame \(index + 1)"
        )
    }
}
