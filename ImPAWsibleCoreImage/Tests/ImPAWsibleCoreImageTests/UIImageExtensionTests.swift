import XCTest
import UIKit
@testable import ImPAWsibleCoreImage

@available(iOS 16.0, macOS 13.0, *)
final class UIImageExtensionTests: XCTestCase {
    var testImage: UIImage!

    override func setUp() async throws {
        try await super.setUp()
        testImage = createTestImage()
    }

    override func tearDown() async throws {
        testImage = nil
        try await super.tearDown()
    }

    private func createTestImage(size: CGSize = CGSize(width: 100, height: 100)) -> UIImage {
        let renderer = UIGraphicsImageRenderer(size: size)
        return renderer.image { context in
            UIColor.systemBlue.setFill()
            context.fill(CGRect(origin: .zero, size: size))
        }
    }

    // MARK: - Async Applying Tests

    func testApplyingAsyncWithMonoFilter() async throws {
        let result = try await testImage.applying(.mono)
        XCTAssertNotNil(result)
        XCTAssertEqual(result.size, testImage.size)
    }

    func testApplyingAsyncWithNoneFilter() async throws {
        let result = try await testImage.applying(.none)
        XCTAssertNotNil(result)
    }

    func testApplyingAsyncWithIntensity() async throws {
        let result = try await testImage.applying(.sepia, intensity: 0.7)
        XCTAssertNotNil(result)
    }

    func testApplyingAsyncThrowsForInvalidIntensity() async {
        do {
            _ = try await testImage.applying(.sepia, intensity: 1.5)
            XCTFail("Should throw error for invalid intensity")
        } catch {
            XCTAssertTrue(error is FilterError)
        }
    }

    // MARK: - Filter Thumbnail Tests

    func testFilterThumbnailGeneratesSmaller() async throws {
        let largeImage = createTestImage(size: CGSize(width: 500, height: 500))
        let thumbnail = try await largeImage.filterThumbnail(.vintage, maxDimension: 100)

        XCTAssertNotNil(thumbnail)
        XCTAssertTrue(
            thumbnail.size.width <= 100 || thumbnail.size.height <= 100,
            "Thumbnail should be within max dimension"
        )
    }

    func testFilterThumbnailAppliesFilter() async throws {
        let thumbnail = try await testImage.filterThumbnail(.noir, maxDimension: 50)
        XCTAssertNotNil(thumbnail)
    }

    // MARK: - Sync Applying Tests

    func testApplyingSyncWithFilter() throws {
        let result = try testImage.applyingSync(.chrome)
        XCTAssertNotNil(result)
        XCTAssertEqual(result.size, testImage.size)
    }

    func testApplyingSyncWithIntensity() throws {
        let result = try testImage.applyingSync(.sepia, intensity: 0.5)
        XCTAssertNotNil(result)
    }

    func testApplyingSyncThrowsForInvalidIntensity() {
        XCTAssertThrowsError(
            try testImage.applyingSync(.sepia, intensity: -0.5)
        )
    }

    // MARK: - Batch Processing Tests

    func testApplyingBatchProcessesMultipleImages() async throws {
        let images = [
            createTestImage(),
            createTestImage(size: CGSize(width: 150, height: 150)),
            createTestImage(size: CGSize(width: 200, height: 200))
        ]

        let results = try await UIImage.applyingBatch(images, filter: .fade)

        XCTAssertEqual(results.count, images.count)
        for result in results {
            XCTAssertNotNil(result)
        }
    }

    func testApplyingBatchWithEmptyArray() async throws {
        let results = try await UIImage.applyingBatch([], filter: .instant)
        XCTAssertTrue(results.isEmpty)
    }

    func testApplyingBatchPreservesOrder() async throws {
        let sizes = [
            CGSize(width: 100, height: 100),
            CGSize(width: 200, height: 200),
            CGSize(width: 150, height: 150)
        ]
        let images = sizes.map { createTestImage(size: $0) }

        let results = try await UIImage.applyingBatch(images, filter: .tonal)

        for (index, result) in results.enumerated() {
            XCTAssertEqual(result.size, sizes[index])
        }
    }

    // MARK: - Generate Filter Previews Tests

    func testGenerateFilterPreviewsCreatesAllFilters() async throws {
        let previews = try await testImage.generateFilterPreviews(maxDimension: 64)

        // Should generate preview for all filters
        XCTAssertEqual(previews.count, ImPAWsibleFilter.allCases.count)

        // Verify each filter has a preview
        for filter in ImPAWsibleFilter.allCases {
            XCTAssertNotNil(previews[filter], "Preview for \(filter.displayName) should exist")
        }
    }

    func testGenerateFilterPreviewsWithSpecificFilters() async throws {
        let specificFilters: [ImPAWsibleFilter] = [.mono, .sepia, .vintage]
        let previews = try await testImage.generateFilterPreviews(
            maxDimension: 64,
            filters: specificFilters
        )

        XCTAssertEqual(previews.count, specificFilters.count)

        for filter in specificFilters {
            XCTAssertNotNil(previews[filter])
        }
    }

    func testGenerateFilterPreviewsResizesProperly() async throws {
        let largeImage = createTestImage(size: CGSize(width: 1000, height: 1000))
        let maxDimension: CGFloat = 100

        let previews = try await largeImage.generateFilterPreviews(maxDimension: maxDimension)

        for (filter, preview) in previews {
            XCTAssertTrue(
                preview.size.width <= maxDimension || preview.size.height <= maxDimension,
                "Preview for \(filter.displayName) exceeds max dimension"
            )
        }
    }

    func testGenerateFilterPreviewsWithEmptyFilterList() async throws {
        let previews = try await testImage.generateFilterPreviews(filters: [])
        XCTAssertTrue(previews.isEmpty)
    }

    // MARK: - All Filters Extension Test

    func testAllFiltersWorkWithExtension() async throws {
        for filter in ImPAWsibleFilter.allCases {
            let result = try await testImage.applying(filter)
            XCTAssertNotNil(result, "Extension should work with \(filter.displayName)")
        }
    }
}
