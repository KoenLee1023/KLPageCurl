#if os(iOS)
import KLPageCurl
import SwiftUI

@main
struct BookPreviewDemoApp: App {
    var body: some Scene {
        WindowGroup {
            BookPreviewView()
        }
    }
}

private struct BookPreviewView: View {
    private let chapters = Chapter.allCases
    private let sequence = ChapterSequence(chapters: Chapter.allCases)

    @State private var displayState = BookPreviewDisplayState(
        selectedChapter: .one,
        settledSurface: .front(.one),
        motionPolicy: .curl
    )

    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                controls
                surfaceStatus
                pager
            }
            .padding()
            .navigationTitle("Book Preview")
        }
    }

    private var controls: some View {
        VStack(alignment: .leading, spacing: 12) {
            Picker("Chapter", selection: selectedChapterBinding) {
                ForEach(chapters) { chapter in
                    Text(chapter.pickerTitle).tag(chapter)
                }
            }
            .pickerStyle(.segmented)

            Toggle("Reduce Motion", isOn: reducedMotionBinding)
        }
    }

    private var surfaceStatus: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("VoiceOver value")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
            Text(surfaceAccessibilityValue(for: displayState.settledSurface))
                .font(.body)
            Text(boundaryDescription)
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 4)
        .accessibilityElement(children: .combine)
    }

    private var pager: some View {
        KLPageCurlPager(
            selection: selectedChapterBinding,
            sequence: sequence,
            revision: { surface in surface },
            front: { chapter, isActive in
                ChapterTextView(chapter: chapter, isActive: isActive)
            },
            back: { chapter in
                SourceNoteView(chapter: chapter)
            },
            configuration: .init(
                motionPolicy: displayState.motionPolicy,
                cache: .init(logicalRadius: 1)
            ),
            accessibility: .init(
                label: { $0.title },
                value: { surfaceAccessibilityValue(for: $0) },
                frontAnnouncement: { "\($0.title), text front" },
                backAnnouncement: { "\($0.title), source-note back" },
                previousActionName: "Previous chapter",
                nextActionName: "Next chapter"
            ),
            onSettled: { surface in
                displayState.didSettle(on: surface)
            }
        )
        .accessibilityIdentifier("bookPreviewPager")
        .clipShape(RoundedRectangle(cornerRadius: 18))
        .overlay {
            RoundedRectangle(cornerRadius: 18)
                .stroke(Color(uiColor: .separator), lineWidth: 1)
        }
    }

    private var boundaryDescription: String {
        switch displayState.settledSurface {
        case .front(.one):
            "Beginning of preview · no previous page"
        case .back(.three):
            "End of preview · no next page"
        default:
            "More preview pages are available"
        }
    }

    private var selectedChapterBinding: Binding<Chapter> {
        Binding(
            get: { displayState.selectedChapter },
            set: { displayState.didSelectChapter($0) }
        )
    }

    private var reducedMotionBinding: Binding<Bool> {
        Binding(
            get: { displayState.motionPolicy == .reducedMotion },
            set: { isReducedMotion in
                displayState.didChangeMotionPolicy(
                    isReducedMotion ? .reducedMotion : .curl
                )
            }
        )
    }
}

private struct ChapterTextView: View {
    let chapter: Chapter
    let isActive: Bool

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                Text(chapter.eyebrow)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
                Text(chapter.title)
                    .font(.largeTitle.bold())
                Text(chapter.text)
                    .font(.body)
                    .lineSpacing(6)
                if isActive {
                    Label("Current chapter", systemImage: "bookmark.fill")
                        .font(.footnote.weight(.semibold))
                        .foregroundStyle(.secondary)
                }
                if chapter == .one {
                    Text("This is the first page in the preview.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(28)
        }
        .background(.background)
    }
}

private struct SourceNoteView: View {
    let chapter: Chapter

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                Label("Source note", systemImage: "text.quote")
                    .font(.headline)
                Text(chapter.sourceNote)
                    .font(.body)
                    .lineSpacing(6)
                Divider()
                Text("Turn backward to revisit the chapter text.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                if chapter == .three {
                    Text("End of preview · there is no next chapter front.")
                        .font(.footnote.weight(.semibold))
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(28)
        }
        .background(.background)
    }
}

private func surfaceAccessibilityValue(
    for surface: KLPageCurlSurface<Chapter>
) -> String {
    switch surface {
    case .front(let chapter):
        "\(chapter.title), text front"
    case .back(let chapter):
        "\(chapter.title), source-note back"
    }
}

private extension Chapter {
    var pickerTitle: String {
        switch self {
        case .one: "One"
        case .two: "Two"
        case .three: "Three"
        }
    }

    var eyebrow: String {
        switch self {
        case .one: "CHAPTER ONE"
        case .two: "CHAPTER TWO"
        case .three: "CHAPTER THREE"
        }
    }

    var title: String {
        switch self {
        case .one: "The Quiet Shelf"
        case .two: "A Turn of the Page"
        case .three: "The Last Margin"
        }
    }

    var text: String {
        switch self {
        case .one:
            "A small book waited where the afternoon light reached the shelf. Its cover carried no promise beyond the invitation to begin."
        case .two:
            "The paper shifted beneath a careful hand. One side held the story; the other kept a note about where the words had come from."
        case .three:
            "At the final margin, the reader paused. The preview ended cleanly, without inventing another chapter beyond the book's finite edge."
        }
    }

    var sourceNote: String {
        switch self {
        case .one:
            "An original sample passage introducing the finite book preview."
        case .two:
            "An original sample passage demonstrating distinct front and back surfaces."
        case .three:
            "An original sample passage documenting the preview's final boundary."
        }
    }
}
#else
@main
enum BookPreviewDemoApp {
    static func main() {}
}
#endif
