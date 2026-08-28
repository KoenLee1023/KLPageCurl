struct KLPageCurlAnySequence<ID: Hashable & Sendable>: KLPageCurlSequence {
    private let initialSurfaceProvider: @Sendable (ID) -> KLPageCurlSurface<ID>
    private let adjacentSurfaceProvider: @Sendable (
        KLPageCurlSurface<ID>,
        KLPageCurlDirection
    ) -> KLPageCurlSurface<ID>?

    init<PageSequence: KLPageCurlSequence<ID>>(_ sequence: PageSequence) {
        initialSurfaceProvider = { selection in
            sequence.initialSurface(for: selection)
        }
        adjacentSurfaceProvider = { surface, direction in
            sequence.adjacent(to: surface, direction: direction)
        }
    }

    func initialSurface(for selection: ID) -> KLPageCurlSurface<ID> {
        initialSurfaceProvider(selection)
    }

    func adjacent(
        to surface: KLPageCurlSurface<ID>,
        direction: KLPageCurlDirection
    ) -> KLPageCurlSurface<ID>? {
        adjacentSurfaceProvider(surface, direction)
    }
}

#if os(iOS)
import SwiftUI
import UIKit

/// The UIKit page-view controller used by ``KLPageCurlPager``.
@available(iOS 17.0, *)
@MainActor
public final class KLPageCurlViewController: UIPageViewController {
    /// Creates a horizontal, minimum-spine, double-sided page-curl controller.
    ///
    /// Call this initializer and all instance methods on the main actor. The
    /// controller is available on iOS 17 and later.
    public init() {
        super.init(
            transitionStyle: .pageCurl,
            navigationOrientation: .horizontal,
            options: [.spineLocation: SpineLocation.min.rawValue]
        )
        isDoubleSided = true
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) is unavailable")
    }

    /// Makes every page gesture wait for the supplied interactive-pop gesture.
    ///
    /// The navigation host owns the recognizer and any leading-edge threshold.
    ///
    /// - Parameter popGesture: The host navigation controller's pop recognizer.
    public func installInteractivePopPriority(using popGesture: UIGestureRecognizer) {
        let pageGestures = gestureRecognizers.filter { $0 !== popGesture }
        KLPageCurlGesturePriority.install(
            pageGestures: pageGestures,
            popGesture: popGesture,
            requireFailure: { pageGesture, popGesture in
                pageGesture.require(toFail: popGesture)
            }
        )
    }

    /// Installs priority for the containing navigation controller's pop gesture.
    public override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if let popGesture = navigationController?.interactivePopGestureRecognizer {
            installInteractivePopPriority(using: popGesture)
        }
    }
}

/// A generic SwiftUI pager with curl and reduced-motion static presentations.
///
/// Logical selection changes only after a front surface settles. Programmatic
/// selection synchronously recenters the controller and its bounded cache.
/// The type is main-actor isolated and available on iOS 17 and later.
@available(iOS 17.0, *)
@MainActor
public struct KLPageCurlPager<
    ID: Hashable & Sendable,
    Front: View,
    Back: View
>: UIViewControllerRepresentable {
    /// The currently committed logical page identifier.
    ///
    /// The pager writes this binding only after a front settles. A host write
    /// atomically recenters an idle pager on the sequence's initial surface.
    @Binding public var selection: ID

    private let sequence: KLPageCurlAnySequence<ID>
    private let configuration: KLPageCurlConfiguration
    let accessibility: KLPageCurlAccessibility<ID>?
    let frontBuilder: (ID, Bool) -> Front
    private let backBuilder: (ID) -> Back
    let onSettled: (KLPageCurlSurface<ID>) -> Void
    private let recordRevision: (
        inout KLPageCurlRevisionIndex<ID>,
        KLPageCurlSurface<ID>
    ) -> Void
    private let decideRevision: (
        KLPageCurlRevisionIndex<ID>,
        KLPageCurlSurface<ID>,
        Bool
    ) -> KLPageCurlRefreshDecision

    /// Creates a page-curl container from host-provided sequence and surfaces.
    ///
    /// - Parameters:
    ///   - selection: The committed logical selection binding.
    ///   - sequence: The source of front/back adjacency and finite boundaries.
    ///   - revision: A stable revision for each surface.
    ///   - front: Builds a front surface; the Boolean is true when it is active.
    ///   - back: Builds a back surface.
    ///   - configuration: Motion and bounded-cache configuration.
    ///   - accessibility: Optional host-localized accessibility content.
    ///   - onSettled: Called after either front or back completes settling.
    ///
    /// The default configuration uses curl motion and cache radius one. The
    /// default accessibility value is `nil`, and the default settle callback
    /// does nothing. All builders and callbacks execute on the main actor.
    public init<PageSequence: KLPageCurlSequence<ID>, Revision: Hashable & Sendable>(
        selection: Binding<ID>,
        sequence: PageSequence,
        revision: @escaping @Sendable (KLPageCurlSurface<ID>) -> Revision,
        front: @escaping (ID, Bool) -> Front,
        back: @escaping (ID) -> Back,
        configuration: KLPageCurlConfiguration = .init(),
        accessibility: KLPageCurlAccessibility<ID>? = nil,
        onSettled: @escaping (KLPageCurlSurface<ID>) -> Void = { _ in }
    ) {
        _selection = selection
        self.sequence = KLPageCurlAnySequence(sequence)
        self.configuration = configuration
        self.accessibility = accessibility
        frontBuilder = front
        backBuilder = back
        self.onSettled = onSettled
        recordRevision = { index, surface in
            index.record(revision(surface), for: surface)
        }
        decideRevision = { index, surface, isTransitioning in
            index.refreshDecision(
                revision: revision(surface),
                surface: surface,
                isTransitioning: isTransitioning
            )
        }
    }

    /// Creates the main-actor coordinator that owns transition, cache, and revision state.
    public func makeCoordinator() -> Coordinator {
        Coordinator(parent: self)
    }

    /// Creates a neutral container and installs the selected presentation.
    ///
    /// - Parameter context: SwiftUI's representable creation context.
    /// - Returns: A container hosting either the curl or static presentation.
    public func makeUIViewController(context: Context) -> UIViewController {
        let container = UIViewController()
        context.coordinator.connect(parent: self, container: container)
        return container
    }

    /// Applies host updates and atomically recenters changed selection.
    ///
    /// - Parameters:
    ///   - container: The container created by ``makeUIViewController(context:)``.
    ///   - context: SwiftUI's representable update context.
    public func updateUIViewController(
        _ container: UIViewController,
        context: Context
    ) {
        context.coordinator.receive(parent: self, container: container)
    }

    /// Coordinates UIKit delegates with the pure state and cache reducers.
    @MainActor
    public final class Coordinator: NSObject,
        UIPageViewControllerDataSource,
        UIPageViewControllerDelegate
    {
        var parent: KLPageCurlPager
        var state: KLPageCurlControllerState<ID, KLPageCurlAnySequence<ID>>
        private var hosts = KLPageCurlHostCache<
            ID,
            UIHostingController<AnyView>
        >()
        private var curlController: KLPageCurlViewController?
        var staticHost: UIHostingController<AnyView>?
        var feedbackGenerator: UIImpactFeedbackGenerator?
        private var presentation: KLPageCurlPresentation?

        fileprivate init(parent: KLPageCurlPager) {
            self.parent = parent
            state = KLPageCurlControllerState(
                initialSelection: parent.selection,
                sequence: parent.sequence,
                cacheConfiguration: parent.configuration.cache
            )
        }

        fileprivate func connect(
            parent: KLPageCurlPager,
            container: UIViewController
        ) {
            self.parent = parent
            installPresentation(in: container)
        }

        fileprivate func receive(
            parent: KLPageCurlPager,
            container: UIViewController
        ) {
            self.parent = parent
            let updatePlan = state.update(
                sequence: parent.sequence,
                cacheConfiguration: parent.configuration.cache
            )
            let resolvedPresentation = KLPageCurlPresentation.resolve(
                for: parent.configuration.motionPolicy
            )
            let presentationChanged = presentation != resolvedPresentation
            let recenter = state.requestRecenter(on: parent.selection)
            let transitionAbort = state.abortTransitionForPresentationChange(
                from: presentation,
                to: resolvedPresentation
            )
            let postAbortPlan: KLPageCurlCachePlan<ID>?
            if transitionAbort != nil {
                postAbortPlan = state.replanIfIdle()
            } else {
                postAbortPlan = nil
            }
            let updateSurfacesToPreload = hosts.applyUpdatePlan(
                updatePlan,
                presentation: resolvedPresentation,
                isSupersededByRecenter: recenter != nil ||
                    transitionAbort?.recenter != nil ||
                    postAbortPlan != nil
            )
            _ = hosts.applyUpdatePlan(
                postAbortPlan,
                presentation: resolvedPresentation,
                isSupersededByRecenter: false
            )

            if presentationChanged {
                _ = hosts.applyRecenterPlans(
                    [recenter, transitionAbort?.recenter],
                    presentation: resolvedPresentation
                )
                installPresentation(in: container)
                return
            }

            if updatePlan != nil, resolvedPresentation == .curl, recenter == nil {
                preloadHosts(updateSurfacesToPreload)
            }

            if let recenter {
                apply(recenter: recenter)
            } else if !state.isTransitioning, let curlController {
                refreshVisibleSurfaceIfIdle(controller: curlController)
                configureAccessibility(
                    on: curlController.view,
                    surface: state.currentSurface
                )
            } else if presentation == .staticPager {
                refreshStaticHost()
            }
        }

        private func installPresentation(in container: UIViewController) {
            let resolvedPresentation = KLPageCurlPresentation.resolve(
                for: parent.configuration.motionPolicy
            )
            if
                resolvedPresentation == .staticPager,
                state.currentSurface != .front(state.currentSelection)
            {
                let recenter = state.recenter(on: state.currentSelection)
                _ = hosts.applyRecenterPlans(
                    [recenter],
                    presentation: .staticPager
                )
            }
            let resources: KLPageCurlPresentationResources<
                UIViewController,
                UIImpactFeedbackGenerator
            > = .make(
                for: parent.configuration.motionPolicy,
                makeCurl: { KLPageCurlViewController() },
                makeStaticPager: { self.makeStaticHost() },
                makeFeedback: { UIImpactFeedbackGenerator(style: .light) }
            )

            presentation = resolvedPresentation
            feedbackGenerator = resources.feedback
            replaceChild(of: container, with: resources.presentation)

            switch resolvedPresentation {
            case .curl:
                guard let controller = resources.presentation as? KLPageCurlViewController else {
                    return
                }
                staticHost = nil
                curlController = controller
                controller.dataSource = self
                controller.delegate = self
                let plan = state.cachePlan()
                apply(plan: plan)
                let center = host(for: state.currentSurface)
                controller.setViewControllers(
                    [center],
                    direction: .forward,
                    animated: false
                )
                configureAccessibility(
                    on: controller.view,
                    surface: state.currentSurface
                )
            case .staticPager:
                curlController = nil
                guard let host = resources.presentation as? UIHostingController<AnyView> else {
                    return
                }
                staticHost = host
                refreshStaticHost()
            }
        }

        func apply(recenter: KLPageCurlControllerRecenter<ID>) {
            state.applyCachePlan(recenter.cachePlan)
            let surfacesToPreload = hosts.applyRecenterPlans(
                [recenter],
                presentation: presentation ?? .staticPager
            )
            switch presentation {
            case .curl:
                preloadHosts(surfacesToPreload)
                guard let curlController else {
                    return
                }
                let center = host(for: state.currentSurface)
                curlController.setViewControllers(
                    [center],
                    direction: .forward,
                    animated: false
                )
                configureAccessibility(
                    on: curlController.view,
                    surface: state.currentSurface
                )
            case .staticPager:
                refreshStaticHost()
            case nil:
                break
            }
        }

        private func apply(plan: KLPageCurlCachePlan<ID>) {
            state.applyCachePlan(plan)
            hosts.apply(plan: plan)
            preloadHosts(plan.surfacesToPreload)
        }

        private func preloadHosts(
            _ surfaces: [KLPageCurlSurface<ID>]
        ) {
            for surface in surfaces {
                _ = host(for: surface)
            }
            synchronizeRetainedFrontActivity()
        }

        private func synchronizeRetainedFrontActivity() {
            let activeFront = state.currentSurface.isFront ? state.currentSurface : nil
            let frontBuilder = parent.frontBuilder
            let refreshedSurfaces = hosts.synchronizeFrontActivity(
                activeFront: activeFront,
                updateRoot: { surface, host, isActive in
                    guard case .front(let id) = surface else {
                        return
                    }
                    host.rootView = AnyView(frontBuilder(id, isActive))
                }
            )
            for surface in refreshedSurfaces {
                state.didCache(surface, recordRevision: parent.recordRevision)
            }
        }

        private func host(
            for surface: KLPageCurlSurface<ID>
        ) -> UIHostingController<AnyView> {
            let decision = state.refreshDecision(
                surface: surface,
                decideRevision: parent.decideRevision
            )
            let frontBuilder = parent.frontBuilder
            let backBuilder = parent.backBuilder
            let rootView: (Bool) -> AnyView = { isActive in
                switch surface {
                case .front(let id):
                    AnyView(frontBuilder(id, isActive))
                case .back(let id):
                    AnyView(backBuilder(id))
                }
            }

            var didRefresh = false
            let host = hosts.resolve(
                surface: surface,
                isActive: surface.isFront && surface == state.currentSurface,
                revisionDecision: decision,
                makeHost: { isActive in
                    let host = UIHostingController(rootView: rootView(isActive))
                    host.view.backgroundColor = .clear
                    return host
                },
                updateRoot: { host, isActive in
                    host.rootView = rootView(isActive)
                },
                didRefresh: {
                    didRefresh = true
                }
            )
            if didRefresh {
                state.didCache(surface, recordRevision: parent.recordRevision)
            }
            return host
        }

        private func surface(
            for controller: UIViewController
        ) -> KLPageCurlSurface<ID>? {
            guard let host = controller as? UIHostingController<AnyView> else {
                return nil
            }
            return hosts.surface(for: host)
        }

        private func refreshVisibleSurfaceIfIdle(controller: KLPageCurlViewController) {
            guard
                !state.isTransitioning,
                let visibleController = controller.viewControllers?.first,
                let visibleSurface = surface(for: visibleController)
            else {
                return
            }

            let refreshed = host(for: visibleSurface)
            if refreshed !== visibleController {
                controller.setViewControllers(
                    [refreshed],
                    direction: .forward,
                    animated: false
                )
            }
        }

        /// Returns the preceding cached or newly built surface at a finite boundary.
        public func pageViewController(
            _ pageViewController: UIPageViewController,
            viewControllerBefore viewController: UIViewController
        ) -> UIViewController? {
            guard
                let surface = surface(for: viewController),
                let previous = state.surface(before: surface)
            else {
                return nil
            }
            return host(for: previous)
        }

        /// Returns the following cached or newly built surface at a finite boundary.
        public func pageViewController(
            _ pageViewController: UIPageViewController,
            viewControllerAfter viewController: UIViewController
        ) -> UIViewController? {
            guard
                let surface = surface(for: viewController),
                let next = state.surface(after: surface)
            else {
                return nil
            }
            return host(for: next)
        }

        /// Records the pending surface before UIKit begins an interactive turn.
        public func pageViewController(
            _ pageViewController: UIPageViewController,
            willTransitionTo pendingViewControllers: [UIViewController]
        ) {
            guard
                let pendingController = pendingViewControllers.first,
                let pendingSurface = surface(for: pendingController)
            else {
                return
            }
            state.beginTransition(to: pendingSurface)
        }

        /// Commits or cancels a UIKit turn, then reconciles selection and cache.
        public func pageViewController(
            _ pageViewController: UIPageViewController,
            didFinishAnimating finished: Bool,
            previousViewControllers: [UIViewController],
            transitionCompleted completed: Bool
        ) {
            let finish = state.finishTransitionAndReconcile(completed: completed)
            guard let controller = pageViewController as? KLPageCurlViewController else {
                return
            }

            switch finish.transitionOutcome {
            case .cancelled:
                break
            case .settled(surface: _, selection: _):
                if let selection = finish.selectionToCommit {
                    parent.selection = selection
                }
                applyTransitionSideEffects(outcome: finish.transitionOutcome)
            case .ignored, .recentered:
                return
            }

            if let recenter = finish.recenter {
                apply(recenter: recenter)
                return
            }

            apply(plan: state.cachePlan())
            refreshVisibleSurfaceIfIdle(controller: controller)
            configureAccessibility(
                on: controller.view,
                surface: state.currentSurface
            )
        }

        /// Keeps the page-curl controller on its minimum spine.
        public func pageViewController(
            _ pageViewController: UIPageViewController,
            spineLocationFor orientation: UIInterfaceOrientation
        ) -> UIPageViewController.SpineLocation {
            .min
        }
    }
}
#endif
