# Contributing

Thanks for helping improve CapsuleLoader.

## Getting started

1. Fork the repository and create a branch from `main`.
2. Open `Package.swift` in Xcode, or open `Example/CapsuleLoaderExample.xcodeproj` to try changes in the demo app.
3. Run the tests on an iOS simulator:

   ```bash
   xcodebuild test -scheme CapsuleLoader -destination 'platform=iOS Simulator,name=iPhone 17'
   ```

## Guidelines

- Keep the public API small. Discuss new API in an issue before opening a pull request.
- Code must build without warnings in Swift 6 language mode.
- Add or update tests (Swift Testing) for behavior changes.
- Document public symbols with DocC comments.
- Add an entry under **Unreleased** in `CHANGELOG.md`.
- Keep pull requests focused on one change.

## Commit messages

Use the imperative mood and keep the subject under 72 characters, for example
`Add determinate progress to spinner`.

## Code of conduct

This project follows the [Code of Conduct](CODE_OF_CONDUCT.md). By participating
you agree to uphold it.
