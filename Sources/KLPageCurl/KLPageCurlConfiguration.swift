/// The host-selected motion behavior for page presentation.
public enum KLPageCurlMotionPolicy: Hashable, Sendable {
    /// Present interactive page-curl transitions where supported.
    case curl

    /// Present logical pages without a curl transition.
    case reducedMotion
}

/// The concrete presentation selected from a host-provided motion policy.
public enum KLPageCurlPresentation: Hashable, Sendable {
    /// Interactive, double-sided UIKit page curl.
    case curl

    /// A non-curl logical pager for reduced-motion presentation.
    case staticPager

    /// Resolves presentation without consulting application environment state.
    ///
    /// - Parameter policy: The motion policy already selected by the host.
    /// - Returns: Curl for ``KLPageCurlMotionPolicy/curl`` and a static pager for
    ///   ``KLPageCurlMotionPolicy/reducedMotion``.
    public static func resolve(
        for policy: KLPageCurlMotionPolicy
    ) -> KLPageCurlPresentation {
        switch policy {
        case .curl:
            .curl
        case .reducedMotion:
            .staticPager
        }
    }
}

struct KLPageCurlPresentationResources<Presentation, Feedback> {
    let presentation: Presentation
    let feedback: Feedback?

    static func make(
        for policy: KLPageCurlMotionPolicy,
        makeCurl: () -> Presentation,
        makeStaticPager: () -> Presentation,
        makeFeedback: () -> Feedback
    ) -> KLPageCurlPresentationResources {
        switch KLPageCurlPresentation.resolve(for: policy) {
        case .curl:
            KLPageCurlPresentationResources(
                presentation: makeCurl(),
                feedback: makeFeedback()
            )
        case .staticPager:
            KLPageCurlPresentationResources(
                presentation: makeStaticPager(),
                feedback: nil
            )
        }
    }
}

/// Top-level behavior shared by KLPageCurl presentation implementations.
public struct KLPageCurlConfiguration: Hashable, Sendable {
    /// The requested page-transition motion policy.
    public let motionPolicy: KLPageCurlMotionPolicy

    /// The bounded logical-page cache configuration.
    public let cache: KLPageCurlCacheConfiguration

    /// Creates page-curl behavior with host-selected motion and cache policies.
    ///
    /// - Parameters:
    ///   - motionPolicy: The presentation policy. The default is `curl`.
    ///   - cache: The bounded cache policy. The default logical radius is one.
    public init(
        motionPolicy: KLPageCurlMotionPolicy = .curl,
        cache: KLPageCurlCacheConfiguration = .init(logicalRadius: 1)
    ) {
        self.motionPolicy = motionPolicy
        self.cache = cache
    }
}
