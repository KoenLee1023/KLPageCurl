/// One displayable side of a logical page.
///
/// A logical page has a front and a back that share the same identifier.
public enum KLPageCurlSurface<ID: Hashable & Sendable>: Hashable, Sendable {
    /// The front side of the identified logical page.
    case front(ID)

    /// The back side of the identified logical page.
    case back(ID)

    /// The logical page identifier shared by both sides.
    public var id: ID {
        switch self {
        case .front(let id), .back(let id):
            id
        }
    }

    /// Whether this surface is the front side of its logical page.
    public var isFront: Bool {
        switch self {
        case .front:
            true
        case .back:
            false
        }
    }
}

/// A direction through the ordered sequence of page surfaces.
public enum KLPageCurlDirection: Hashable, Sendable {
    /// Move toward the preceding surface.
    case before

    /// Move toward the following surface.
    case after
}

/// Supplies initial and adjacent surfaces for logical page identifiers.
///
/// Implementations own ordering and boundary behavior. Returning `nil` from
/// ``adjacent(to:direction:)`` marks a finite boundary.
public protocol KLPageCurlSequence<ID>: Sendable {
    /// The logical identifier represented by the sequence.
    associatedtype ID: Hashable & Sendable

    /// Returns the surface from which the supplied logical selection starts.
    ///
    /// - Parameter selection: The host's committed logical selection.
    /// - Returns: The initial surface, normally the selection's front.
    func initialSurface(for selection: ID) -> KLPageCurlSurface<ID>

    /// Returns the adjacent surface, or `nil` at a finite boundary.
    ///
    /// - Parameters:
    ///   - surface: The surface from which navigation starts.
    ///   - direction: Whether to request the preceding or following surface.
    /// - Returns: The adjacent surface, or `nil` when the sequence ends.
    func adjacent(
        to surface: KLPageCurlSurface<ID>,
        direction: KLPageCurlDirection
    ) -> KLPageCurlSurface<ID>?
}

/// A deterministic finite sequence backed by ordered logical identifiers.
public struct KLFinitePageCurlSequence<ID: Hashable & Sendable>: KLPageCurlSequence {
    /// The unique logical page identifiers in navigation order.
    public let orderedIDs: [ID]

    /// Creates a finite sequence from identifiers in navigation order.
    ///
    /// The first occurrence of each identifier is preserved. Later duplicates
    /// are ignored so every logical page has one deterministic sequence position.
    ///
    /// - Parameter orderedIDs: Logical identifiers in front-to-back navigation
    ///   order. The collection may be empty.
    public init(orderedIDs: [ID]) {
        var seen: Set<ID> = []
        var uniqueIDs: [ID] = []
        uniqueIDs.reserveCapacity(orderedIDs.count)

        for id in orderedIDs {
            if seen.insert(id).inserted {
                uniqueIDs.append(id)
            }
        }

        self.orderedIDs = uniqueIDs
    }

    /// Starts each logical selection on its front surface.
    ///
    /// The selection need not occur in ``orderedIDs``. Such a surface has no
    /// neighbors until the sequence is replaced with one containing its ID.
    public func initialSurface(for selection: ID) -> KLPageCurlSurface<ID> {
        .front(selection)
    }

    /// Walks front-to-back within an item and back-to-front between items.
    ///
    /// Moving after a front returns its back; moving after a back returns the
    /// next front. Reverse movement applies the inverse order. The method
    /// returns `nil` for an unknown ID, before the first front, and after the
    /// last back.
    public func adjacent(
        to surface: KLPageCurlSurface<ID>,
        direction: KLPageCurlDirection
    ) -> KLPageCurlSurface<ID>? {
        guard let index = orderedIDs.firstIndex(of: surface.id) else {
            return nil
        }

        switch (surface, direction) {
        case (.front(let id), .after):
            return .back(id)
        case (.back(let id), .before):
            return .front(id)
        case (.front, .before):
            guard index > orderedIDs.startIndex else {
                return nil
            }
            return .back(orderedIDs[orderedIDs.index(before: index)])
        case (.back, .after):
            let nextIndex = orderedIDs.index(after: index)
            guard nextIndex < orderedIDs.endIndex else {
                return nil
            }
            return .front(orderedIDs[nextIndex])
        }
    }
}
