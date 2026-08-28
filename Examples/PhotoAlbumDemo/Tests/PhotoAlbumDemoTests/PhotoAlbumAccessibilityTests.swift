#if os(iOS)
import KLPageCurl
import SwiftUI
import Testing
import UIKit
@testable import PhotoAlbumDemoApp

@MainActor
@Suite struct PhotoAlbumAccessibilityTests {
    @Test func `curl summary preserves editable front and back descendants`() async throws {
        let hierarchy = await makeHierarchy(motionPolicy: .curl)
        let curlController = try #require(
            descendantControllers(of: hierarchy.host).compactMap {
                $0 as? KLPageCurlViewController
            }.first
        )

        #expect(curlController.view.isAccessibilityElement == false)
        try expectSummaryAndActions(in: curlController.view)

        let frontHost = try #require(curlController.viewControllers?.first)
        try expectEditableField(
            identifier: "photoCaptionField",
            in: frontHost.view
        )

        let backHost = try #require(
            curlController.dataSource?.pageViewController(
                curlController,
                viewControllerAfter: frontHost
            )
        )
        backHost.loadViewIfNeeded()
        backHost.view.layoutIfNeeded()
        try expectEditableField(
            identifier: "photoMetadataField",
            in: backHost.view
        )

        _ = hierarchy.window
    }

    @Test func `static summary preserves both editors and truthful controls`() async throws {
        let hierarchy = await makeHierarchy(motionPolicy: .reducedMotion)
        let summary = try #require(
            allViews(in: hierarchy.host.view).first(where: isPageSummary)
        )

        #expect(summary.superview?.isAccessibilityElement == false)
        try expectSummaryAndActions(in: summary.superview)
        try expectEditableField(
            identifier: "photoCaptionField",
            in: hierarchy.host.view
        )
        try expectEditableField(
            identifier: "photoMetadataField",
            in: hierarchy.host.view
        )

        let reduceMotionControl = try #require(
            allViews(in: hierarchy.host.view).first {
                $0.accessibilityLabel == "Reduce Motion"
            }
        )
        #expect(
            reduceMotionControl.accessibilityHint ==
                "Show the selected photo front without a page curl"
        )

        _ = hierarchy.window
    }

    private func makeHierarchy(
        motionPolicy: KLPageCurlMotionPolicy
    ) async -> (window: UIWindow, host: UIHostingController<PhotoAlbumView>) {
        let host = UIHostingController(
            rootView: PhotoAlbumView(initialMotionPolicy: motionPolicy)
        )
        let window = UIWindow(frame: UIScreen.main.bounds)
        window.rootViewController = host
        window.isHidden = false
        host.loadViewIfNeeded()
        host.view.setNeedsLayout()
        host.view.layoutIfNeeded()
        await Task.yield()
        host.view.layoutIfNeeded()
        return (window, host)
    }

    private func expectSummaryAndActions(in root: UIView?) throws {
        let root = try #require(root)
        let summary = try #require(allViews(in: root).first(where: isPageSummary))

        #expect(summary.isAccessibilityElement)
        #expect(summary.accessibilityValue == "Synthetic coast photo, editable photo front")
        #expect(
            summary.accessibilityCustomActions?.map(\.name) == [
                "Previous photo",
                "Next photo",
            ]
        )
    }

    private func expectEditableField(
        identifier: String,
        in root: UIView
    ) throws {
        let field = try #require(
            allViews(in: root).first {
                $0.accessibilityIdentifier == identifier
            }
        )

        #expect(field.isAccessibilityElement)
        #expect(field is UITextField || field is UITextView)
    }

    private func isPageSummary(_ view: UIView) -> Bool {
        view.isAccessibilityElement &&
            view.accessibilityLabel == "Synthetic coast photo" &&
            view.accessibilityCustomActions?.count == 2
    }

    private func descendantControllers(
        of root: UIViewController
    ) -> [UIViewController] {
        var result: [UIViewController] = []
        for child in root.children {
            result.append(child)
            result.append(contentsOf: descendantControllers(of: child))
        }
        return result
    }

    private func allViews(in root: UIView) -> [UIView] {
        var result = [root]
        for subview in root.subviews {
            result.append(contentsOf: allViews(in: subview))
        }
        return result
    }
}
#endif
