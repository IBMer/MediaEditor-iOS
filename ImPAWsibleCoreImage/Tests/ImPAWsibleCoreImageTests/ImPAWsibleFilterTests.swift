import XCTest
@testable import ImPAWsibleCoreImage

@available(iOS 16.0, macOS 13.0, *)
final class ImPAWsibleFilterTests: XCTestCase {
    // MARK: - Filter Enum Tests

    func testAllFiltersHaveDisplayNames() {
        for filter in ImPAWsibleFilter.allCases {
            XCTAssertFalse(filter.displayName.isEmpty, "Filter \(filter) should have a display name")
        }
    }

    func testAllFiltersHaveDescriptions() {
        for filter in ImPAWsibleFilter.allCases {
            XCTAssertFalse(filter.description.isEmpty, "Filter \(filter) should have a description")
        }
    }

    func testNoneFilterHasEmptyCIFilterName() {
        XCTAssertEqual(ImPAWsibleFilter.none.ciFilterName, "")
    }

    func testAllNonNoneFiltersHaveCIFilterNames() {
        for filter in ImPAWsibleFilter.allCases where filter != .none {
            XCTAssertFalse(
                filter.ciFilterName.isEmpty,
                "Filter \(filter) should have a Core Image filter name"
            )
            XCTAssertTrue(
                filter.ciFilterName.hasPrefix("CI"),
                "Filter \(filter) Core Image name should start with 'CI'"
            )
        }
    }

    func testSepiaFilterSupportsIntensity() {
        XCTAssertTrue(ImPAWsibleFilter.sepia.supportsIntensity)
    }

    func testPhotoEffectFiltersDoNotSupportIntensity() {
        let photoEffectFilters: [ImPAWsibleFilter] = [
            .mono, .noir, .vintage, .tonal, .transfer, .chrome, .fade, .instant
        ]

        for filter in photoEffectFilters {
            XCTAssertFalse(
                filter.supportsIntensity,
                "Photo effect filter \(filter) should not support intensity"
            )
        }
    }

    func testFilterIdentifiableConformance() {
        let filter = ImPAWsibleFilter.mono
        XCTAssertEqual(filter.id, filter.rawValue)
    }

    func testFilterCaseCount() {
        // Should have 10 filters total (none + 9 effects)
        XCTAssertEqual(ImPAWsibleFilter.allCases.count, 10)
    }

    // MARK: - Filter Name Mapping Tests

    func testMonoFilterMapping() {
        XCTAssertEqual(ImPAWsibleFilter.mono.ciFilterName, "CIPhotoEffectMono")
    }

    func testNoirFilterMapping() {
        XCTAssertEqual(ImPAWsibleFilter.noir.ciFilterName, "CIPhotoEffectNoir")
    }

    func testSepiaFilterMapping() {
        XCTAssertEqual(ImPAWsibleFilter.sepia.ciFilterName, "CISepiaTone")
    }

    func testVintageFilterMapping() {
        XCTAssertEqual(ImPAWsibleFilter.vintage.ciFilterName, "CIPhotoEffectProcess")
    }

    func testTonalFilterMapping() {
        XCTAssertEqual(ImPAWsibleFilter.tonal.ciFilterName, "CIPhotoEffectTonal")
    }

    func testTransferFilterMapping() {
        XCTAssertEqual(ImPAWsibleFilter.transfer.ciFilterName, "CIPhotoEffectTransfer")
    }

    func testChromeFilterMapping() {
        XCTAssertEqual(ImPAWsibleFilter.chrome.ciFilterName, "CIPhotoEffectChrome")
    }

    func testFadeFilterMapping() {
        XCTAssertEqual(ImPAWsibleFilter.fade.ciFilterName, "CIPhotoEffectFade")
    }

    func testInstantFilterMapping() {
        XCTAssertEqual(ImPAWsibleFilter.instant.ciFilterName, "CIPhotoEffectInstant")
    }
}
