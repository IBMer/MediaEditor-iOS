import Foundation

/// 滤镜参数（简化版，仅支持强度调节）
///
/// 用于控制滤镜效果的强度，范围从 0.0（无效果）到 1.0（全效果）。
@available(iOS 17.0, macOS 13.0, *)
public struct FilterParameters: Sendable, Equatable {
    /// 强度（0.0 = 无效果，1.0 = 全效果）
    public let intensity: Float

    /// 创建滤镜参数
    /// - Parameter intensity: 强度值，自动限制在 0.0-1.0 范围内
    public init(intensity: Float = 1.0) {
        self.intensity = max(0.0, min(1.0, intensity))
    }

    /// 默认参数（全强度）
    public static let `default` = FilterParameters(intensity: 1.0)

    /// 验证强度范围
    public var isValid: Bool {
        return intensity >= 0.0 && intensity <= 1.0
    }
}
