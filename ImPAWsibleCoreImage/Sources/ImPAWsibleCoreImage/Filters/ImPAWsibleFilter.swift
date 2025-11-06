import Foundation
import CoreImage

/// Represents all available photo filters in the ImPAWsible Core Image library.
///
/// Each filter corresponds to a Core Image built-in filter that creates
/// specific photographic effects. Most filters are parameter-free except for
/// the input image, making them easy to apply instantly.
///
/// Example usage:
/// ```swift
/// let filteredImage = try await image.applying(.mono)
/// ```
@available(iOS 16.0, macOS 13.0, *)
public enum ImPAWsibleFilter: String, CaseIterable, Identifiable, Sendable {
    /// No filter applied - returns the original image
    case none

    /// Black and white filter with exaggerated contrast
    /// - Core Image: CIPhotoEffectMono
    /// - Available: iOS 7.0+, macOS 10.9+
    case mono

    /// Black and white filter with darker tones and high contrast
    /// - Core Image: CIPhotoEffectNoir
    /// - Available: iOS 7.0+, macOS 10.9+
    case noir

    /// Warm sepia tone effect with adjustable intensity
    /// - Core Image: CISepiaTone
    /// - Available: iOS 5.0+, macOS 10.4+
    /// - Note: This filter supports intensity adjustment
    case sepia

    /// Vintage photo processing effect
    /// - Core Image: CIPhotoEffectProcess
    /// - Available: iOS 7.0+, macOS 10.9+
    case vintage

    /// Tonal color effect
    /// - Core Image: CIPhotoEffectTonal
    /// - Available: iOS 7.0+, macOS 10.9+
    case tonal

    /// Transfer color effect
    /// - Core Image: CIPhotoEffectTransfer
    /// - Available: iOS 7.0+, macOS 10.9+
    case transfer

    /// Chrome color effect with enhanced metallic tones
    /// - Core Image: CIPhotoEffectChrome
    /// - Available: iOS 7.0+, macOS 10.9+
    case chrome

    /// Faded color effect
    /// - Core Image: CIPhotoEffectFade
    /// - Available: iOS 7.0+, macOS 10.9+
    case fade

    /// Instant camera effect
    /// - Core Image: CIPhotoEffectInstant
    /// - Available: iOS 7.0+, macOS 10.9+
    case instant

    // MARK: - Public Properties

    /// Unique identifier for Identifiable conformance
    public var id: String { rawValue }

    /// User-friendly display name for the filter
    public var displayName: String {
        switch self {
        case .none: return "Original"
        case .mono: return "Mono"
        case .noir: return "Noir"
        case .sepia: return "Sepia"
        case .vintage: return "Vintage"
        case .tonal: return "Tonal"
        case .transfer: return "Transfer"
        case .chrome: return "Chrome"
        case .fade: return "Fade"
        case .instant: return "Instant"
        }
    }

    /// The Core Image filter name used for processing
    public var ciFilterName: String {
        switch self {
        case .none: return ""
        case .mono: return "CIPhotoEffectMono"
        case .noir: return "CIPhotoEffectNoir"
        case .sepia: return "CISepiaTone"
        case .vintage: return "CIPhotoEffectProcess"
        case .tonal: return "CIPhotoEffectTonal"
        case .transfer: return "CIPhotoEffectTransfer"
        case .chrome: return "CIPhotoEffectChrome"
        case .fade: return "CIPhotoEffectFade"
        case .instant: return "CIPhotoEffectInstant"
        }
    }

    /// Whether this filter supports intensity adjustment
    public var supportsIntensity: Bool {
        switch self {
        case .sepia:
            return true
        default:
            return false
        }
    }

    /// Brief description of the filter's effect
    public var description: String {
        switch self {
        case .none:
            return "No filter applied"
        case .mono:
            return "Black and white with high contrast"
        case .noir:
            return "Dramatic black and white film effect"
        case .sepia:
            return "Warm brown tone reminiscent of old photographs"
        case .vintage:
            return "Classic film processing look"
        case .tonal:
            return "Soft tonal color effect"
        case .transfer:
            return "Color transfer effect"
        case .chrome:
            return "Metallic chrome effect"
        case .fade:
            return "Faded vintage photograph look"
        case .instant:
            return "Instant camera photograph style"
        }
    }
}
