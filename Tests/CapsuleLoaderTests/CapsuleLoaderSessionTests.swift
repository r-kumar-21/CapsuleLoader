import Testing
@testable import CapsuleLoader

@Suite("Show and hide counting")
struct CapsuleLoaderSessionTests {
    @Test func loaderStaysVisibleUntilEveryShowIsHidden() {
        var session = CapsuleLoaderSession()

        let firstShow = session.show()
        let secondShow = session.show()
        #expect(firstShow)
        #expect(!secondShow)
        #expect(session.isVisible)

        let firstHide = session.hide()
        #expect(!firstHide)
        #expect(session.isVisible)

        let lastHide = session.hide()
        #expect(lastHide)
        #expect(!session.isVisible)
    }

    @Test func extraHideDoesNothing() {
        var session = CapsuleLoaderSession()
        let didHide = session.hide()
        #expect(!didHide)
        #expect(!session.isVisible)
        #expect(session.count == 0)
    }

    @Test func hideAllClearsNestedShows() {
        var session = CapsuleLoaderSession()
        _ = session.show()
        _ = session.show()
        let didHideAll = session.hideAll()
        let extraHide = session.hide()
        #expect(didHideAll)
        #expect(!session.isVisible)
        #expect(!extraHide)
    }

    @Test func hideAllWhenHiddenReportsNoChange() {
        var session = CapsuleLoaderSession()
        let didHideAll = session.hideAll()
        #expect(!didHideAll)
    }

    @Test(arguments: 1...5)
    func balancedShowsAndHidesEndHidden(depth: Int) {
        var session = CapsuleLoaderSession()
        for _ in 0..<depth { _ = session.show() }
        for step in 1...depth {
            let didHide = session.hide()
            #expect(didHide == (step == depth))
        }
        #expect(!session.isVisible)
    }
}
