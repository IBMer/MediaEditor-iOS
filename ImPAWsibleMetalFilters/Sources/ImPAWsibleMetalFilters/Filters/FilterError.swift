import Foundation

/// Filter processing errors
@available(iOS 17.0, macOS 13.0, *)
public enum FilterError: LocalizedError, Sendable {
    case filterNotAvailable(String)
    case filterProcessingFailed(String)
    case pixelBufferCreationFailed
    case invalidIntensity(Double)
    case metalDeviceNotAvailable

    public var errorDescription: String? {
        switch self {
        case .filterNotAvailable(let name):
            return "Filter '\(name)' is not available"
        case .filterProcessingFailed(let name):
            return "Failed to process filter '\(name)'"
        case .pixelBufferCreationFailed:
            return "Failed to create pixel buffer"
        case .invalidIntensity(let value):
            return "Invalid intensity value: \(value). Must be between 0.0 and 1.0"
        case .metalDeviceNotAvailable:
            return "Metal device is not available on this device"
        }
    }

    public var recoverySuggestion: String? {
        switch self {
        case .metalDeviceNotAvailable:
            return "Ensure you are running on a Metal-capable device"
        case .invalidIntensity:
            return "Use intensity value between 0.0 and 1.0"
        default:
            return nil
        }
    }
}
