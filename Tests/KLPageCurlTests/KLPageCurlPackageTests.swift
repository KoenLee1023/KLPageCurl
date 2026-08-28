import Testing
@testable import KLPageCurl

@Suite struct KLPageCurlPackageTests {
    @Test func `package exposes its public module`() {
        #expect(KLPageCurlVersion.current == "0.1.0")
    }
}
