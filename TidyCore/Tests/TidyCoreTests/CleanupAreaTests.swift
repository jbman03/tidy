import XCTest
@testable import TidyCore

final class CleanupAreaTests: XCTestCase {
    func testOrderTitlesAndStages() {
        XCTAssertEqual(CleanupArea.allCases.map(\.title),
            ["Screenshots", "Big Videos", "Duplicates", "Blurry", "Contacts", "Files"])
        XCTAssertEqual(CleanupArea.allCases.map(\.stage), [2, 2, 3, 3, 4, 5])
    }

    func testSymbols() {
        XCTAssertEqual(CleanupArea.allCases.map(\.systemImage),
            ["camera.viewfinder", "video", "square.on.square", "drop", "person.2", "folder"])
    }
}
