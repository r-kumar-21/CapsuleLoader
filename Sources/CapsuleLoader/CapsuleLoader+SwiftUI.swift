import SwiftUI
import UIKit

extension View {
    /// Covers this view with the capsule loader while `isPresented` is true.
    ///
    /// ```swift
    /// List(posts) { post in
    ///     Text(post.title)
    /// }
    /// .capsuleLoader(isPresented: isLoading, message: "Loading")
    /// .task {
    ///     isLoading = true
    ///     defer { isLoading = false }
    ///     posts = (try? await api.posts()) ?? []
    /// }
    /// ```
    public func capsuleLoader(
        isPresented: Bool,
        message: String? = nil,
        style: CapsuleLoader.Style = .bar,
        progress: Double? = nil,
        dimsBackground: Bool = true,
        blocksInteraction: Bool = true,
        indicatorColor: Color? = nil
    ) -> some View {
        modifier(
            CapsuleLoaderModifier(
                isPresented: isPresented,
                message: message,
                style: style,
                progress: progress,
                dimsBackground: dimsBackground,
                blocksInteraction: blocksInteraction,
                indicatorColor: indicatorColor
            )
        )
    }
}

/// The macOS activity ring, for use inside your own SwiftUI layout.
public struct CapsuleSpinner: UIViewRepresentable {
    var size: CGFloat
    var indicatorColor: Color?
    var isAnimating: Bool

    public init(size: CGFloat = 32, indicatorColor: Color? = nil, isAnimating: Bool = true) {
        self.size = size
        self.indicatorColor = indicatorColor
        self.isAnimating = isAnimating
    }

    public func makeUIView(context: Context) -> CapsuleSpinnerView {
        CapsuleSpinnerView()
    }

    public func updateUIView(_ uiView: CapsuleSpinnerView, context: Context) {
        uiView.indicatorColor = indicatorColor.map { UIColor($0) }
        uiView.isAnimating = isAnimating
    }

    public func sizeThatFits(_ proposal: ProposedViewSize, uiView: CapsuleSpinnerView, context: Context) -> CGSize? {
        CGSize(width: size, height: size)
    }
}

/// The macOS progress bar, for use inside your own SwiftUI layout.
///
/// Omit `progress` for the sliding animation. Pass a value from 0 to 1 to fill the track.
public struct CapsuleProgressBar: UIViewRepresentable {
    var progress: Double?
    var indicatorColor: Color?

    public init(progress: Double? = nil, indicatorColor: Color? = nil) {
        self.progress = progress
        self.indicatorColor = indicatorColor
    }

    public func makeUIView(context: Context) -> CapsuleProgressBarView {
        CapsuleProgressBarView()
    }

    public func updateUIView(_ uiView: CapsuleProgressBarView, context: Context) {
        uiView.indicatorColor = indicatorColor.map { UIColor($0) }
        uiView.setProgress(progress.map { CGFloat($0) }, animated: true)
    }

    public func sizeThatFits(_ proposal: ProposedViewSize, uiView: CapsuleProgressBarView, context: Context) -> CGSize? {
        CGSize(width: proposal.width ?? 180, height: 6)
    }
}

private struct CapsuleLoaderModifier: ViewModifier {
    var isPresented: Bool
    var message: String?
    var style: CapsuleLoader.Style
    var progress: Double?
    var dimsBackground: Bool
    var blocksInteraction: Bool
    var indicatorColor: Color?

    func body(content: Content) -> some View {
        content
            .overlay {
                if isPresented {
                    CapsuleLoaderSwiftUIOverlay(
                        message: message,
                        style: style,
                        progress: progress,
                        dimsBackground: dimsBackground,
                        blocksInteraction: blocksInteraction,
                        indicatorColor: indicatorColor
                    )
                    .ignoresSafeArea()
                    .allowsHitTesting(blocksInteraction)
                    .transition(.opacity.combined(with: .scale(scale: 0.96)))
                }
            }
            .animation(.spring(response: 0.34, dampingFraction: 0.86), value: isPresented)
    }
}

private struct CapsuleLoaderSwiftUIOverlay: UIViewRepresentable {
    var message: String?
    var style: CapsuleLoader.Style
    var progress: Double?
    var dimsBackground: Bool
    var blocksInteraction: Bool
    var indicatorColor: Color?

    func makeUIView(context: Context) -> CapsuleLoaderOverlayView {
        let view = CapsuleLoaderOverlayView()
        view.alpha = 1
        return view
    }

    func updateUIView(_ uiView: CapsuleLoaderOverlayView, context: Context) {
        uiView.alpha = 1
        uiView.update(
            message: message,
            style: style,
            progress: progress,
            indicatorColor: indicatorColor.map { UIColor($0) },
            dimsBackground: dimsBackground,
            blocksInteraction: blocksInteraction
        )
    }
}

#if DEBUG
@available(iOS 17, *)
#Preview("Bar") {
    Color(uiColor: .systemGroupedBackground)
        .capsuleLoader(isPresented: true, message: "Loading")
}

@available(iOS 17, *)
#Preview("Spinner") {
    Color(uiColor: .systemGroupedBackground)
        .capsuleLoader(isPresented: true, message: "Fetching posts", style: .spinner)
}
#endif
