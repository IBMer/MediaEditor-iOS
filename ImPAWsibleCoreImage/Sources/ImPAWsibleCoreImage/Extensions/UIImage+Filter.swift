import UIKit

/// Convenient extension for applying filters directly to UIImage
@available(iOS 16.0, macOS 13.0, *)
public extension UIImage {
    // MARK: - Async Methods

    /// Applies a filter to this image asynchronously
    ///
    /// This is the recommended way to apply filters as it doesn't block the main thread
    /// and provides optimal performance.
    ///
    /// Example:
    /// ```swift
    /// let filtered = try await myImage.applying(.mono)
    /// ```
    ///
    /// - Parameters:
    ///   - filter: The filter to apply
    ///   - intensity: The filter intensity (0.0 - 1.0), only applicable for filters that support it
    /// - Returns: A new UIImage with the filter applied
    /// - Throws: FilterError if processing fails
    func applying(_ filter: ImPAWsibleFilter, intensity: Double = 1.0) async throws -> UIImage {
        let processor = FilterProcessor()
        return try await processor.process(self, filter: filter, intensity: intensity)
    }

    /// Generates a thumbnail with a filter applied
    ///
    /// Useful for creating preview images efficiently without processing the full-resolution image.
    ///
    /// Example:
    /// ```swift
    /// let thumbnail = try await myImage.filterThumbnail(.sepia, maxDimension: 200)
    /// ```
    ///
    /// - Parameters:
    ///   - filter: The filter to apply
    ///   - maxDimension: Maximum width or height of the thumbnail (default: 256)
    ///   - intensity: The filter intensity (0.0 - 1.0)
    /// - Returns: A thumbnail UIImage with the filter applied
    /// - Throws: FilterError if processing fails
    func filterThumbnail(
        _ filter: ImPAWsibleFilter,
        maxDimension: CGFloat = 256,
        intensity: Double = 1.0
    ) async throws -> UIImage {
        let processor = FilterProcessor()
        return try await processor.generateThumbnail(
            self,
            filter: filter,
            maxDimension: maxDimension,
            intensity: intensity
        )
    }

    // MARK: - Synchronous Methods

    /// Applies a filter to this image synchronously
    ///
    /// - Warning: This method blocks the calling thread. Use the async version when possible.
    ///
    /// Example:
    /// ```swift
    /// let filtered = try myImage.applyingSync(.noir)
    /// ```
    ///
    /// - Parameters:
    ///   - filter: The filter to apply
    ///   - intensity: The filter intensity (0.0 - 1.0)
    /// - Returns: A new UIImage with the filter applied
    /// - Throws: FilterError if processing fails
    func applyingSync(_ filter: ImPAWsibleFilter, intensity: Double = 1.0) throws -> UIImage {
        let processor = FilterProcessor()
        return try processor.processSync(self, filter: filter, intensity: intensity)
    }

    // MARK: - Batch Processing

    /// Applies the same filter to multiple images concurrently
    ///
    /// Static method for efficiently processing multiple images with the same filter.
    ///
    /// Example:
    /// ```swift
    /// let filtered = try await UIImage.applyingBatch(images, filter: .vintage)
    /// ```
    ///
    /// - Parameters:
    ///   - images: Array of images to process
    ///   - filter: The filter to apply to all images
    ///   - intensity: The filter intensity (0.0 - 1.0)
    /// - Returns: Array of filtered images in the same order
    /// - Throws: FilterError if processing fails
    static func applyingBatch(
        _ images: [UIImage],
        filter: ImPAWsibleFilter,
        intensity: Double = 1.0
    ) async throws -> [UIImage] {
        let processor = FilterProcessor()
        return try await processor.processBatch(images, filter: filter, intensity: intensity)
    }

    // MARK: - Preview Helpers

    /// Generates thumbnails for all available filters
    ///
    /// Useful for creating a filter picker interface where users can preview each filter.
    ///
    /// Example:
    /// ```swift
    /// let previews = try await myImage.generateFilterPreviews(maxDimension: 100)
    /// // Returns dictionary: [.mono: thumbnail, .sepia: thumbnail, ...]
    /// ```
    ///
    /// - Parameters:
    ///   - maxDimension: Maximum dimension for each thumbnail (default: 128)
    ///   - filters: Specific filters to generate previews for (defaults to all)
    /// - Returns: Dictionary mapping filters to their preview images
    /// - Throws: FilterError if processing fails
    func generateFilterPreviews(
        maxDimension: CGFloat = 128,
        filters: [ImPAWsibleFilter] = ImPAWsibleFilter.allCases
    ) async throws -> [ImPAWsibleFilter: UIImage] {
        let processor = FilterProcessor()

        return try await withThrowingTaskGroup(
            of: (ImPAWsibleFilter, UIImage).self
        ) { group in
            for filter in filters {
                group.addTask {
                    let thumbnail = try await processor.generateThumbnail(
                        self,
                        filter: filter,
                        maxDimension: maxDimension
                    )
                    return (filter, thumbnail)
                }
            }

            var results: [ImPAWsibleFilter: UIImage] = [:]
            for try await (filter, thumbnail) in group {
                results[filter] = thumbnail
            }
            return results
        }
    }
}
