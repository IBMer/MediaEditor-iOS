import Metal
import Foundation

/// Thread-safe Metal context manager (singleton pattern)
///
/// This class manages:
/// - Metal device access
/// - Command queue creation
/// - Compute pipeline state caching
/// - Default Metal library loading
///
/// Usage:
/// ```swift
/// let context = try MetalFilterContext.shared
/// let pipelineState = try context.pipelineState(for: .mono)
/// ```
@available(iOS 16.0, macOS 13.0, *)
public final class MetalFilterContext: @unchecked Sendable {
    // MARK: - Singleton

    /// Shared singleton instance
    public static let shared: MetalFilterContext = {
        do {
            return try MetalFilterContext()
        } catch {
            fatalError("Failed to initialize MetalFilterContext: \(error)")
        }
    }()

    // MARK: - Properties

    /// The Metal device (typically GPU)
    public let device: MTLDevice

    /// Command queue for submitting work to GPU
    public let commandQueue: MTLCommandQueue

    /// Default Metal library containing compiled shaders
    private let library: MTLLibrary

    /// Cache of compiled compute pipeline states (thread-safe)
    private var pipelineCache: [String: MTLComputePipelineState] = [:]
    private let cacheLock = NSLock()

    // MARK: - Initialization

    /// Private initializer (use `shared` singleton)
    private init() throws {
        // 1. Get default Metal device
        guard let device = MTLCreateSystemDefaultDevice() else {
            throw FilterError.metalDeviceNotAvailable
        }
        self.device = device

        // 2. Create command queue
        guard let commandQueue = device.makeCommandQueue() else {
            throw FilterError.metalCommandCreationFailed
        }
        self.commandQueue = commandQueue

        // 3. Load default Metal library from bundle
        guard let library = try? device.makeDefaultLibrary(bundle: .module) else {
            // Fallback: try to load from main bundle (for app integration)
            guard let library = device.makeDefaultLibrary() else {
                throw FilterError.pipelineStateCreationFailed("Failed to load Metal library")
            }
            self.library = library
            return
        }
        self.library = library
    }

    // MARK: - Pipeline State Management

    /// Gets or creates a compute pipeline state for the given filter
    /// - Parameter filter: The target filter
    /// - Returns: Compiled compute pipeline state (cached for reuse)
    /// - Throws: `FilterError` if shader compilation fails
    public func pipelineState(for filter: MetalFilter) throws -> MTLComputePipelineState {
        // No processing needed for .none filter
        guard filter != .none else {
            throw FilterError.invalidKernelFunction("none filter has no kernel")
        }

        let functionName = filter.kernelFunctionName

        // Check cache first (thread-safe)
        cacheLock.lock()
        if let cached = pipelineCache[functionName] {
            cacheLock.unlock()
            return cached
        }
        cacheLock.unlock()

        // Load kernel function
        guard let function = library.makeFunction(name: functionName) else {
            throw FilterError.invalidKernelFunction(functionName)
        }

        // Compile compute pipeline state
        let pipelineState: MTLComputePipelineState
        do {
            pipelineState = try device.makeComputePipelineState(function: function)
        } catch {
            throw FilterError.pipelineStateCreationFailed("\(functionName): \(error.localizedDescription)")
        }

        // Cache for future use (thread-safe)
        cacheLock.lock()
        pipelineCache[functionName] = pipelineState
        cacheLock.unlock()

        return pipelineState
    }

    /// Precompiles all filter shaders for faster first-use
    /// - Note: Call this during app initialization to avoid frame drops
    public func warmupAllFilters() {
        DispatchQueue.global(qos: .utility).async {
            for filter in MetalFilter.allCases where filter != .none {
                _ = try? self.pipelineState(for: filter)
            }
        }
    }

    /// Clears the pipeline state cache (useful for memory pressure)
    public func clearCache() {
        cacheLock.lock()
        pipelineCache.removeAll()
        cacheLock.unlock()
    }

    // MARK: - Device Capabilities

    /// Checks if the device supports required Metal features
    /// - Returns: true if device is capable of running all filters
    public var isCapable: Bool {
        // Check for Metal 2.0+ features
        guard device.supportsFamily(.common2) else {
            return false
        }

        // Verify compute shader support
        return device.supportsFamily(.apple3) || device.supportsFamily(.mac1)
    }

    /// Returns a human-readable device name
    public var deviceName: String {
        device.name
    }

    /// Recommended thread execution width for this device
    public var recommendedThreadExecutionWidth: Int {
        // Typical GPU warp/wavefront size
        // A100/M1: 32, AMD: 64, Intel: varies
        return 32
    }
}

// MARK: - Debug Helpers

@available(iOS 16.0, macOS 13.0, *)
extension MetalFilterContext {
    /// Returns detailed context information for debugging
    public var debugInfo: String {
        """
        MetalFilterContext Debug Info:
        - Device: \(device.name)
        - Supports Common2: \(device.supportsFamily(.common2))
        - Cached Pipelines: \(pipelineCache.count)
        - Recommended Thread Width: \(recommendedThreadExecutionWidth)
        """
    }

    /// Validates that all filter shaders can be loaded
    /// - Throws: `FilterError` if any shader is missing or invalid
    public func validateAllShaders() throws {
        for filter in MetalFilter.allCases where filter != .none {
            _ = try pipelineState(for: filter)
        }
    }
}
