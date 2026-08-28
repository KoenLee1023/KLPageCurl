import Foundation
import Testing

@Suite struct KLPageCurlBoundaryTests {
    private let locales = ["en", "ja", "ko", "zh-Hans", "zh-Hant"]
    private let documentationPages = [
        "KLPageCurl.md",
        "Articles/Surface-Sequence.md",
        "Articles/Recenter-and-Cache.md",
        "Articles/Accessibility-and-Motion.md",
        "Articles/KLPageCurl-Version.md",
    ]
    private let forbiddenBusinessSymbols = [
        "Note",
        "LifeCalendarEvent",
        "UserDefaults",
        "Calendar.current",
        "ToastManager",
        "Journal",
    ]
    private let generatedRepositoryNames = [
        ".build",
        "DerivedData",
        ".xcresult",
        ".swiftpm",
    ]

    @Test func `release boundary contains no host business dependencies`() throws {
        for sourceURL in try publicSourceURLs() {
            let source = try String(contentsOf: sourceURL)
            for symbol in forbiddenBusinessSymbols {
                #expect(!source.contains(symbol))
            }
        }
    }

    @Test func `release boundary includes required documentation`() throws {
        let catalogRoot = packageRoot.appending(path: "Sources/KLPageCurl/Documentation.docc")
        for page in documentationPages {
            #expect(FileManager.default.fileExists(atPath: catalogRoot.appending(path: page).path()))
        }

        for locale in locales {
            let guideRoot = packageRoot.appending(path: "Documentation/")
                .appending(path: locale)
            #expect(FileManager.default.fileExists(atPath: guideRoot.appending(path: "README.md").path()))
        }

        #expect(FileManager.default.fileExists(atPath: packageRoot.appending(path: "README.md").path()))
        #expect(FileManager.default.fileExists(atPath: packageRoot.appending(path: "CHANGELOG.md").path()))
    }

    @Test func `demo projects retain Xcode 77 format`() throws {
        for projectName in ["BookPreviewDemo", "PhotoAlbumDemo"] {
            let project = packageRoot
                .appending(path: "Examples")
                .appending(path: projectName)
                .appending(path: "\(projectName).xcodeproj/project.pbxproj")
            let content = try String(contentsOf: project)
            #expect(content.contains("objectVersion = 77;"))
        }
    }

    #if os(macOS)
    @Test func `tracked package files exclude private paths and generated junk`() throws {
        let trackedFiles = try trackedRepositoryFiles()

        for relativePath in trackedFiles {
            #expect(!relativePath.split(separator: "/").contains { generatedRepositoryNames.contains(String($0)) })
            let contentURL = packageRoot.appending(path: relativePath)
            guard !isBinaryFile(contentURL) else { continue }
            let content = try String(contentsOf: contentURL)
            #expect(privatePathLeak(in: content) == nil)
        }
    }
    #endif

    @Test func `private path detector catches generated forbidden fixtures`() {
        for component in ["Users", "Volumes", "private"] {
            let fixture = "/" + component + "/generated-fixture"
            #expect(privatePathLeak(in: fixture) != nil)
        }
    }

    private var packageRoot: URL {
        URL(filePath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .deletingLastPathComponent()
    }

    private func publicSourceURLs() throws -> [URL] {
        let sourceRoot = packageRoot.appending(path: "Sources/KLPageCurl")
        return try FileManager.default.contentsOfDirectory(
            at: sourceRoot,
            includingPropertiesForKeys: nil
        ).filter { $0.pathExtension == "swift" }
    }

    #if os(macOS)
    private func trackedRepositoryFiles() throws -> [String] {
        let process = Process()
        process.currentDirectoryURL = packageRoot
        process.executableURL = URL(filePath: "/usr/bin/git")
        process.arguments = ["ls-files", "-z"]

        let output = Pipe()
        process.standardOutput = output
        try process.run()
        process.waitUntilExit()
        #expect(process.terminationStatus == 0)

        let data = output.fileHandleForReading.readDataToEndOfFile()
        return String(decoding: data, as: UTF8.self)
            .split(separator: "\0")
            .map(String.init)
    }
    #endif

    private func isBinaryFile(_ url: URL) -> Bool {
        guard let data = try? Data(contentsOf: url) else { return false }
        return data.contains(0)
    }

    private func privatePathLeak(in content: String) -> String? {
        privatePathPrefixes.first { content.contains($0) }
    }

    private var privatePathPrefixes: [String] {
        ["Users", "Volumes", "private"].map { "/" + $0 + "/" }
    }
}
