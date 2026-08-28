#if os(iOS)
import SwiftUI
import UIKit

@available(iOS 17.0, *)
private final class KLPageCurlAccessibilitySummaryView: UIView {
    init() {
        super.init(frame: .zero)
        backgroundColor = .clear
        isAccessibilityElement = true
        isUserInteractionEnabled = false
        translatesAutoresizingMaskIntoConstraints = false
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) is unavailable")
    }
}

@available(iOS 17.0, *)
@MainActor
extension KLPageCurlPager.Coordinator {
    func makeStaticHost() -> UIHostingController<AnyView> {
        let host = UIHostingController(
            rootView: AnyView(
                parent.frontBuilder(state.currentSelection, true)
            )
        )
        host.view.backgroundColor = .clear
        return host
    }

    func refreshStaticHost() {
        guard let staticHost else {
            return
        }
        staticHost.rootView = AnyView(
            parent.frontBuilder(state.currentSelection, true)
        )
        configureAccessibility(
            on: staticHost.view,
            surface: .front(state.currentSelection)
        )
    }

    func replaceChild(
        of container: UIViewController,
        with child: UIViewController
    ) {
        for existingChild in container.children {
            existingChild.willMove(toParent: nil)
            existingChild.view.removeFromSuperview()
            existingChild.removeFromParent()
        }

        container.addChild(child)
        child.view.translatesAutoresizingMaskIntoConstraints = false
        container.view.addSubview(child.view)
        NSLayoutConstraint.activate([
            child.view.leadingAnchor.constraint(equalTo: container.view.leadingAnchor),
            child.view.trailingAnchor.constraint(equalTo: container.view.trailingAnchor),
            child.view.topAnchor.constraint(equalTo: container.view.topAnchor),
            child.view.bottomAnchor.constraint(equalTo: container.view.bottomAnchor),
        ])
        child.didMove(toParent: container)
    }

    func configureAccessibility(
        on view: UIView,
        surface: KLPageCurlSurface<ID>
    ) {
        view.isAccessibilityElement = false
        view.accessibilityLabel = nil
        view.accessibilityValue = nil
        view.accessibilityCustomActions = nil

        let existingSummary = view.subviews.compactMap {
            $0 as? KLPageCurlAccessibilitySummaryView
        }.first
        guard let accessibility = parent.accessibility else {
            existingSummary?.removeFromSuperview()
            return
        }

        let summary = existingSummary ?? makeAccessibilitySummary(in: view)
        summary.accessibilityLabel = accessibility.label(surface.id)
        summary.accessibilityValue = accessibility.value(surface)
        summary.accessibilityCustomActions = [
            UIAccessibilityCustomAction(
                name: accessibility.previousActionName,
                actionHandler: { [weak self] _ in
                    self?.performAccessibilityAction(.previous) ?? false
                }
            ),
            UIAccessibilityCustomAction(
                name: accessibility.nextActionName,
                actionHandler: { [weak self] _ in
                    self?.performAccessibilityAction(.next) ?? false
                }
            ),
        ]
    }

    private func makeAccessibilitySummary(
        in view: UIView
    ) -> KLPageCurlAccessibilitySummaryView {
        let summary = KLPageCurlAccessibilitySummaryView()
        view.addSubview(summary)
        NSLayoutConstraint.activate([
            summary.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            summary.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            summary.topAnchor.constraint(equalTo: view.topAnchor),
            summary.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ])
        return summary
    }

    private func performAccessibilityAction(
        _ action: KLPageCurlAccessibilityAction
    ) -> Bool {
        guard parent.accessibility != nil else {
            return false
        }
        guard let recenter = state.performAccessibilityAction(action) else {
            return false
        }

        parent.selection = state.currentSelection
        apply(recenter: recenter)
        applyTransitionSideEffects(outcome: recenter.outcome)
        return true
    }

    func applyTransitionSideEffects(
        outcome: KLPageCurlTransitionOutcome<ID>
    ) {
        KLPageCurlTransitionSideEffects.apply(
            outcome: outcome,
            accessibility: parent.accessibility,
            feedback: { feedbackGenerator?.impactOccurred() },
            announce: {
                UIAccessibility.post(notification: .pageScrolled, argument: $0)
            },
            onSettled: parent.onSettled
        )
    }
}
#endif
