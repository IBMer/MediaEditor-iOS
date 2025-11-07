import CoreVideo
import Foundation

/// CVPixelBuffer 扩展，提供便捷的滤镜应用方法
@available(iOS 17.0, macOS 13.0, *)
public extension CVPixelBuffer {
    /// 便捷方法：应用滤镜（异步）
    /// - Parameters:
    ///   - filter: 要应用的滤镜
    ///   - intensity: 滤镜强度（0.0-1.0）
    /// - Returns: 应用滤镜后的新 CVPixelBuffer
    /// - Throws: 处理失败时抛出 FilterError
    func applying(
        _ filter: MetalFilter,
        intensity: Float = 1.0
    ) async throws -> CVPixelBuffer {
        let pipeline = try await MetalCIFilterPipeline()
        let parameters = FilterParameters(intensity: intensity)
        return try await pipeline.process(
            pixelBuffer: self,
            filter: filter,
            parameters: parameters
        )
    }

    /// 便捷方法：应用滤镜（使用 FilterParameters）
    /// - Parameters:
    ///   - filter: 要应用的滤镜
    ///   - parameters: 滤镜参数
    /// - Returns: 应用滤镜后的新 CVPixelBuffer
    /// - Throws: 处理失败时抛出 FilterError
    func applying(
        _ filter: MetalFilter,
        parameters: FilterParameters
    ) async throws -> CVPixelBuffer {
        let pipeline = try await MetalCIFilterPipeline()
        return try await pipeline.process(
            pixelBuffer: self,
            filter: filter,
            parameters: parameters
        )
    }
}
