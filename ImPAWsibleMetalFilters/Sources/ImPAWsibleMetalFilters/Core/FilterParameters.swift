import Foundation

/// Parameter container for filter customization (supports presets + custom values)
///
/// This struct provides a type-safe way to configure filter parameters with:
/// - Universal intensity control (0.0 = no effect, 1.0 = full effect)
/// - Filter-specific custom parameters (e.g., warmth for sepia, contrast for mono)
/// - Convenient preset factories for common use cases
///
/// Example usage:
/// ```swift
/// // Use default preset
/// let params = FilterParameters.preset(for: .sepia)
///
/// // Custom sepia with more warmth
/// let customSepia = FilterParameters.sepia(warmth: 0.9, intensity: 1.0)
///
/// // Manual construction
/// let custom = FilterParameters(intensity: 0.8, customParams: ["contrast": 1.2])
/// ```
@available(iOS 16.0, macOS 13.0, *)
public struct FilterParameters: Sendable, Equatable {
    /// Universal filter intensity (0.0 = no effect, 1.0 = full effect)
    /// - Note: Automatically clamped to 0.0...1.0 range
    public let intensity: Float

    /// Filter-specific custom parameters
    /// - Common keys: "warmth", "contrast", "brightness"
    public let customParams: [String: Float]

    /// Creates filter parameters with intensity and optional custom values
    /// - Parameters:
    ///   - intensity: Effect strength (automatically clamped to 0.0...1.0)
    ///   - customParams: Dictionary of filter-specific parameters
    public init(intensity: Float = 1.0, customParams: [String: Float] = [:]) {
        self.intensity = max(0.0, min(1.0, intensity))
        self.customParams = customParams
    }

    // MARK: - Preset Factories

    /// Returns recommended preset parameters for the given filter
    /// - Parameter filter: The target filter
    /// - Returns: Optimal parameter configuration for the filter
    public static func preset(for filter: MetalFilter) -> FilterParameters {
        switch filter {
        case .none:
            return FilterParameters(intensity: 0.0)

        case .mono:
            return FilterParameters(
                intensity: 1.0,
                customParams: ["contrast": 1.1]
            )

        case .noir:
            return FilterParameters(intensity: 1.0)

        case .sepia:
            return FilterParameters(
                intensity: 1.0,
                customParams: ["warmth": 0.7]
            )

        case .vintage:
            return FilterParameters(intensity: 1.0)

        case .tonal:
            return FilterParameters(intensity: 1.0)

        case .transfer:
            return FilterParameters(intensity: 1.0)

        case .chrome:
            return FilterParameters(intensity: 1.0)

        case .fade:
            return FilterParameters(
                intensity: 0.8,
                customParams: ["brightness": 1.1]
            )

        case .instant:
            return FilterParameters(intensity: 1.0)
        }
    }

    // MARK: - Filter-Specific Convenience Factories

    /// Creates Sepia filter parameters with custom warmth
    /// - Parameters:
    ///   - warmth: Warm tone intensity (0.0 = neutral, 1.0 = very warm) [default: 0.7]
    ///   - intensity: Overall filter strength [default: 1.0]
    /// - Returns: Configured sepia parameters
    public static func sepia(warmth: Float = 0.7, intensity: Float = 1.0) -> FilterParameters {
        let clampedWarmth = max(0.0, min(1.0, warmth))
        return FilterParameters(
            intensity: intensity,
            customParams: ["warmth": clampedWarmth]
        )
    }

    /// Creates Mono filter parameters with custom contrast
    /// - Parameters:
    ///   - contrast: Contrast enhancement (0.8 = low, 1.0 = normal, 1.5 = high) [default: 1.1]
    ///   - intensity: Overall filter strength [default: 1.0]
    /// - Returns: Configured mono parameters
    public static func mono(contrast: Float = 1.1, intensity: Float = 1.0) -> FilterParameters {
        let clampedContrast = max(0.8, min(1.5, contrast))
        return FilterParameters(
            intensity: intensity,
            customParams: ["contrast": clampedContrast]
        )
    }

    /// Creates Fade filter parameters with custom brightness
    /// - Parameters:
    ///   - brightness: Brightness adjustment (0.8 = darker, 1.0 = normal, 1.3 = brighter) [default: 1.1]
    ///   - intensity: Overall filter strength [default: 0.8]
    /// - Returns: Configured fade parameters
    public static func fade(brightness: Float = 1.1, intensity: Float = 0.8) -> FilterParameters {
        let clampedBrightness = max(0.8, min(1.3, brightness))
        return FilterParameters(
            intensity: intensity,
            customParams: ["brightness": clampedBrightness]
        )
    }

    // MARK: - Parameter Access Helpers

    /// Safely retrieves a custom parameter value with fallback
    /// - Parameters:
    ///   - key: Parameter key
    ///   - defaultValue: Fallback value if key doesn't exist
    /// - Returns: Parameter value or default
    public func customParameter(_ key: String, default defaultValue: Float) -> Float {
        customParams[key] ?? defaultValue
    }

    /// Validates all custom parameters are within acceptable ranges
    /// - Throws: `FilterError.invalidParameter` if any value is out of bounds
    public func validate(for filter: MetalFilter) throws {
        switch filter {
        case .sepia:
            if let warmth = customParams["warmth"], !(0.0...1.0).contains(warmth) {
                throw FilterError.invalidParameter("warmth", value: warmth)
            }

        case .mono:
            if let contrast = customParams["contrast"], !(0.8...1.5).contains(contrast) {
                throw FilterError.invalidParameter("contrast", value: contrast)
            }

        case .fade:
            if let brightness = customParams["brightness"], !(0.8...1.3).contains(brightness) {
                throw FilterError.invalidParameter("brightness", value: brightness)
            }

        default:
            break
        }
    }
}
