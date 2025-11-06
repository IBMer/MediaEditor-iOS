import Foundation

/// Errors that can occur during Metal filter processing
@available(iOS 16.0, macOS 13.0, *)
public enum FilterError: LocalizedError, Sendable {
    /// Metal device is not available
    case metalDeviceNotAvailable

    /// Failed to create Metal command buffer or encoder
    case metalCommandCreationFailed

    /// Failed to create compute pipeline state
    case pipelineStateCreationFailed(String)

    /// Failed to create pixel buffer
    case pixelBufferCreationFailed

    /// Failed to create Metal texture from pixel buffer
    case textureCreationFailed

    /// Failed to create texture cache
    case textureCacheCreationFailed

    /// Invalid filter kernel function name
    case invalidKernelFunction(String)

    /// Filter processing failed
    case processingFailed(String)

    /// Invalid parameter value
    case invalidParameter(String, value: Float)

    public var errorDescription: String? {
        switch self {
        case .metalDeviceNotAvailable:
            return "Metal device is not available on this system"
        case .metalCommandCreationFailed:
            return "Failed to create Metal command buffer or encoder"
        case .pipelineStateCreationFailed(let filter):
            return "Failed to create compute pipeline state for filter: \(filter)"
        case .pixelBufferCreationFailed:
            return "Failed to create output pixel buffer"
        case .textureCreationFailed:
            return "Failed to create Metal texture from pixel buffer"
        case .textureCacheCreationFailed:
            return "Failed to create CVMetalTextureCache"
        case .invalidKernelFunction(let name):
            return "Invalid or missing kernel function: \(name)"
        case .processingFailed(let reason):
            return "Filter processing failed: \(reason)"
        case .invalidParameter(let name, let value):
            return "Invalid parameter '\(name)' with value \(value)"
        }
    }

    public var recoverySuggestion: String? {
        switch self {
        case .metalDeviceNotAvailable:
            return "Ensure you are running on a device with Metal support"
        case .pipelineStateCreationFailed:
            return "Check if the shader code is valid and compiled correctly"
        case .invalidParameter(let name, _):
            return "Ensure '\(name)' is within valid range (typically 0.0-1.0)"
        default:
            return nil
        }
    }
}
