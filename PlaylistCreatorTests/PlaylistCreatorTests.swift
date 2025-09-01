import XCTest
@testable import PlaylistCreator

final class PlaylistCreatorTests: XCTestCase {

    func testAppLaunches() throws {
        // This is a simple smoke test to verify the app can launch
        // We'll test that our main ContentView can be instantiated
        let contentView = ContentView()
        XCTAssertNotNil(contentView)
    }

    func testExample() throws {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct
        // results.
        XCTAssertEqual(2 + 2, 4)
    }

    func testPerformanceExample() throws {
        // This is an example of a performance test case.
        self.measure {
            // Put the code you want to measure the time of here.
            _ = ContentView()
        }
    }
}