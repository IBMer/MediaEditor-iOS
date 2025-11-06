import Foundation
import CoreImage
import CoreGraphics

/// Thread-safe Core Image context manager
///
/// This actor provides a shared, thread-safe Core Image context for efficient
/// filter processing. Using a single context across multiple filter operations
/// improves performance by reusing GPU/CPU resources.
@available(iOS 16.0, macOS 13.0, *)
public actor FilterContext {
    /// Shared singleton instance
    public static let shared = FilterContext()

    /// The underlying Core Image context
    private let ciContext: CIContext

    /// Private initializer to ensure singleton pattern
    private init() {
        // Create context with optimal settings
        let options: [CIContextOption: Any] = [
            .workingColorSpace: CGColorSpaceCreateDeviceRGB(),
            .outputColorSpace: CGColorSpaceCreateDeviceRGB(),
            .useSoftwareRenderer: false // Prefer GPU when available
        ]
        self.ciContext = CIContext(options: options)
    }

    /// Renders a CIImage to CGImage
    /// - Parameters:
    ///   - image: The Core Image to render
    ///   - extent: The region to render (defaults to image extent)
    /// - Returns: Rendered CGImage
    /// - Throws: FilterError if rendering fails
    public func render(_ image: CIImage, in extent: CGRect? = nil) throws -> CGImage {
        let renderExtent = extent ?? image.extent

        guard let cgImage = ciContext.createCGImage(image, from: renderExtent) else {
            throw FilterError.renderingFailed
        }

        return cgImage
    }

    /// Applies a Core Image filter to an image
    /// - Parameters:
    ///   - filterName: The name of the Core Image filter
    ///   - input: The input CIImage
    ///   - parameters: Additional filter parameters
    /// - Returns: Filtered CIImage
    /// - Throws: FilterError if filter creation or application fails
    public func applyFilter(
        named filterName: String,
        to input: CIImage,
        parameters: [String: Any] = [:]
    ) throws -> CIImage {
        guard !filterName.isEmpty else {
            return input
        }

        guard let filter = CIFilter(name: filterName) else {
            throw FilterError.filterNotAvailable(filterName)
        }

        filter.setValue(input, forKey: kCIInputImageKey)

        // Apply additional parameters
        for (key, value) in parameters {
            filter.setValue(value, forKey: key)
        }

        guard let output = filter.outputImage else {
            throw FilterError.filterProcessingFailed(filterName)
        }

        return output
    }
}

/// Errors that can occur during filter processing
@available(iOS 16.0, macOS 13.0, *)
public enum FilterError: LocalizedError, Sendable {
    /// The requested filter is not available
    case filterNotAvailable(String)

    /// Filter processing failed
    case filterProcessingFailed(String)

    /// Image rendering failed
    case renderingFailed

    /// Invalid input image
    case invalidInputImage

    /// Invalid intensity value
    case invalidIntensity(Double)

    public var errorDescription: String? {
        switch self {
        case .filterNotAvailable(let name):
            return "Filter '\(name)' is not available on this system"
        case .filterProcessingFailed(let name):
            return "Failed to process image with filter '\(name)'"
        case .renderingFailed:
            return "Failed to render the filtered image"
        case .invalidInputImage:
            return "The input image is invalid or cannot be processed"
        case .invalidIntensity(let value):
            return "Invalid intensity value: \(value). Must be between 0.0 and 1.0"
        }
    }
}
