#if os(iOS)
import KLPageCurl
import SwiftUI

@main
struct PhotoAlbumDemoApp: App {
    var body: some Scene {
        WindowGroup {
            PhotoAlbumView()
        }
    }
}

struct PhotoAlbumView: View {
    private let sequence = PhotoSequence(ids: PhotoID.allCases)

    @State private var album: PhotoAlbumState

    init(initialMotionPolicy: KLPageCurlMotionPolicy = .curl) {
        _album = State(
            initialValue: PhotoAlbumState(
                records: PhotoRecord.demoRecords,
                selectedID: .coast,
                motionPolicy: initialMotionPolicy
            )
        )
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 14) {
                controls
                settledStatus
                pager
            }
            .padding()
            .navigationTitle("Synthetic Album")
        }
    }

    private var controls: some View {
        VStack(alignment: .leading, spacing: 12) {
            Picker("Photo", selection: selectedPhotoBinding) {
                ForEach(PhotoID.allCases) { id in
                    Text(id.shortName).tag(id)
                }
            }
            .pickerStyle(.menu)
            .accessibilityHint("Recenter the album on a photo front")

            Toggle("Reduce Motion", isOn: reducedMotionBinding)
                .accessibilityHint(
                    "Show the selected photo front without a page curl"
                )
        }
    }

    private var settledStatus: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Settled album surface")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
            Text(photoSurfaceAccessibilityValue(for: album.settledSurface))
                .font(.body)
            Text(boundaryDescription)
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .combine)
    }

    private var pager: some View {
        let revisions = surfaceRevisions
        return KLPageCurlPager(
            selection: selectedPhotoBinding,
            sequence: sequence,
            revision: { surface in revisions[surface] },
            front: { id, isActive in
                PhotoFrontView(
                    record: displayedRecord(for: id),
                    caption: captionBinding(for: id),
                    staticMetadata: staticMetadataBinding(for: id),
                    isActive: isActive
                )
            },
            back: { id in
                PhotoBackView(
                    record: displayedRecord(for: id),
                    metadata: metadataBinding(for: id)
                )
            },
            configuration: .init(
                motionPolicy: album.motionPolicy,
                cache: .init(logicalRadius: 1)
            ),
            accessibility: .init(
                label: { $0.accessibilityLabel },
                value: { photoSurfaceAccessibilityValue(for: $0) },
                frontAnnouncement: { "\($0.accessibilityLabel), photo front" },
                backAnnouncement: { "\($0.accessibilityLabel), metadata back" },
                previousActionName: "Previous photo",
                nextActionName: "Next photo"
            ),
            onSettled: { surface in
                album.didSettle(on: surface)
            }
        )
        .accessibilityIdentifier("photoAlbumPager")
        .clipShape(RoundedRectangle(cornerRadius: 18))
        .overlay {
            RoundedRectangle(cornerRadius: 18)
                .stroke(Color(uiColor: .separator), lineWidth: 1)
        }
    }

    private var surfaceRevisions: [KLPageCurlSurface<PhotoID>: PhotoRevision?] {
        var revisions: [KLPageCurlSurface<PhotoID>: PhotoRevision?] = [:]
        for id in PhotoID.allCases {
            revisions[.front(id)] = album.revision(for: .front(id))
            revisions[.back(id)] = album.revision(for: .back(id))
        }
        return revisions
    }

    private var selectedPhotoBinding: Binding<PhotoID> {
        Binding(
            get: { album.selectedID },
            set: { album.didSelectPhoto($0) }
        )
    }

    private var reducedMotionBinding: Binding<Bool> {
        Binding(
            get: { album.motionPolicy == .reducedMotion },
            set: { isReducedMotion in
                album.didChangeMotionPolicy(
                    isReducedMotion ? .reducedMotion : .curl
                )
            }
        )
    }

    private func captionBinding(for id: PhotoID) -> Binding<String> {
        Binding(
            get: { album.record(for: id)?.caption ?? "" },
            set: { album.didEditCaption($0, for: id) }
        )
    }

    private func metadataBinding(for id: PhotoID) -> Binding<String> {
        Binding(
            get: { album.record(for: id)?.metadata ?? "" },
            set: { album.didEditMetadata($0, for: id) }
        )
    }

    private func staticMetadataBinding(for id: PhotoID) -> Binding<String>? {
        guard album.motionPolicy == .reducedMotion else {
            return nil
        }
        return metadataBinding(for: id)
    }

    private func displayedRecord(for id: PhotoID) -> PhotoRecord {
        album.record(for: id) ?? PhotoRecord(id: id, caption: "", metadata: "")
    }

    private var boundaryDescription: String {
        switch album.settledSurface {
        case .front(.coast):
            "Beginning of album · no previous surface"
        case .back(.night):
            "End of album · no next surface"
        default:
            "More album surfaces are available"
        }
    }
}

private struct PhotoFrontView: View {
    let record: PhotoRecord
    @Binding var caption: String
    let staticMetadata: Binding<String>?
    let isActive: Bool

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                SyntheticPhoto(id: record.id)
                    .frame(minHeight: 260)
                    .accessibilityHidden(true)

                TextField("Photo caption", text: $caption, axis: .vertical)
                    .font(.title2.weight(.semibold))
                    .textFieldStyle(.roundedBorder)
                    .accessibilityLabel("Caption for \(record.id.accessibilityLabel)")
                    .accessibilityIdentifier("photoCaptionField")

                if let staticMetadata {
                    TextField(
                        "Metadata",
                        text: staticMetadata,
                        axis: .vertical
                    )
                    .textFieldStyle(.roundedBorder)
                    .accessibilityLabel(
                        "Metadata for \(record.id.accessibilityLabel)"
                    )
                    .accessibilityIdentifier("photoMetadataField")

                    Text("Metadata remains editable because this mode shows the selected front without a curl turn.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }

                Text("Editing this caption refreshes only this photo front.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)

                if isActive {
                    Label("Current photo front", systemImage: "photo.fill")
                        .font(.footnote.weight(.semibold))
                        .foregroundStyle(.secondary)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(24)
        }
        .background(.background)
    }
}

private struct PhotoBackView: View {
    let record: PhotoRecord
    @Binding var metadata: String

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                Label("Photo metadata", systemImage: "info.circle.fill")
                    .font(.title2.bold())

                LabeledContent("Stable ID", value: record.id.rawValue)

                TextField("Metadata", text: $metadata, axis: .vertical)
                    .textFieldStyle(.roundedBorder)
                    .accessibilityLabel("Metadata for \(record.id.accessibilityLabel)")
                    .accessibilityIdentifier("photoMetadataField")

                Divider()

                Text("This image is generated from SwiftUI shapes and system symbols. No external or personal asset is included.")
                    .font(.body)
                Text("Editing metadata refreshes only this back surface.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(24)
        }
        .background(.background)
    }
}

private struct SyntheticPhoto: View {
    let id: PhotoID

    var body: some View {
        ZStack {
            LinearGradient(
                colors: id.gradientColors,
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            Circle()
                .fill(.white.opacity(0.18))
                .frame(width: 180, height: 180)
                .offset(x: 90, y: -70)
            RoundedRectangle(cornerRadius: 36)
                .fill(.black.opacity(0.12))
                .frame(width: 230, height: 100)
                .rotationEffect(.degrees(-12))
                .offset(x: -70, y: 105)
            Image(systemName: id.symbolName)
                .font(.system(size: 76, weight: .light))
                .foregroundStyle(.white.opacity(0.9))
        }
        .clipShape(RoundedRectangle(cornerRadius: 22))
    }
}

private func photoSurfaceAccessibilityValue(
    for surface: KLPageCurlSurface<PhotoID>
) -> String {
    switch surface {
    case .front(let id):
        "\(id.accessibilityLabel), editable photo front"
    case .back(let id):
        "\(id.accessibilityLabel), editable metadata back"
    }
}

private extension PhotoRecord {
    static let demoRecords = [
        PhotoRecord(id: .coast, caption: "Coastline study", metadata: "Synthetic frame 01 · coastal palette"),
        PhotoRecord(id: .canyon, caption: "Canyon light", metadata: "Synthetic frame 02 · sandstone palette"),
        PhotoRecord(id: .forest, caption: "Forest quiet", metadata: "Synthetic frame 03 · evergreen palette"),
        PhotoRecord(id: .city, caption: "City geometry", metadata: "Synthetic frame 04 · architectural palette"),
        PhotoRecord(id: .garden, caption: "Garden rhythm", metadata: "Synthetic frame 05 · botanical palette"),
        PhotoRecord(id: .night, caption: "Night signal", metadata: "Synthetic frame 06 · nocturnal palette"),
    ]
}

private extension PhotoID {
    var shortName: String {
        switch self {
        case .coast: "Coast"
        case .canyon: "Canyon"
        case .forest: "Forest"
        case .city: "City"
        case .garden: "Garden"
        case .night: "Night"
        }
    }

    var accessibilityLabel: String {
        "Synthetic \(shortName.lowercased()) photo"
    }

    var symbolName: String {
        switch self {
        case .coast: "water.waves"
        case .canyon: "mountain.2.fill"
        case .forest: "tree.fill"
        case .city: "building.2.fill"
        case .garden: "leaf.fill"
        case .night: "moon.stars.fill"
        }
    }

    var gradientColors: [Color] {
        switch self {
        case .coast: [.cyan, .blue]
        case .canyon: [.orange, .brown]
        case .forest: [.green, .teal]
        case .city: [.indigo, .gray]
        case .garden: [.pink, .green]
        case .night: [.purple, .black]
        }
    }
}
#endif
