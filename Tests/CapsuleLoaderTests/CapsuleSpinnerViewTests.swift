import Testing
import UIKit
@testable import CapsuleLoader

@MainActor
@Suite("Spinner")
struct CapsuleSpinnerViewTests {
    @Test func animatesByDefault() {
        #expect(CapsuleSpinnerView().isAnimating)
    }

    @Test func stopAndStartToggleAnimation() {
        let spinner = CapsuleSpinnerView()
        spinner.stopAnimating()
        #expect(!spinner.isAnimating)
        spinner.startAnimating()
        #expect(spinner.isAnimating)
    }

    @Test func isAccessible() {
        let spinner = CapsuleSpinnerView()
        #expect(spinner.isAccessibilityElement)
        #expect(spinner.accessibilityLabel == "Loading")
    }

    @Test func hasSquareIntrinsicSize() {
        #expect(CapsuleSpinnerView().intrinsicContentSize == CGSize(width: 32, height: 32))
    }
}
