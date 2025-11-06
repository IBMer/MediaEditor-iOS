import CoreVideo
import Foundation

/// Convenience extensions for CVPixelBuffer to support Metal filtering
@available(iOS 16.0, macOS 13.0, *)
public extension CVPixelBuffer {
    // MARK: - Filter Application

    /// Applies a Metal filter to this pixel buffer
    /// - Parameters:
    ///   - filter: The filter to apply
    ///   - parameters: Custom parameters (uses defaults if nil)
    /// - Returns: Filtered pixel buffer
    /// - Throws: `FilterError` if filtering fails
    func applying(
        _ filter: MetalFilter,
        parameters: FilterParameters? = nil
    ) throws -> CVPixelBuffer {
        let pipeline = try MetalFilterPipeline()
        return try pipeline.process(
            pixelBuffer: self,
            filter: filter,
            parameters: parameters
        )
    }

    // MARK: - Metal Compatibility

    /// Checks if this pixel buffer is Metal-compatible
    var isMetalCompatible: Bool {
        guard let compatible = CVBufferGetAttachment(
            self,
            kCVPixelBufferMetalCompatibilityKey,
            nil
        )?.takeUnretainedValue() as? Bool else {
            return false
        }
        return compatible
    }

    /// Ensures this pixel buffer is Metal-compatible
    /// - Throws: `FilterError` if not compatible
    func ensureMetalCompatible() throws {
        guard isMetalCompatible else {
            throw FilterError.processingFailed("Pixel buffer is not Metal-compatible. Enable kCVPixelBufferMetalCompatibilityKey when creating.")
        }
    }

    // MARK: - Format Information

    /// Returns a human-readable description of the pixel format
    var formatDescription: String {
        let format = CVPixelBufferGetPixelFormatType(self)
        let width = CVPixelBufferGetWidth(self)
        let height = CVPixelBufferGetHeight(self)

        let formatName: String
        switch format {
        case kCVPixelFormatType_32BGRA:
            formatName = "BGRA8888"
        case kCVPixelFormatType_32RGBA:
            formatName = "RGBA8888"
        case kCVPixelFormatType_420YpCbCr8BiPlanarFullRange:
            formatName = "NV12 (Full Range)"
        case kCVPixelFormatType_420YpCbCr8BiPlanarVideoRange:
            formatName = "NV12 (Video Range)"
        case kCVPixelFormatType_420YpCbCr10BiPlanarFullRange:
            formatName = "P010 (10-bit, Full Range)"
        case kCVPixelFormatType_420YpCbCr10BiPlanarVideoRange:
            formatName = "P010 (10-bit, Video Range)"
        default:
            formatName = "Unknown (0x\(String(format: "%X", format)))"
        }

        return "\(width)x\(height) \(formatName)"
    }

    /// Returns the size of this pixel buffer
    var size: CGSize {
        CGSize(
            width: CVPixelBufferGetWidth(self),
            height: CVPixelBufferGetHeight(self)
        )
    }

    /// Returns the pixel format type (FourCC code)
    var pixelFormat: OSType {
        CVPixelBufferGetPixelFormatType(self)
    }

    // MARK: - IOSurface Support

    /// Checks if this pixel buffer is backed by an IOSurface
    var hasIOSurface: Bool {
        CVPixelBufferGetIOSurface(self) != nil
    }

    /// Returns IOSurface information if available
    var ioSurfaceInfo: String? {
        guard let ioSurface = CVPixelBufferGetIOSurface(self)?.takeUnretainedValue() else {
            return nil
        }

        return """
        IOSurface: \(ioSurface)
        - In Use: \(IOSurfaceIsInUse(ioSurface))
        """
    }

    // MARK: - Debug Utilities

    /// Returns comprehensive debug information about this pixel buffer
    var debugDescription: String {
        """
        CVPixelBuffer Debug Info:
        - Format: \(formatDescription)
        - Size: \(size)
        - Metal Compatible: \(isMetalCompatible)
        - Has IOSurface: \(hasIOSurface)
        - Plane Count: \(CVPixelBufferGetPlaneCount(self))
        """
    }

    /// Validates that this pixel buffer meets Metal filtering requirements
    /// - Throws: Detailed `FilterError` if validation fails
    func validateForFiltering() throws {
        // Check Metal compatibility
        try ensureMetalCompatible()

        // Check reasonable dimensions
        let width = CVPixelBufferGetWidth(self)
        let height = CVPixelBufferGetHeight(self)

        guard width > 0 && height > 0 else {
            throw FilterError.processingFailed("Invalid dimensions: \(width)x\(height)")
        }

        guard width <= 8192 && height <= 8192 else {
            throw FilterError.processingFailed("Dimensions too large: \(width)x\(height) (max: 8192x8192)")
        }

        // Check supported pixel format
        let format = CVPixelBufferGetPixelFormatType(self)
        let supportedFormats: [OSType] = [
            kCVPixelFormatType_32BGRA,
            kCVPixelFormatType_32RGBA,
            kCVPixelFormatType_420YpCbCr8BiPlanarFullRange,
            kCVPixelFormatType_420YpCbCr8BiPlanarVideoRange,
            kCVPixelFormatType_420YpCbCr10BiPlanarFullRange,
            kCVPixelFormatType_420YpCbCr10BiPlanarVideoRange
        ]

        guard supportedFormats.contains(format) else {
            throw FilterError.processingFailed("Unsupported pixel format: 0x\(String(format: "%X", format))")
        }
    }
}

// MARK: - Factory Methods

@available(iOS 16.0, macOS 13.0, *)
public extension CVPixelBuffer {
    /// Creates a new Metal-compatible pixel buffer with the same specifications
    /// - Returns: New empty pixel buffer
    /// - Throws: `FilterError` if creation fails
    func createCompatibleBuffer() throws -> CVPixelBuffer {
        let width = CVPixelBufferGetWidth(self)
        let height = CVPixelBufferGetHeight(self)
        let pixelFormat = CVPixelBufferGetPixelFormatType(self)

        var buffer: CVPixelBuffer?
        let status = CVPixelBufferCreate(
            kCFAllocatorDefault,
            width,
            height,
            pixelFormat,
            [
                kCVPixelBufferMetalCompatibilityKey: true,
                kCVPixelBufferIOSurfacePropertiesKey: [:]
            ] as CFDictionary,
            &buffer
        )

        guard status == kCVReturnSuccess, let pixelBuffer = buffer else {
            throw FilterError.pixelBufferCreationFailed
        }

        return pixelBuffer
    }
}
