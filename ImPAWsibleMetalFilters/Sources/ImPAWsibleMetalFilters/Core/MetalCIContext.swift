import CoreImage
import Metal
import Foundation

/// Metal-backed Core Image 上下文管理器（单例 Actor）
///
/// 管理 Metal 设备和 GPU 加速的 Core Image 上下文，用于高性能视频滤镜处理。
///
/// 关键优化：
/// - 使用 Metal GPU 强制渲染（避免 CPU fallback）
/// - 禁用中间结果缓存（视频流每帧都不同）
/// - 零拷贝 CVPixelBuffer 处理
@available(iOS 17.0, macOS 13.0, *)
public actor MetalCIContext {
    // MARK: - Singleton

    /// 共享单例实例
    public static let shared = MetalCIContext()

    // MARK: - Properties

    /// Metal 设备
    public let device: MTLDevice

    /// Core Image 上下文（Metal-backed）
    public let ciContext: CIContext

    /// Metal 命令队列
    public let commandQueue: MTLCommandQueue

    // MARK: - Initialization

    private init() {
        guard let device = MTLCreateSystemDefaultDevice() else {
            fatalError("Metal is not supported on this device")
        }
        self.device = device

        guard let queue = device.makeCommandQueue() else {
            fatalError("Failed to create Metal command queue")
        }
        self.commandQueue = queue

        // 关键：创建 Metal-backed CIContext
        self.ciContext = CIContext(
            mtlDevice: device,
            options: [
                // 使用设备 RGB 色彩空间（与相机一致）
                .workingColorSpace: CGColorSpaceCreateDeviceRGB(),

                // 禁用中间结果缓存（视频流每帧都不同）
                .cacheIntermediates: false,

                // 强制使用 GPU 渲染（禁用软件后备）
                .useSoftwareRenderer: false,

                // 高质量下采样
                .highQualityDownsample: true
            ]
        )

        print("✅ Metal-backed CIContext initialized (GPU: \(device.name))")
    }

    // MARK: - Public Methods

    /// 渲染 CIImage 到 CVPixelBuffer（GPU 加速）
    /// - Parameters:
    ///   - image: 输入 CIImage
    ///   - pixelBuffer: 输出 CVPixelBuffer
    /// - Throws: 渲染失败时抛出错误
    public func render(
        _ image: CIImage,
        to pixelBuffer: CVPixelBuffer
    ) throws {
        ciContext.render(
            image,
            to: pixelBuffer,
            bounds: image.extent,
            colorSpace: CGColorSpaceCreateDeviceRGB()
        )
    }

    /// 检查设备是否支持 Metal
    public var isMetalSupported: Bool {
        return MTLCreateSystemDefaultDevice() != nil
    }

    /// 设备名称（用于调试）
    public var deviceName: String {
        return device.name
    }
}
