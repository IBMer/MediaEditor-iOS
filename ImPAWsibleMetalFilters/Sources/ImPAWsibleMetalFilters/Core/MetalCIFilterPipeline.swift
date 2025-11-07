import CoreImage
import CoreVideo
import Metal
import Foundation

/// Metal GPU 加速的 Core Image 滤镜处理管道
///
/// 使用 Apple 的内置 Core Image 滤镜，通过 Metal GPU 加速实现实时视频处理。
/// 性能目标：1920x1080 @ 30fps，单帧处理 < 12ms
///
/// 示例：
/// ```swift
/// let pipeline = try await MetalCIFilterPipeline()
/// let filtered = try await pipeline.process(
///     pixelBuffer: frame,
///     filter: .mono,
///     parameters: FilterParameters(intensity: 0.8)
/// )
/// ```
@available(iOS 17.0, macOS 13.0, *)
@MainActor
public final class MetalCIFilterPipeline {
    // MARK: - Properties

    private let context: MetalCIContext

    // MARK: - Initialization

    /// 创建滤镜处理管道
    /// - Throws: 如果 Metal 不可用则抛出错误
    public init() async throws {
        self.context = await MetalCIContext.shared
    }

    // MARK: - Main Processing Method

    /// 处理单个 CVPixelBuffer（主方法）
    /// - Parameters:
    ///   - pixelBuffer: 输入视频帧
    ///   - filter: 要应用的滤镜
    ///   - parameters: 滤镜参数（默认为全强度）
    /// - Returns: 处理后的 CVPixelBuffer
    /// - Throws: 处理失败时抛出 FilterError
    public func process(
        pixelBuffer: CVPixelBuffer,
        filter: MetalFilter,
        parameters: FilterParameters = .default
    ) async throws -> CVPixelBuffer {
        // 无滤镜直接返回
        guard filter != .none else {
            return pixelBuffer
        }

        // 验证参数
        guard parameters.isValid else {
            throw FilterError.invalidIntensity(Double(parameters.intensity))
        }

        // 1. CVPixelBuffer → CIImage（零拷贝）
        var ciImage = CIImage(cvPixelBuffer: pixelBuffer)

        // 2. 应用 Apple 的 Core Image 滤镜
        ciImage = try await applyFilter(filter, to: ciImage, parameters: parameters)

        // 3. 创建输出 CVPixelBuffer
        let outputBuffer = try createOutputBuffer(matching: pixelBuffer)

        // 4. GPU 渲染到输出 buffer
        try await context.render(ciImage, to: outputBuffer)

        return outputBuffer
    }

    // MARK: - Private Methods

    /// 应用 Core Image 滤镜
    private func applyFilter(
        _ filter: MetalFilter,
        to image: CIImage,
        parameters: FilterParameters
    ) async throws -> CIImage {
        guard let filterName = filter.ciFilterName else {
            return image
        }

        // 创建 Core Image 滤镜
        guard let ciFilter = CIFilter(name: filterName) else {
            throw FilterError.filterNotAvailable(filterName)
        }

        // 设置输入图像
        ciFilter.setValue(image, forKey: kCIInputImageKey)

        // 设置强度参数（仅 CISepiaTone 原生支持）
        if filter.supportsIntensity {
            ciFilter.setValue(parameters.intensity, forKey: kCIInputIntensityKey)
        }

        // 获取输出图像
        guard let outputImage = ciFilter.outputImage else {
            throw FilterError.filterProcessingFailed(filterName)
        }

        // 对于不支持强度的滤镜，使用 CIColorMatrix 模拟强度调节
        if !filter.supportsIntensity && parameters.intensity < 1.0 {
            return try applyIntensityBlending(
                original: image,
                filtered: outputImage,
                intensity: parameters.intensity
            )
        }

        return outputImage
    }

    /// 使用 CIColorMatrix 模拟强度调节（混合原图和滤镜效果）
    private func applyIntensityBlending(
        original: CIImage,
        filtered: CIImage,
        intensity: Float
    ) throws -> CIImage {
        // 使用 CIBlendWithMask 或简单的线性插值
        // 这里使用 CIColorMatrix 实现线性混合
        let blendedImage = filtered.applyingFilter("CIColorMatrix", parameters: [
            "inputRVector": CIVector(x: CGFloat(intensity), y: 0, z: 0, w: 0),
            "inputGVector": CIVector(x: 0, y: CGFloat(intensity), z: 0, w: 0),
            "inputBVector": CIVector(x: 0, y: 0, z: CGFloat(intensity), w: 0),
            "inputAVector": CIVector(x: 0, y: 0, z: 0, w: 1),
            "inputBiasVector": CIVector(
                x: CGFloat(1.0 - intensity) * 0.5,
                y: CGFloat(1.0 - intensity) * 0.5,
                z: CGFloat(1.0 - intensity) * 0.5,
                w: 0
            )
        ])

        // 与原图混合
        return blendedImage.composited(over: original.cropped(to: blendedImage.extent))
    }

    /// 创建输出 CVPixelBuffer（匹配输入格式）
    private func createOutputBuffer(matching inputBuffer: CVPixelBuffer) throws -> CVPixelBuffer {
        let width = CVPixelBufferGetWidth(inputBuffer)
        let height = CVPixelBufferGetHeight(inputBuffer)
        let pixelFormat = CVPixelBufferGetPixelFormatType(inputBuffer)

        var outputBuffer: CVPixelBuffer?
        let status = CVPixelBufferCreate(
            kCFAllocatorDefault,
            width,
            height,
            pixelFormat,
            [
                kCVPixelBufferMetalCompatibilityKey: true,
                kCVPixelBufferIOSurfacePropertiesKey: [:],
                kCVPixelBufferCGImageCompatibilityKey: true,
                kCVPixelBufferCGBitmapContextCompatibilityKey: true
            ] as CFDictionary,
            &outputBuffer
        )

        guard status == kCVReturnSuccess, let buffer = outputBuffer else {
            throw FilterError.pixelBufferCreationFailed
        }

        return buffer
    }

    // MARK: - Performance Utilities

    /// 测量滤镜处理性能
    /// - Parameters:
    ///   - pixelBuffer: 测试用的像素缓冲区
    ///   - filter: 要测试的滤镜
    ///   - iterations: 迭代次数
    /// - Returns: 平均处理时间（毫秒）
    public func measurePerformance(
        pixelBuffer: CVPixelBuffer,
        filter: MetalFilter,
        iterations: Int = 10
    ) async throws -> Double {
        var totalTime: CFAbsoluteTime = 0

        for _ in 0..<iterations {
            let start = CFAbsoluteTimeGetCurrent()
            _ = try await process(pixelBuffer: pixelBuffer, filter: filter)
            let end = CFAbsoluteTimeGetCurrent()
            totalTime += (end - start)
        }

        return (totalTime / Double(iterations)) * 1000  // 转换为毫秒
    }
}
