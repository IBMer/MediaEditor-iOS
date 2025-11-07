import XCTest
@testable import ImPAWsibleMetalFilters

@available(iOS 17.0, macOS 13.0, *)
final class MetalCIFilterTests: XCTestCase {
    var pipeline: MetalCIFilterPipeline!
    var testBuffer: CVPixelBuffer!

    override func setUp() async throws {
        try await super.setUp()
        pipeline = try await MetalCIFilterPipeline()
        testBuffer = createTestBuffer(width: 640, height: 480)
    }

    override func tearDown() async throws {
        pipeline = nil
        testBuffer = nil
        try await super.tearDown()
    }

    // MARK: - Filter Enum Tests

    func testAllFiltersHaveDisplayNames() {
        for filter in MetalFilter.allCases {
            XCTAssertFalse(filter.displayName.isEmpty, "Filter \(filter) should have a display name")
        }
    }

    func testAllFiltersHaveCIFilterNames() {
        for filter in MetalFilter.allCases where filter != .none {
            XCTAssertNotNil(filter.ciFilterName, "Filter \(filter) should have a CI filter name")
        }
    }

    func testNoneFilterHasNoCIFilterName() {
        XCTAssertNil(MetalFilter.none.ciFilterName)
    }

    func testSepiaSupportsIntensity() {
        XCTAssertTrue(MetalFilter.sepia.supportsIntensity)
    }

    func testOtherFiltersDoNotSupportIntensity() {
        let filters: [MetalFilter] = [.mono, .noir, .vintage, .tonal, .transfer, .chrome, .fade, .instant]
        for filter in filters {
            XCTAssertFalse(filter.supportsIntensity, "\(filter) should not support intensity")
        }
    }

    func testFilterCount() {
        XCTAssertEqual(MetalFilter.allCases.count, 10)
    }

    // MARK: - Filter Processing Tests

    func testAllFiltersAvailable() async throws {
        for filter in MetalFilter.allCases where filter != .none {
            let result = try await pipeline.process(
                pixelBuffer: testBuffer,
                filter: filter
            )
            XCTAssertNotNil(result, "Filter \(filter.displayName) should produce output")
        }
    }

    func testNoneFilterPassthrough() async throws {
        let result = try await pipeline.process(
            pixelBuffer: testBuffer,
            filter: .none
        )

        // Should return the same buffer or equivalent
        XCTAssertEqual(
            CVPixelBufferGetWidth(result),
            CVPixelBufferGetWidth(testBuffer)
        )
        XCTAssertEqual(
            CVPixelBufferGetHeight(result),
            CVPixelBufferGetHeight(testBuffer)
        )
    }

    func testIntensityParameter() async throws {
        let intensities: [Float] = [0.0, 0.5, 1.0]

        for intensity in intensities {
            let result = try await pipeline.process(
                pixelBuffer: testBuffer,
                filter: .sepia,
                parameters: FilterParameters(intensity: intensity)
            )
            XCTAssertNotNil(result, "Should process with intensity \(intensity)")
        }
    }

    func testInvalidIntensity() async throws {
        // FilterParameters automatically clamps, so this shouldn't throw
        let params = FilterParameters(intensity: 1.5)
        XCTAssertEqual(params.intensity, 1.0, "Intensity should be clamped to 1.0")

        let params2 = FilterParameters(intensity: -0.5)
        XCTAssertEqual(params2.intensity, 0.0, "Intensity should be clamped to 0.0")
    }

    // MARK: - CVPixelBuffer Extension Tests

    func testCVPixelBufferExtension() async throws {
        let filtered = try await testBuffer.applying(.mono, intensity: 1.0)
        XCTAssertNotNil(filtered)
        XCTAssertEqual(CVPixelBufferGetWidth(filtered), CVPixelBufferGetWidth(testBuffer))
    }

    // MARK: - FilterParameters Tests

    func testDefaultParameters() {
        let params = FilterParameters.default
        XCTAssertEqual(params.intensity, 1.0)
        XCTAssertTrue(params.isValid)
    }

    func testParameterValidation() {
        let valid = FilterParameters(intensity: 0.5)
        XCTAssertTrue(valid.isValid)

        let alsoValid = FilterParameters(intensity: 0.0)
        XCTAssertTrue(alsoValid.isValid)
    }

    // MARK: - Library Info Tests

    func testLibraryVersion() {
        XCTAssertEqual(ImPAWsibleMetalFilters.version, "2.0.0")
        XCTAssertEqual(ImPAWsibleMetalFilters.name, "ImPAWsibleMetalFilters")
        XCTAssertEqual(ImPAWsibleMetalFilters.technology, "Metal-backed Core Image")
    }

    func testMetalAvailability() {
        XCTAssertTrue(ImPAWsibleMetalFilters.isMetalAvailable, "Metal should be available")
    }

    // MARK: - Helpers

    private func createTestBuffer(width: Int, height: Int) -> CVPixelBuffer {
        var buffer: CVPixelBuffer?
        let status = CVPixelBufferCreate(
            kCFAllocatorDefault,
            width, height,
            kCVPixelFormatType_32BGRA,
            [
                kCVPixelBufferMetalCompatibilityKey: true,
                kCVPixelBufferIOSurfacePropertiesKey: [:]
            ] as CFDictionary,
            &buffer
        )

        guard status == kCVReturnSuccess, let pixelBuffer = buffer else {
            fatalError("Failed to create test buffer")
        }

        return pixelBuffer
    }
}
