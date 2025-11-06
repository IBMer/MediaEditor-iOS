import Metal
import CoreVideo
import AVFoundation
import Foundation

/// High-performance Metal filter processing pipeline
///
/// This is the main entry point for applying filters to video frames.
/// Designed for real-time video processing with minimal overhead.
///
/// Performance characteristics:
/// - Target: < 5ms per frame @ 1920x1080
/// - Zero-copy texture binding
/// - Synchronous execution (GPU blocks until complete)
/// - Thread-safe: Can be called from any queue
///
/// Usage:
/// ```swift
/// let pipeline = try MetalFilterPipeline()
/// let filtered = try pipeline.process(
///     pixelBuffer: frame,
///     filter: .mono,
///     parameters: .mono(contrast: 1.2)
/// )
/// ```
@available(iOS 16.0, macOS 13.0, *)
@MainActor
public final class MetalFilterPipeline {
    // MARK: - Properties

    /// Shared Metal context
    private let context: MetalFilterContext

    /// Texture cache for CVPixelBuffer ↔ MTLTexture conversion
    private let textureCache: TextureCache

    /// Pixel buffer pool for output buffer reuse (performance optimization)
    private var outputBufferPool: CVPixelBufferPool?
    private var cachedOutputSize: CGSize = .zero

    // MARK: - Initialization

    /// Creates a new filter pipeline
    /// - Throws: `FilterError` if Metal is unavailable or initialization fails
    public init() throws {
        self.context = try MetalFilterContext.shared
        self.textureCache = try TextureCache(device: context.device)

        // Validate device capabilities
        guard context.isCapable else {
            throw FilterError.metalDeviceNotAvailable
        }
    }

    // MARK: - Main Processing Method

    /// Processes a single pixel buffer with the given filter
    /// - Parameters:
    ///   - pixelBuffer: Input frame (must be Metal-compatible)
    ///   - filter: Filter to apply
    ///   - parameters: Custom parameters (uses filter defaults if nil)
    /// - Returns: Filtered output buffer
    /// - Throws: `FilterError` if processing fails
    public func process(
        pixelBuffer: CVPixelBuffer,
        filter: MetalFilter,
        parameters: FilterParameters? = nil
    ) throws -> CVPixelBuffer {
        // Fast path: no filter, return original buffer
        guard filter != .none else {
            return pixelBuffer
        }

        // Validate Metal compatibility
        guard pixelBuffer.isMetalCompatible else {
            throw FilterError.processingFailed("Pixel buffer is not Metal-compatible")
        }

        let params = parameters ?? filter.defaultParameters
        try params.validate(for: filter)

        // 1. Create input texture (zero-copy)
        let inputTexture = try textureCache.makeTexture(
            from: pixelBuffer,
            usage: .read
        )

        // 2. Get or create output buffer
        let outputBuffer = try getOutputBuffer(matching: pixelBuffer)

        // 3. Create output texture (zero-copy)
        let outputTexture = try textureCache.makeTexture(
            from: outputBuffer,
            usage: .write
        )

        // 4. Execute GPU filtering
        try executeFilter(
            filter: filter,
            inputTexture: inputTexture,
            outputTexture: outputTexture,
            parameters: params
        )

        return outputBuffer
    }

    // MARK: - GPU Execution

    /// Executes the filter kernel on GPU
    private func executeFilter(
        filter: MetalFilter,
        inputTexture: MTLTexture,
        outputTexture: MTLTexture,
        parameters: FilterParameters
    ) throws {
        // 1. Create command buffer
        guard let commandBuffer = context.commandQueue.makeCommandBuffer() else {
            throw FilterError.metalCommandCreationFailed
        }

        guard let encoder = commandBuffer.makeComputeCommandEncoder() else {
            throw FilterError.metalCommandCreationFailed
        }

        // 2. Get compiled pipeline state
        let pipelineState = try context.pipelineState(for: filter)
        encoder.setComputePipelineState(pipelineState)

        // 3. Bind textures
        encoder.setTexture(inputTexture, index: 0)
        encoder.setTexture(outputTexture, index: 1)

        // 4. Bind intensity parameter (universal for all filters)
        var intensity = parameters.intensity
        encoder.setBytes(&intensity, length: MemoryLayout<Float>.size, index: 0)

        // 5. Bind filter-specific parameters
        if filter.supportsCustomParameters {
            try bindCustomParameters(parameters.customParams, to: encoder, for: filter)
        }

        // 6. Calculate thread group sizes
        let threadGroupSize = MTLSize(width: 16, height: 16, depth: 1)
        let threadGroups = MTLSize(
            width: (inputTexture.width + threadGroupSize.width - 1) / threadGroupSize.width,
            height: (inputTexture.height + threadGroupSize.height - 1) / threadGroupSize.height,
            depth: 1
        )

        // 7. Dispatch compute work
        encoder.dispatchThreadgroups(threadGroups, threadsPerThreadgroup: threadGroupSize)
        encoder.endEncoding()

        // 8. Submit and wait for completion (synchronous execution)
        commandBuffer.commit()
        commandBuffer.waitUntilCompleted()

        // 9. Check for errors
        if commandBuffer.status == .error {
            if let error = commandBuffer.error {
                throw FilterError.processingFailed("GPU execution failed: \(error.localizedDescription)")
            } else {
                throw FilterError.processingFailed("GPU execution failed with unknown error")
            }
        }
    }

    /// Binds filter-specific custom parameters to shader buffers
    private func bindCustomParameters(
        _ params: [String: Float],
        to encoder: MTLComputeCommandEncoder,
        for filter: MetalFilter
    ) throws {
        switch filter {
        case .sepia:
            var warmth = params["warmth"] ?? 0.7
            encoder.setBytes(&warmth, length: MemoryLayout<Float>.size, index: 1)

        case .mono:
            var contrast = params["contrast"] ?? 1.1
            encoder.setBytes(&contrast, length: MemoryLayout<Float>.size, index: 1)

        case .fade:
            var brightness = params["brightness"] ?? 1.1
            encoder.setBytes(&brightness, length: MemoryLayout<Float>.size, index: 1)

        default:
            break
        }
    }

    // MARK: - Buffer Management

    /// Gets or creates an output buffer matching the input buffer's specifications
    private func getOutputBuffer(matching inputBuffer: CVPixelBuffer) throws -> CVPixelBuffer {
        let width = CVPixelBufferGetWidth(inputBuffer)
        let height = CVPixelBufferGetHeight(inputBuffer)
        let pixelFormat = CVPixelBufferGetPixelFormatType(inputBuffer)
        let size = CGSize(width: width, height: height)

        // Recreate pool if size changed
        if size != cachedOutputSize || outputBufferPool == nil {
            outputBufferPool = try createPixelBufferPool(
                width: width,
                height: height,
                pixelFormat: pixelFormat
            )
            cachedOutputSize = size
        }

        // Get buffer from pool
        var outputBuffer: CVPixelBuffer?
        let status = CVPixelBufferPoolCreatePixelBuffer(
            kCFAllocatorDefault,
            outputBufferPool!,
            &outputBuffer
        )

        guard status == kCVReturnSuccess, let buffer = outputBuffer else {
            throw FilterError.pixelBufferCreationFailed
        }

        return buffer
    }

    /// Creates a new pixel buffer pool for efficient buffer reuse
    private func createPixelBufferPool(
        width: Int,
        height: Int,
        pixelFormat: OSType
    ) throws -> CVPixelBufferPool {
        let poolAttributes: [CFString: Any] = [
            kCVPixelBufferPoolMinimumBufferCountKey: 3  // Triple buffering
        ]

        let pixelBufferAttributes: [CFString: Any] = [
            kCVPixelBufferWidthKey: width,
            kCVPixelBufferHeightKey: height,
            kCVPixelBufferPixelFormatTypeKey: pixelFormat,
            kCVPixelBufferMetalCompatibilityKey: true,
            kCVPixelBufferIOSurfacePropertiesKey: [:]
        ]

        var pool: CVPixelBufferPool?
        let status = CVPixelBufferPoolCreate(
            kCFAllocatorDefault,
            poolAttributes as CFDictionary,
            pixelBufferAttributes as CFDictionary,
            &pool
        )

        guard status == kCVReturnSuccess, let bufferPool = pool else {
            throw FilterError.pixelBufferCreationFailed
        }

        return bufferPool
    }

    // MARK: - Cache Management

    /// Flushes texture cache and pixel buffer pool
    /// - Note: Call this when processing different sized frames or under memory pressure
    public func flush() {
        textureCache.flush()
        outputBufferPool = nil
        cachedOutputSize = .zero
    }

    // MARK: - Async API (Future Extension)

    /// Asynchronously processes a pixel buffer (non-blocking)
    /// - Note: Returns immediately; use completion handler for result
    public func processAsync(
        pixelBuffer: CVPixelBuffer,
        filter: MetalFilter,
        parameters: FilterParameters? = nil,
        completion: @escaping (Result<CVPixelBuffer, Error>) -> Void
    ) {
        Task {
            do {
                let result = try process(
                    pixelBuffer: pixelBuffer,
                    filter: filter,
                    parameters: parameters
                )
                await MainActor.run {
                    completion(.success(result))
                }
            } catch {
                await MainActor.run {
                    completion(.failure(error))
                }
            }
        }
    }
}

// MARK: - Debug & Performance Utilities

@available(iOS 16.0, macOS 13.0, *)
extension MetalFilterPipeline {
    /// Returns pipeline debug information
    public var debugInfo: String {
        """
        MetalFilterPipeline Debug Info:
        - Metal Device: \(context.deviceName)
        - Cached Output Size: \(cachedOutputSize)
        - Has Buffer Pool: \(outputBufferPool != nil)
        """
    }

    /// Measures processing time for a single frame
    /// - Returns: Processing time in milliseconds
    public func measurePerformance(
        pixelBuffer: CVPixelBuffer,
        filter: MetalFilter,
        iterations: Int = 10
    ) throws -> Double {
        var totalTime: CFAbsoluteTime = 0

        for _ in 0..<iterations {
            let start = CFAbsoluteTimeGetCurrent()
            _ = try process(pixelBuffer: pixelBuffer, filter: filter)
            let end = CFAbsoluteTimeGetCurrent()
            totalTime += (end - start)
        }

        return (totalTime / Double(iterations)) * 1000  // Convert to ms
    }
}
