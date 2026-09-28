# Changelog

All notable changes to this project are documented here.
The format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [1.0.0] - 2026-09-29

### Added
- `CapsuleLoader` global loader with `show`, `hide`, `hideAll`, and `run`.
- Nested show/hide counting for overlapping requests.
- Sliding capsule bar and rotating ring indicator styles.
- Determinate progress via `setProgress(_:animated:)`.
- Host-view presentation with `show(_:style:in:)`.
- SwiftUI `.capsuleLoader(isPresented:)` modifier.
- Inline `CapsuleProgressBar` / `CapsuleSpinner` (SwiftUI) and `CapsuleProgressBarView` / `CapsuleSpinnerView` (UIKit).
- VoiceOver announcements, Dynamic Type, and light/dark mode support.
- Privacy manifest (`PrivacyInfo.xcprivacy`) declaring no tracking or data collection.

[Unreleased]: https://github.com/r-kumar-21/CapsuleLoader/compare/1.0.0...HEAD
[1.0.0]: https://github.com/r-kumar-21/CapsuleLoader/releases/tag/1.0.0
