/// Host-provided, localized accessibility content for logical page surfaces.
public struct KLPageCurlAccessibility<ID: Hashable & Sendable>: Sendable {
    /// Returns the shared label for a logical item.
    public let label: @Sendable (ID) -> String

    /// Returns a surface-specific value so front and back remain distinguishable.
    public let value: @Sendable (KLPageCurlSurface<ID>) -> String

    /// Returns the announcement for a completed front settle.
    public let frontAnnouncement: @Sendable (ID) -> String

    /// Returns the announcement for a completed back settle.
    public let backAnnouncement: @Sendable (ID) -> String

    /// Host-localized name for the logical previous action.
    public let previousActionName: String

    /// Host-localized name for the logical next action.
    public let nextActionName: String

    /// Creates a generic accessibility contract with no product vocabulary.
    ///
    /// All closures may run on the main actor through the iOS pager and must be
    /// safe to capture in a sendable value.
    ///
    /// - Parameters:
    ///   - label: Supplies the shared label for a logical item.
    ///   - value: Supplies a value that distinguishes its front and back.
    ///   - frontAnnouncement: Supplies the announcement after a front settles.
    ///   - backAnnouncement: Supplies the announcement after a back settles.
    ///   - previousActionName: The localized previous-action name.
    ///   - nextActionName: The localized next-action name.
    public init(
        label: @escaping @Sendable (ID) -> String,
        value: @escaping @Sendable (KLPageCurlSurface<ID>) -> String,
        frontAnnouncement: @escaping @Sendable (ID) -> String,
        backAnnouncement: @escaping @Sendable (ID) -> String,
        previousActionName: String,
        nextActionName: String
    ) {
        self.label = label
        self.value = value
        self.frontAnnouncement = frontAnnouncement
        self.backAnnouncement = backAnnouncement
        self.previousActionName = previousActionName
        self.nextActionName = nextActionName
    }

    func announcement(
        for outcome: KLPageCurlTransitionOutcome<ID>
    ) -> String? {
        guard case .settled(let surface, selection: _) = outcome else {
            return nil
        }

        switch surface {
        case .front(let id):
            return frontAnnouncement(id)
        case .back(let id):
            return backAnnouncement(id)
        }
    }
}

enum KLPageCurlAccessibilityAction: Sendable {
    case previous
    case next
}

enum KLPageCurlTransitionSideEffects {
    static func apply<ID: Hashable & Sendable>(
        outcome: KLPageCurlTransitionOutcome<ID>,
        accessibility: KLPageCurlAccessibility<ID>?,
        feedback: () -> Void,
        announce: (String) -> Void,
        onSettled: (KLPageCurlSurface<ID>) -> Void
    ) {
        guard case .settled(let surface, selection: _) = outcome else {
            return
        }

        feedback()
        if let announcement = accessibility?.announcement(for: outcome) {
            announce(announcement)
        }
        onSettled(surface)
    }
}
