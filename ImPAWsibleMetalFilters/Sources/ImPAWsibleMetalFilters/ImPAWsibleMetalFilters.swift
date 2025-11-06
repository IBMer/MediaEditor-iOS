/// ImPAWsibleMetalFilters - High-Performance Metal Video Filters
///
/// A modern Swift package for real-time GPU-accelerated video filtering using Metal.
/// Designed for DuoMira dual-camera recording with 30fps target performance.
///
/// ## Features
/// - 10 professional video filters (Mono, Noir, Sepia, Vintage, etc.)
/// - GPU-accelerated Metal compute shaders
/// - Zero-copy CVPixelBuffer processing
/// - Real-time performance (< 5ms @ 1920x1080)
/// - Thread-safe pipeline architecture
/// - Independent front/back camera filtering
///
/// ## Quick Start
///
/// ### Apply a filter to a video frame:
/// ```swift
/// import ImPAWsibleMetalFilters
///
/// let pipeline = try MetalFilterPipeline()
/// let filtered = try pipeline.process(
///     pixelBuffer: videoFrame,
///     filter: .mono
/// )
/// ```
///
/// ### Custom filter parameters:
/// ```swift
/// let params = FilterParameters.sepia(warmth: 0.9, intensity: 1.0)
/// let filtered = try pipeline.process(
///     pixelBuffer: videoFrame,
///     filter: .sepia,
///     parameters: params
/// )
/// ```
///
/// ## Topics
///
/// ### Core Processing
/// - ``MetalFilterPipeline``
/// - ``MetalFilterContext``
/// - ``TextureCache``
///
/// ### Filters
/// - ``MetalFilter``
/// - ``FilterParameters``
///
/// ### Errors
/// - ``FilterError``
///
/// ## Performance
///
/// Target metrics on Apple Silicon (iPhone 12+, M1+):
/// - 1920x1080: < 5ms per frame
/// - 1280x720: < 2ms per frame
/// - 3840x2160: < 15ms per frame
///
/// Actual performance varies by:
/// - Device GPU capabilities
/// - Filter complexity (instant filter with vignette is slowest)
/// - Frame pixel format (BGRA fastest, YUV requires conversion)
///
/// ## Architecture
///
/// ```
/// CVPixelBuffer (Camera)
///       ↓
/// TextureCache (Zero-copy to MTLTexture)
///       ↓
/// Metal Compute Kernel (GPU Filtering)
///       ↓
/// CVPixelBuffer (Filtered Output)
/// ```
///
/// ## Integration with DuoMira
///
/// For dual-camera recording:
/// 1. Create separate pipelines for front/back cameras (optional but recommended)
/// 2. Apply filters before video composition
/// 3. Use independent filter selection per camera
/// 4. Monitor performance to maintain 30fps target
///
/// Example:
/// ```swift
/// // Front camera: Noir filter
/// let frontFiltered = try frontPipeline.process(
///     pixelBuffer: frontFrame,
///     filter: .noir
/// )
///
/// // Back camera: Vintage filter
/// let backFiltered = try backPipeline.process(
///     pixelBuffer: backFrame,
///     filter: .vintage
/// )
///
/// // Compose dual-camera layout with filtered frames
/// let composed = compositor.compose(main: backFiltered, pip: frontFiltered)
/// ```
///
/// ## Requirements
///
/// - iOS 16.0+ / macOS 13.0+
/// - Swift 5.9+
/// - Metal-capable device
/// - CVPixelBuffers must have `kCVPixelBufferMetalCompatibilityKey` set to true
///
/// ## Resources
///
/// - [Metal Programming Guide](https://developer.apple.com/metal/)
/// - [Core Video Programming Guide](https://developer.apple.com/library/archive/documentation/GraphicsImaging/Conceptual/CoreVideo/)
/// - [DuoMira Project Documentation](https://github.com/IBMer/DuoMira)

import Foundation

/// Library version information
@available(iOS 16.0, macOS 13.0, *)
public enum ImPAWsibleMetalFilters {
    /// Current version
    public static let version = "1.0.0"

    /// Library name
    public static let name = "ImPAWsibleMetalFilters"

    /// Supported Metal version
    public static let metalVersion = "Metal 2.0+"

    /// Minimum GPU family
    public static let minimumGPUFamily = "Apple3 / Mac1"

    /// Checks if current device supports Metal filtering
    /// - Returns: true if device is capable
    public static var isSupported: Bool {
        do {
            let context = try MetalFilterContext.shared
            return context.isCapable
        } catch {
            return false
        }
    }

    /// Returns detailed capability information
    public static var capabilityInfo: String {
        guard let context = try? MetalFilterContext.shared else {
            return "Metal not available"
        }

        return """
        ImPAWsibleMetalFilters Capability Info:
        - Version: \(version)
        - Device: \(context.deviceName)
        - Metal Capable: \(context.isCapable)
        - Available Filters: \(MetalFilter.allCases.count)
        """
    }
}
