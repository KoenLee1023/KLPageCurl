/// The stable or in-flight state of a page-surface transition.
public enum KLPageCurlTransitionState<ID: Hashable & Sendable>: Equatable, Sendable {
    /// No transition is active and the associated surface is displayed.
    case idle(KLPageCurlSurface<ID>)

    /// A transition is moving from the displayed surface toward a pending one.
    case transitioning(
        from: KLPageCurlSurface<ID>,
        pending: KLPageCurlSurface<ID>
    )
}

/// The observable outcome of completing or rejecting a state-machine event.
public enum KLPageCurlTransitionOutcome<ID: Hashable & Sendable>: Equatable, Sendable {
    /// A transition completed on a surface.
    ///
    /// `selection` is non-`nil` only when a front surface settles.
    case settled(surface: KLPageCurlSurface<ID>, selection: ID?)

    /// A transition was cancelled and restored its origin surface.
    case cancelled(surface: KLPageCurlSurface<ID>)

    /// A programmatic selection synchronously replaced the idle center.
    case recentered(surface: KLPageCurlSurface<ID>, selection: ID)

    /// The event was not valid for the current transition state.
    case ignored
}

/// A UIKit-independent reducer for page turns and programmatic selection.
public struct KLPageCurlStateMachine<ID: Hashable & Sendable>: Sendable {
    /// The current transition state, mutated only by reducer operations.
    public private(set) var state: KLPageCurlTransitionState<ID>

    /// The last committed logical selection.
    ///
    /// A back settle leaves this value unchanged. A front settle or successful
    /// idle recenter replaces it.
    public private(set) var currentSelection: ID

    /// The surface currently displayed to the user.
    ///
    /// During a transition this remains the origin until the transition settles.
    public var currentSurface: KLPageCurlSurface<ID> {
        switch state {
        case .idle(let surface), .transitioning(from: let surface, pending: _):
            surface
        }
    }

    /// Creates an idle state on the sequence's initial surface.
    ///
    /// - Parameters:
    ///   - initialSelection: The initial committed logical selection.
    ///   - sequence: The sequence that maps that selection to its first surface.
    public init(
        initialSelection: ID,
        sequence: some KLPageCurlSequence<ID>
    ) {
        currentSelection = initialSelection
        state = .idle(sequence.initialSurface(for: initialSelection))
    }

    /// Begins a transition from the current idle surface.
    ///
    /// - Parameter pending: The surface expected to settle if the transition
    ///   completes.
    /// - Returns: `true` when the transition began; otherwise `false` when a
    ///   transition was already active or the destination was already displayed.
    @discardableResult
    public mutating func beginTransition(to pending: KLPageCurlSurface<ID>) -> Bool {
        guard case .idle(let current) = state, current != pending else {
            return false
        }

        state = .transitioning(from: current, pending: pending)
        return true
    }

    /// Completes or cancels the active transition.
    ///
    /// A completed back surface does not commit logical selection. A completed
    /// front surface commits its identifier.
    ///
    /// - Parameter completed: `true` to settle on the pending surface; `false`
    ///   to restore the transition origin.
    /// - Returns: The settled or cancelled surface, or `ignored` if idle.
    public mutating func finishTransition(
        completed: Bool
    ) -> KLPageCurlTransitionOutcome<ID> {
        guard case .transitioning(let from, let pending) = state else {
            return .ignored
        }

        guard completed else {
            state = .idle(from)
            return .cancelled(surface: from)
        }

        state = .idle(pending)
        guard pending.isFront else {
            return .settled(surface: pending, selection: nil)
        }

        currentSelection = pending.id
        return .settled(surface: pending, selection: pending.id)
    }

    /// Atomically replaces an idle center with a programmatic logical selection.
    ///
    /// Recenter requests during an active transition are ignored without changing
    /// either transition state or logical selection.
    ///
    /// - Parameters:
    ///   - selection: The new committed logical selection.
    ///   - sequence: The sequence that supplies its initial surface.
    /// - Returns: `recentered` with the new surface and selection while idle;
    ///   otherwise `ignored`.
    public mutating func recenter(
        on selection: ID,
        sequence: some KLPageCurlSequence<ID>
    ) -> KLPageCurlTransitionOutcome<ID> {
        guard case .idle = state else {
            return .ignored
        }

        let surface = sequence.initialSurface(for: selection)
        state = .idle(surface)
        currentSelection = selection
        return .recentered(surface: surface, selection: selection)
    }
}
