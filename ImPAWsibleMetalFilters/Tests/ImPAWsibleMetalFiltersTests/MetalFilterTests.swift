import XCTest
@testable import ImPAWsibleMetalFilters

@available(iOS 16.0, macOS 13.0, *)
final class MetalFilterTests: XCTestCase {
    // MARK: - Filter Enum Tests

    func testAllFiltersHaveDisplayNames() {
        for filter in MetalFilter.allCases {
            XCTAssertFalse(filter.displayName.isEmpty, "Filter \(filter) should have a display name")
        }
    }

    func testAllFiltersHaveKernelNames() {
        for filter in MetalFilter.allCases where filter != .none {
            XCTAssertFalse(
                filter.kernelFunctionName.isEmpty,
                "Filter \(filter) should have a kernel function name"
            )
        }
    }

    func testNoneFilterHasEmptyKernelName() {
        XCTAssertEqual(MetalFilter.none.kernelFunctionName, "")
    }

    func testFilterSupportsCustomParameters() {
        XCTAssertTrue(MetalFilter.sepia.supportsCustomParameters)
        XCTAssertTrue(MetalFilter.mono.supportsCustomParameters)
        XCTAssertTrue(MetalFilter.fade.supportsCustomParameters)

        XCTAssertFalse(MetalFilter.noir.supportsCustomParameters)
        XCTAssertFalse(MetalFilter.vintage.supportsCustomParameters)
    }

    func testFilterCount() {
        // Should have 10 filters (none + 9 effects)
        XCTAssertEqual(MetalFilter.allCases.count, 10)
    }

    func testFilterIdentifiable() {
        let filter = MetalFilter.mono
        XCTAssertEqual(filter.id, filter.rawValue)
    }

    // MARK: - FilterParameters Tests

    func testDefaultParameters() {
        let params = FilterParameters.preset(for: .sepia)
        XCTAssertEqual(params.intensity, 1.0)
        XCTAssertEqual(params.customParams["warmth"], 0.7)
    }

    func testParameterIntensityClamping() {
        let tooHigh = FilterParameters(intensity: 1.5)
        XCTAssertEqual(tooHigh.intensity, 1.0)

        let tooLow = FilterParameters(intensity: -0.5)
        XCTAssertEqual(tooLow.intensity, 0.0)

        let normal = FilterParameters(intensity: 0.5)
        XCTAssertEqual(normal.intensity, 0.5)
    }

    func testSepiaParameterFactory() {
        let params = FilterParameters.sepia(warmth: 0.9, intensity: 0.8)
        XCTAssertEqual(params.intensity, 0.8)
        XCTAssertEqual(params.customParams["warmth"], 0.9)
    }

    func testMonoParameterFactory() {
        let params = FilterParameters.mono(contrast: 1.3, intensity: 1.0)
        XCTAssertEqual(params.intensity, 1.0)
        XCTAssertEqual(params.customParams["contrast"], 1.3)
    }

    func testFadeParameterFactory() {
        let params = FilterParameters.fade(brightness: 1.2, intensity: 0.9)
        XCTAssertEqual(params.intensity, 0.9)
        XCTAssertEqual(params.customParams["brightness"], 1.2)
    }

    func testParameterValidation() throws {
        // Valid parameters should not throw
        let validSepia = FilterParameters.sepia(warmth: 0.5)
        XCTAssertNoThrow(try validSepia.validate(for: .sepia))

        // Invalid warmth should throw
        let invalidSepia = FilterParameters(intensity: 1.0, customParams: ["warmth": 1.5])
        XCTAssertThrowsError(try invalidSepia.validate(for: .sepia))

        // Invalid contrast should throw
        let invalidMono = FilterParameters(intensity: 1.0, customParams: ["contrast": 2.0])
        XCTAssertThrowsError(try invalidMono.validate(for: .mono))
    }

    // MARK: - MetalFilterContext Tests

    func testMetalContextInitialization() throws {
        let context = try MetalFilterContext.shared
        XCTAssertNotNil(context.device)
        XCTAssertNotNil(context.commandQueue)
    }

    func testMetalDeviceCapability() throws {
        let context = try MetalFilterContext.shared
        XCTAssertTrue(context.isCapable, "Device should support Metal filtering")
    }

    func testDeviceName() throws {
        let context = try MetalFilterContext.shared
        XCTAssertFalse(context.deviceName.isEmpty)
    }

    // MARK: - Library Info Tests

    func testLibraryVersion() {
        XCTAssertEqual(ImPAWsibleMetalFilters.version, "1.0.0")
        XCTAssertEqual(ImPAWsibleMetalFilters.name, "ImPAWsibleMetalFilters")
    }

    func testIsSupported() {
        // Should be true on devices with Metal support
        XCTAssertTrue(ImPAWsibleMetalFilters.isSupported)
    }

    // MARK: - FilterError Tests

    func testFilterErrorDescriptions() {
        let errors: [FilterError] = [
            .metalDeviceNotAvailable,
            .metalCommandCreationFailed,
            .pipelineStateCreationFailed("test"),
            .pixelBufferCreationFailed,
            .textureCreationFailed,
            .textureCacheCreationFailed,
            .invalidKernelFunction("test"),
            .processingFailed("test"),
            .invalidParameter("warmth", value: 1.5)
        ]

        for error in errors {
            XCTAssertFalse(error.errorDescription?.isEmpty ?? true)
        }
    }
}
