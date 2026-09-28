import Testing
import UIKit
@testable import CapsuleLoader

@MainActor
@Suite("Progress bar")
struct CapsuleProgressBarViewTests {
    @Test func startsIndeterminate() {
        let bar = CapsuleProgressBarView()
        #expect(bar.progress == nil)
        #expect(bar.accessibilityValue == nil)
    }

    @Test(arguments: [
        (CGFloat(-0.5), CGFloat(0)),
        (0, 0),
        (0.35, 0.35),
        (1, 1),
        (2, 1),
    ])
    func clampsProgress(input: CGFloat, expected: CGFloat) {
        let bar = CapsuleProgressBarView()
        bar.setProgress(input, animated: false)
        #expect(bar.progress == expected)
    }

    @Test func reportsPercentToVoiceOver() {
        let bar = CapsuleProgressBarView()
        bar.setProgress(0.426, animated: false)
        #expect(bar.accessibilityValue == "43 percent")
    }

    @Test func nilReturnsToIndeterminate() {
        let bar = CapsuleProgressBarView()
        bar.setProgress(0.5, animated: false)
        bar.startAnimating()
        #expect(bar.progress == nil)
        #expect(bar.accessibilityValue == nil)
    }

    @Test func hasFixedHeight() {
        #expect(CapsuleProgressBarView().intrinsicContentSize.height == 6)
    }
}
