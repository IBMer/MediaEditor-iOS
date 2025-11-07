import Foundation

/// Represents all available Metal-accelerated photo filters
///
/// Each filter corresponds to a GPU compute shader that processes video frames in real-time.
/// Designed for high-performance video processing (target: < 5ms @ 1920x1080).
///
/// Example usage:
/// ```swift
/// let pipeline = try MetalFilterPipeline()
/// let filtered = try pipeline.process(pixelBuffer: frame, filter: .mono)
/// ```
@available(iOS 16.0, macOS 13.0, *)
public enum MetalFilter: String, CaseIterable, Identifiable, Sendable {
    /// No filter applied - returns the original frame
    case none

    /// Black and white filter with adjustable contrast
    /// - GPU Kernel: `monoFilter`
    /// - Custom Parameters: contrast (0.8-1.5, default: 1.1)
    case mono

    /// Dramatic black and white film effect with enhanced contrast
    /// - GPU Kernel: `noirFilter`
    case noir

    /// Warm sepia tone with adjustable warmth
    /// - GPU Kernel: `sepiaFilter`
    /// - Custom Parameters: warmth (0.0-1.0, default: 0.7)
    case sepia

    /// Vintage photo processing effect with desaturated warm tones
    /// - GPU Kernel: `vintageFilter`
    case vintage

    /// Soft tonal color effect with midtone lift
    /// - GPU Kernel: `tonalFilter`
    case tonal

    /// Color transfer effect with enhanced greens and cyans
    /// - GPU Kernel: `transferFilter`
    case transfer

    /// Metallic chrome effect with high contrast desaturation
    /// - GPU Kernel: `chromeFilter`
    case chrome

    /// Faded photograph look with adjustable brightness
    /// - GPU Kernel: `fadeFilter`
    /// - Custom Parameters: brightness (0.8-1.3, default: 1.1)
    case fade

    /// Instant camera photograph style with vignette
    /// - GPU Kernel: `instantFilter`
    case instant

    // MARK: - Public Properties

    /// Unique identifier for Identifiable conformance
    public var id: String { rawValue }

    /// User-friendly display name (localization-ready)
    public var displayName: String {
        switch self {
        case .none: return NSLocalizedString("Original", comment: "Filter name")
        case .mono: return NSLocalizedString("Mono", comment: "Filter name")
        case .noir: return NSLocalizedString("Noir", comment: "Filter name")
        case .sepia: return NSLocalizedString("Sepia", comment: "Filter name")
        case .vintage: return NSLocalizedString("Vintage", comment: "Filter name")
        case .tonal: return NSLocalizedString("Tonal", comment: "Filter name")
        case .transfer: return NSLocalizedString("Transfer", comment: "Filter name")
        case .chrome: return NSLocalizedString("Chrome", comment: "Filter name")
        case .fade: return NSLocalizedString("Fade", comment: "Filter name")
        case .instant: return NSLocalizedString("Instant", comment: "Filter name")
        }
    }

    /// The Metal compute kernel function name
    public var kernelFunctionName: String {
        switch self {
        case .none: return ""  // No processing needed
        case .mono: return "monoFilter"
        case .noir: return "noirFilter"
        case .sepia: return "sepiaFilter"
        case .vintage: return "vintageFilter"
        case .tonal: return "tonalFilter"
        case .transfer: return "transferFilter"
        case .chrome: return "chromeFilter"
        case .fade: return "fadeFilter"
        case .instant: return "instantFilter"
        }
    }

    /// Whether this filter supports custom parameter tuning
    public var supportsCustomParameters: Bool {
        switch self {
        case .sepia, .mono, .fade:
            return true
        default:
            return false
        }
    }

    /// Default parameter preset for this filter
    public var defaultParameters: FilterParameters {
        FilterParameters.preset(for: self)
    }

    /// Brief description of the filter's visual effect
    public var description: String {
        switch self {
        case .none:
            return NSLocalizedString("No filter applied", comment: "Filter description")
        case .mono:
            return NSLocalizedString("Black and white with high contrast", comment: "Filter description")
        case .noir:
            return NSLocalizedString("Dramatic black and white film effect", comment: "Filter description")
        case .sepia:
            return NSLocalizedString("Warm brown tone reminiscent of old photographs", comment: "Filter description")
        case .vintage:
            return NSLocalizedString("Classic vintage film processing look", comment: "Filter description")
        case .tonal:
            return NSLocalizedString("Soft tonal color effect with lifted midtones", comment: "Filter description")
        case .transfer:
            return NSLocalizedString("Enhanced green and cyan color transfer", comment: "Filter description")
        case .chrome:
            return NSLocalizedString("Metallic chrome effect with high contrast", comment: "Filter description")
        case .fade:
            return NSLocalizedString("Faded vintage photograph look", comment: "Filter description")
        case .instant:
            return NSLocalizedString("Instant camera photograph style with vignette", comment: "Filter description")
        }
    }

    /// Typical GPU processing time estimate at 1920x1080
    /// - Note: Actual performance varies by device
    public var estimatedProcessingTime: String {
        switch self {
        case .none:
            return "~0ms (passthrough)"
        case .instant:
            return "~4-6ms (with vignette calculation)"
        default:
            return "~2-4ms"
        }
    }
}
