import Metal
import CoreVideo
import Foundation

/// High-performance texture cache for CVPixelBuffer ↔ MTLTexture conversion
///
/// This class enables zero-copy texture creation from pixel buffers using `CVMetalTextureCache`,
/// which is critical for real-time video processing performance.
///
/// Benefits:
/// - Zero-copy: CVPixelBuffer memory is directly mapped to Metal texture
/// - Automatic caching: Textures are reused when possible
/// - Thread-safe: Can be called from multiple queues
///
/// Usage:
/// ```swift
/// let cache = try TextureCache(device: metalDevice)
/// let texture = try cache.makeTexture(from: pixelBuffer, usage: .read)
/// ```
@available(iOS 16.0, macOS 13.0, *)
public final class TextureCache: @unchecked Sendable {
    // MARK: - Properties

    /// The underlying Core Video Metal texture cache
    private let cache: CVMetalTextureCache

    /// Associated Metal device
    private let device: MTLDevice

    // MARK: - Initialization

    /// Creates a new texture cache for the given Metal device
    /// - Parameter device: The Metal device to create textures for
    /// - Throws: `FilterError.textureCacheCreationFailed` if creation fails
    public init(device: MTLDevice) throws {
        var textureCache: CVMetalTextureCache?

        let status = CVMetalTextureCacheCreate(
            kCFAllocatorDefault,
            nil,  // Default cache attributes
            device,
            nil,  // Default texture attributes
            &textureCache
        )

        guard status == kCVReturnSuccess, let cache = textureCache else {
            throw FilterError.textureCacheCreationFailed
        }

        self.cache = cache
        self.device = device
    }

    // MARK: - Texture Creation

    /// Texture usage intent
    public enum Usage {
        case read   // Input texture (shader will read)
        case write  // Output texture (shader will write)
    }

    /// Creates a Metal texture from a CVPixelBuffer with zero-copy
    /// - Parameters:
    ///   - pixelBuffer: Source pixel buffer
    ///   - planeIndex: Plane index for planar formats (default: 0 for interleaved)
    ///   - pixelFormat: Desired Metal pixel format (auto-detected if nil)
    ///   - usage: Texture usage intent (.read or .write)
    /// - Returns: Metal texture mapped to pixel buffer memory
    /// - Throws: `FilterError.textureCreationFailed` if conversion fails
    public func makeTexture(
        from pixelBuffer: CVPixelBuffer,
        planeIndex: Int = 0,
        pixelFormat: MTLPixelFormat? = nil,
        usage: Usage = .read
    ) throws -> MTLTexture {
        let width = CVPixelBufferGetWidthOfPlane(pixelBuffer, planeIndex)
        let height = CVPixelBufferGetHeightOfPlane(pixelBuffer, planeIndex)

        // Auto-detect pixel format if not specified
        let format = pixelFormat ?? detectPixelFormat(for: pixelBuffer, plane: planeIndex)

        var cvMetalTexture: CVMetalTexture?

        let status = CVMetalTextureCacheCreateTextureFromImage(
            kCFAllocatorDefault,
            cache,
            pixelBuffer,
            nil,  // Texture attributes
            format,
            width,
            height,
            planeIndex,
            &cvMetalTexture
        )

        guard status == kCVReturnSuccess,
              let cvTexture = cvMetalTexture,
              let metalTexture = CVMetalTextureGetTexture(cvTexture) else {
            throw FilterError.textureCreationFailed
        }

        return metalTexture
    }

    // MARK: - Cache Management

    /// Flushes the texture cache to free unused textures
    /// - Note: Call this periodically if processing many different sized frames
    public func flush() {
        CVMetalTextureCacheFlush(cache, 0)
    }

    // MARK: - Private Helpers

    /// Auto-detects appropriate Metal pixel format for a CVPixelBuffer
    private func detectPixelFormat(for pixelBuffer: CVPixelBuffer, plane: Int) -> MTLPixelFormat {
        let pixelFormat = CVPixelBufferGetPixelFormatType(pixelBuffer)

        switch pixelFormat {
        // BGRA formats (most common for video)
        case kCVPixelFormatType_32BGRA:
            return .bgra8Unorm

        case kCVPixelFormatType_32RGBA:
            return .rgba8Unorm

        // YCbCr formats (common for camera input)
        case kCVPixelFormatType_420YpCbCr8BiPlanarFullRange,
             kCVPixelFormatType_420YpCbCr8BiPlanarVideoRange:
            return plane == 0 ? .r8Unorm : .rg8Unorm

        // HDR formats (10-bit)
        case kCVPixelFormatType_420YpCbCr10BiPlanarFullRange,
             kCVPixelFormatType_420YpCbCr10BiPlanarVideoRange:
            return plane == 0 ? .r16Unorm : .rg16Unorm

        // Fallback to BGRA
        default:
            return .bgra8Unorm
        }
    }
}

// MARK: - Debug Helpers

@available(iOS 16.0, macOS 13.0, *)
extension TextureCache {
    /// Returns cache statistics for debugging
    public var debugInfo: String {
        """
        TextureCache Debug Info:
        - Device: \(device.name)
        - Cache: \(cache)
        """
    }
}

// MARK: - CVPixelBuffer Validation

@available(iOS 16.0, macOS 13.0, *)
extension CVPixelBuffer {
    /// Checks if pixel buffer is Metal-compatible
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

    /// Returns a description of the pixel buffer format
    var formatDescription: String {
        let format = CVPixelBufferGetPixelFormatType(self)
        let width = CVPixelBufferGetWidth(self)
        let height = CVPixelBufferGetHeight(self)

        let formatName: String
        switch format {
        case kCVPixelFormatType_32BGRA:
            formatName = "BGRA"
        case kCVPixelFormatType_32RGBA:
            formatName = "RGBA"
        case kCVPixelFormatType_420YpCbCr8BiPlanarFullRange:
            formatName = "NV12 (Full Range)"
        case kCVPixelFormatType_420YpCbCr8BiPlanarVideoRange:
            formatName = "NV12 (Video Range)"
        default:
            formatName = "Unknown (\(format))"
        }

        return "\(width)x\(height) \(formatName)"
    }
}
