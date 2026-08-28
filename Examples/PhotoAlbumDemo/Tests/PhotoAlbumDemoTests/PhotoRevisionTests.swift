import Testing
@testable import PhotoAlbumDemoApp

@Suite struct PhotoRevisionTests {
    @Test func `editing caption changes only front revision`() {
        var record = PhotoRecord(
            id: .coast,
            caption: "Morning coast",
            metadata: "Synthetic study · frame 01"
        )
        let frontBefore = record.frontRevision
        let backBefore = record.backRevision

        record.caption = "Evening coast"

        #expect(record.frontRevision != frontBefore)
        #expect(record.backRevision == backBefore)
    }

    @Test func `editing metadata changes only back revision`() {
        var record = PhotoRecord(
            id: .coast,
            caption: "Morning coast",
            metadata: "Synthetic study · frame 01"
        )
        let frontBefore = record.frontRevision
        let backBefore = record.backRevision

        record.metadata = "Synthetic study · frame 02"

        #expect(record.frontRevision == frontBefore)
        #expect(record.backRevision != backBefore)
    }
}
