# ``CapsuleLoader``

A macOS-inspired loading panel for iOS, with a sliding capsule bar and a rotating ring.

## Overview

Show the loader when an API call starts, and hide it when the call finishes.
Overlapping calls are counted, so the panel stays up until every request is done.

```swift
let posts = try await CapsuleLoader.run("Loading") {
    try await api.posts()
}
```

In SwiftUI, drive it from state:

```swift
List(posts) { Text($0.title) }
    .capsuleLoader(isPresented: isLoading, message: "Loading")
```

## Topics

### Showing the loader

- ``CapsuleLoader/show(_:style:)``
- ``CapsuleLoader/show(_:style:in:)``
- ``CapsuleLoader/run(_:style:operation:)``
- ``CapsuleLoader/hide()``
- ``CapsuleLoader/hideAll()``

### Customizing

- ``CapsuleLoader/Style``
- ``CapsuleLoader/Appearance``
- ``CapsuleLoader/configure(_:)``
- ``CapsuleLoader/setIndicatorColor(_:)``
- ``CapsuleLoader/setProgress(_:animated:)``

### Inline indicators

- ``CapsuleProgressBar``
- ``CapsuleSpinner``
- ``CapsuleProgressBarView``
- ``CapsuleSpinnerView``
