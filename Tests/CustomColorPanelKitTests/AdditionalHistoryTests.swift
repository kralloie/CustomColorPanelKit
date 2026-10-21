import SwiftUI
import XCTest
@testable import CustomColorPanelKit

@MainActor
final class AdditionalHistoryTests: XCTestCase {
    func testFullHistoryReaddingEntryDoesNotEvictAnother() {
        // Adjacent red channels differ by 1/255, greater than the deduplication tolerance.
        for movedIndex in [1, ColorHistory.capacity / 2, ColorHistory.capacity - 1] {
            let history = ColorHistory()
            for index in 0..<ColorHistory.capacity {
                history.add(HSBAColor(hue: 0, saturation: 1, brightness: CGFloat(index + 1) / 255))
            }
            let before = history.colors
            let moved = before[movedIndex]
            history.add(moved)
            var expected = before
            expected.remove(at: movedIndex)
            expected.insert(moved, at: 0)
            XCTAssertEqual(history.colors, expected)
            XCTAssertEqual(history.colors.count, ColorHistory.capacity)
        }
    }

    func testDeletingApproximatelyEquivalentEntryPreservesOtherEntries() {
        let history = ColorHistory()
        let gray = HSBAColor(hue: 0, saturation: 0, brightness: 0.5, alpha: 0.75)
        let blue = HSBAColor(hue: 2.0 / 3, saturation: 1, brightness: 1)
        history.add(gray)
        history.add(blue)
        history.delete(HSBAColor(hue: 0.8, saturation: 0, brightness: 0.5005, alpha: 0.7505))
        XCTAssertEqual(history.colors, [blue])
    }
}
