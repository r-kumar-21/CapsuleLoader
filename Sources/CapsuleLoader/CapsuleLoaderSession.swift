/// Counts overlapping `show` / `hide` calls so the loader stays up
/// until every in-flight request has finished.
struct CapsuleLoaderSession: Equatable {
    private(set) var count = 0

    var isVisible: Bool { count > 0 }

    /// Returns true when the loader should appear.
    mutating func show() -> Bool {
        count += 1
        return count == 1
    }

    /// Returns true when the loader should disappear.
    /// Extra hides, with nothing showing, are ignored.
    mutating func hide() -> Bool {
        guard count > 0 else { return false }
        count -= 1
        return count == 0
    }

    /// Returns true when a visible loader should disappear.
    mutating func hideAll() -> Bool {
        let wasVisible = isVisible
        count = 0
        return wasVisible
    }
}
