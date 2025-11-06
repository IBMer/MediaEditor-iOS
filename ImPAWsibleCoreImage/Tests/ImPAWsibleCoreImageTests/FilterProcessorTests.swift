import XCTest
import UIKit
@testable import ImPAWsibleCoreImage

@available(iOS 16.0, macOS 13.0, *)
final class FilterProcessorTests: XCTestCase {
    var processor: FilterProcessor!
    var testImage: UIImage!

    override func setUp() async throws {
        try await super.setUp()
        processor = FilterProcessor()
        // Create a simple test image
        testImage = createTestImage()
    }

    override func tearDown() async throws {
        processor = nil
        testImage = nil
        try await super.tearDown()
    }

    // MARK: - Helper Methods

    private func createTestImage(size: CGSize = CGSize(width: 100, height: 100)) -> UIImage {
        let renderer = UIGraphicsImageRenderer(size: size)
        return renderer.image { context in
            // Create a gradient background
            UIColor.red.setFill()
            context.fill(CGRect(origin: .zero, size: size))

            UIColor.blue.setFill()
            context.fill(CGRect(x: 0, y: 0, width: size.width / 2, height: size.height))
        }
    }

    // MARK: - Basic Processing Tests

    func testProcessNoneFilterReturnsOriginalImage() async throws {
        let result = try await processor.process(testImage, filter: .none)
        XCTAssertNotNil(result)
        XCTAssertEqual(result.size, testImage.size)
    }

    func testProcessMonoFilterSucceeds() async throws {
        let result = try await processor.process(testImage, filter: .mono)
        XCTAssertNotNil(result)
        XCTAssertEqual(result.size, testImage.size)
    }

    func testProcessSepiaFilterSucceeds() async throws {
        let result = try await processor.process(testImage, filter: .sepia)
        XCTAssertNotNil(result)
        XCTAssertEqual(result.size, testImage.size)
    }

    func testProcessWithValidIntensity() async throws {
        let result = try await processor.process(testImage, filter: .sepia, intensity: 0.5)
        XCTAssertNotNil(result)
    }

    func testProcessWithZeroIntensity() async throws {
        let result = try await processor.process(testImage, filter: .sepia, intensity: 0.0)
        XCTAssertNotNil(result)
    }

    func testProcessWithMaxIntensity() async throws {
        let result = try await processor.process(testImage, filter: .sepia, intensity: 1.0)
        XCTAssertNotNil(result)
    }

    // MARK: - Error Handling Tests

    func testProcessWithInvalidIntensityThrows() async {
        do {
            _ = try await processor.process(testImage, filter: .sepia, intensity: 1.5)
            XCTFail("Should throw error for intensity > 1.0")
        } catch FilterError.invalidIntensity {
            // Expected error
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }

    func testProcessWithNegativeIntensityThrows() async {
        do {
            _ = try await processor.process(testImage, filter: .sepia, intensity: -0.1)
            XCTFail("Should throw error for negative intensity")
        } catch FilterError.invalidIntensity {
            // Expected error
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }

    // MARK: - Batch Processing Tests

    func testProcessBatchWithMultipleImages() async throws {
        let images = [
            createTestImage(),
            createTestImage(size: CGSize(width: 150, height: 150)),
            createTestImage(size: CGSize(width: 200, height: 100))
        ]

        let results = try await processor.processBatch(images, filter: .noir)

        XCTAssertEqual(results.count, images.count)
        for (index, result) in results.enumerated() {
            XCTAssertEqual(result.size, images[index].size)
        }
    }

    func testProcessBatchPreservesOrder() async throws {
        let sizes = [
            CGSize(width: 100, height: 100),
            CGSize(width: 200, height: 200),
            CGSize(width: 150, height: 150)
        ]
        let images = sizes.map { createTestImage(size: $0) }

        let results = try await processor.processBatch(images, filter: .vintage)

        for (index, result) in results.enumerated() {
            XCTAssertEqual(result.size, sizes[index])
        }
    }

    func testProcessBatchWithEmptyArray() async throws {
        let results = try await processor.processBatch([], filter: .mono)
        XCTAssertTrue(results.isEmpty)
    }

    // MARK: - Thumbnail Generation Tests

    func testGenerateThumbnailReducesSize() async throws {
        let largeImage = createTestImage(size: CGSize(width: 1000, height: 1000))
        let thumbnail = try await processor.generateThumbnail(
            largeImage,
            filter: .chrome,
            maxDimension: 100
        )

        XCTAssertNotNil(thumbnail)
        XCTAssertTrue(thumbnail.size.width <= 100 || thumbnail.size.height <= 100)
    }

    func testGenerateThumbnailPreservesAspectRatio() async throws {
        let rectangularImage = createTestImage(size: CGSize(width: 400, height: 200))
        let thumbnail = try await processor.generateThumbnail(
            rectangularImage,
            filter: .fade,
            maxDimension: 100
        )

        let originalRatio = rectangularImage.size.width / rectangularImage.size.height
        let thumbnailRatio = thumbnail.size.width / thumbnail.size.height

        XCTAssertEqual(originalRatio, thumbnailRatio, accuracy: 0.1)
    }

    // MARK: - Synchronous API Tests

    func testProcessSyncReturnsFilteredImage() throws {
        let result = try processor.processSync(testImage, filter: .tonal)
        XCTAssertNotNil(result)
        XCTAssertEqual(result.size, testImage.size)
    }

    func testProcessSyncWithNoneFilter() throws {
        let result = try processor.processSync(testImage, filter: .none)
        XCTAssertNotNil(result)
    }

    func testProcessSyncThrowsForInvalidIntensity() {
        XCTAssertThrowsError(
            try processor.processSync(testImage, filter: .sepia, intensity: 2.0)
        ) { error in
            XCTAssertTrue(error is FilterError)
        }
    }

    // MARK: - All Filters Test

    func testAllFiltersCanBeApplied() async throws {
        for filter in ImPAWsibleFilter.allCases {
            let result = try await processor.process(testImage, filter: filter)
            XCTAssertNotNil(result, "Filter \(filter.displayName) should produce a result")
        }
    }

    // MARK: - Image Properties Preservation Tests

    func testProcessPreservesImageScale() async throws {
        let scaledImage = UIImage(
            cgImage: testImage.cgImage!,
            scale: 2.0,
            orientation: testImage.imageOrientation
        )

        let result = try await processor.process(scaledImage, filter: .instant)

        XCTAssertEqual(result.scale, scaledImage.scale)
    }

    func testProcessPreservesImageOrientation() async throws {
        let rotatedImage = UIImage(
            cgImage: testImage.cgImage!,
            scale: testImage.scale,
            orientation: .right
        )

        let result = try await processor.process(rotatedImage, filter: .transfer)

        XCTAssertEqual(result.imageOrientation, rotatedImage.imageOrientation)
    }
}
