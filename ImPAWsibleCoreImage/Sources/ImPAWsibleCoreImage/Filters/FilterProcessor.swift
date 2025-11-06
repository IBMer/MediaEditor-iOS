import Foundation
import UIKit
import CoreImage

/// High-performance filter processor for applying Core Image filters to images
///
/// This class provides both synchronous and asynchronous methods for applying
/// filters to UIImage objects. It uses a shared, thread-safe Core Image context
/// for optimal performance.
///
/// Example usage:
/// ```swift
/// let processor = FilterProcessor()
/// let filtered = try await processor.process(image, filter: .mono)
/// ```
@available(iOS 16.0, macOS 13.0, *)
public final class FilterProcessor: Sendable {
    /// The filter context used for processing
    private let context: FilterContext

    /// Creates a new filter processor
    /// - Parameter context: Custom filter context (defaults to shared instance)
    public init(context: FilterContext = .shared) {
        self.context = context
    }

    // MARK: - Async API

    /// Applies a filter to an image asynchronously
    /// - Parameters:
    ///   - image: The input UIImage
    ///   - filter: The filter to apply
    ///   - intensity: The filter intensity (0.0 - 1.0), only applicable for filters that support it
    /// - Returns: Filtered UIImage
    /// - Throws: FilterError if processing fails
    public func process(
        _ image: UIImage,
        filter: ImPAWsibleFilter,
        intensity: Double = 1.0
    ) async throws -> UIImage {
        // No filter case
        guard filter != .none else {
            return image
        }

        // Validate intensity
        guard intensity >= 0.0 && intensity <= 1.0 else {
            throw FilterError.invalidIntensity(intensity)
        }

        // Convert to CIImage
        guard let ciImage = convertToCIImage(image) else {
            throw FilterError.invalidInputImage
        }

        // Prepare filter parameters
        var parameters: [String: Any] = [:]
        if filter.supportsIntensity {
            parameters[kCIInputIntensityKey] = intensity
        }

        // Apply filter
        let filtered = try await context.applyFilter(
            named: filter.ciFilterName,
            to: ciImage,
            parameters: parameters
        )

        // Render to CGImage
        let cgImage = try await context.render(filtered)

        // Convert back to UIImage, preserving original properties
        return UIImage(
            cgImage: cgImage,
            scale: image.scale,
            orientation: image.imageOrientation
        )
    }

    /// Processes multiple images with the same filter concurrently
    /// - Parameters:
    ///   - images: Array of input images
    ///   - filter: The filter to apply to all images
    ///   - intensity: The filter intensity (0.0 - 1.0)
    /// - Returns: Array of filtered images in the same order
    /// - Throws: FilterError if processing fails
    public func processBatch(
        _ images: [UIImage],
        filter: ImPAWsibleFilter,
        intensity: Double = 1.0
    ) async throws -> [UIImage] {
        try await withThrowingTaskGroup(of: (Int, UIImage).self) { group in
            // Process each image concurrently
            for (index, image) in images.enumerated() {
                group.addTask {
                    let processed = try await self.process(image, filter: filter, intensity: intensity)
                    return (index, processed)
                }
            }

            // Collect results in original order
            var results: [(Int, UIImage)] = []
            for try await result in group {
                results.append(result)
            }

            return results.sorted(by: { $0.0 < $1.0 }).map(\.1)
        }
    }

    /// Generates a thumbnail preview of the filter applied to an image
    /// - Parameters:
    ///   - image: The input image
    ///   - filter: The filter to preview
    ///   - size: The maximum dimension for the thumbnail (default: 256)
    ///   - intensity: The filter intensity
    /// - Returns: Thumbnail UIImage with filter applied
    /// - Throws: FilterError if processing fails
    public func generateThumbnail(
        _ image: UIImage,
        filter: ImPAWsibleFilter,
        maxDimension size: CGFloat = 256,
        intensity: Double = 1.0
    ) async throws -> UIImage {
        // Create thumbnail first for performance
        let thumbnail = resizeImage(image, maxDimension: size)
        return try await process(thumbnail, filter: filter, intensity: intensity)
    }

    // MARK: - Synchronous API

    /// Applies a filter to an image synchronously (blocks current thread)
    ///
    /// - Warning: This method blocks the calling thread. Prefer async version for better performance.
    /// - Parameters:
    ///   - image: The input UIImage
    ///   - filter: The filter to apply
    ///   - intensity: The filter intensity (0.0 - 1.0)
    /// - Returns: Filtered UIImage
    /// - Throws: FilterError if processing fails
    public func processSync(
        _ image: UIImage,
        filter: ImPAWsibleFilter,
        intensity: Double = 1.0
    ) throws -> UIImage {
        // No filter case
        guard filter != .none else {
            return image
        }

        // Validate intensity
        guard intensity >= 0.0 && intensity <= 1.0 else {
            throw FilterError.invalidIntensity(intensity)
        }

        // Convert to CIImage
        guard let ciImage = convertToCIImage(image) else {
            throw FilterError.invalidInputImage
        }

        // Create filter
        guard let ciFilter = CIFilter(name: filter.ciFilterName) else {
            throw FilterError.filterNotAvailable(filter.ciFilterName)
        }

        ciFilter.setValue(ciImage, forKey: kCIInputImageKey)

        if filter.supportsIntensity {
            ciFilter.setValue(intensity, forKey: kCIInputIntensityKey)
        }

        guard let outputImage = ciFilter.outputImage else {
            throw FilterError.filterProcessingFailed(filter.ciFilterName)
        }

        // Render using a temporary context (not ideal for repeated use)
        let context = CIContext(options: nil)
        guard let cgImage = context.createCGImage(outputImage, from: outputImage.extent) else {
            throw FilterError.renderingFailed
        }

        return UIImage(
            cgImage: cgImage,
            scale: image.scale,
            orientation: image.imageOrientation
        )
    }

    // MARK: - Private Helpers

    /// Converts UIImage to CIImage
    private func convertToCIImage(_ image: UIImage) -> CIImage? {
        if let ciImage = image.ciImage {
            return ciImage
        }

        if let cgImage = image.cgImage {
            return CIImage(cgImage: cgImage)
        }

        return nil
    }

    /// Resizes an image to fit within a maximum dimension
    private func resizeImage(_ image: UIImage, maxDimension: CGFloat) -> UIImage {
        let size = image.size
        let aspectRatio = size.width / size.height

        let newSize: CGSize
        if size.width > size.height {
            newSize = CGSize(width: maxDimension, height: maxDimension / aspectRatio)
        } else {
            newSize = CGSize(width: maxDimension * aspectRatio, height: maxDimension)
        }

        let renderer = UIGraphicsImageRenderer(size: newSize)
        return renderer.image { _ in
            image.draw(in: CGRect(origin: .zero, size: newSize))
        }
    }
}
