import Foundation

/// 滤镜枚举（与 ImPAWsibleCoreImage 保持一致）
///
/// 使用 Metal-backed Core Image 实现，确保效果与静态图片滤镜完全一致。
@available(iOS 17.0, macOS 13.0, *)
public enum MetalFilter: String, CaseIterable, Identifiable, Sendable {
    case none       // 无滤镜
    case mono       // 黑白（单色）
    case noir       // 黑白胶片
    case sepia      // 褐色
    case vintage    // 怀旧
    case tonal      // 色调
    case transfer   // 色彩转移
    case chrome     // 金属质感
    case fade       // 褪色
    case instant    // 即时相机

    public var id: String { rawValue }

    /// 用户显示名称（支持本地化）
    public var displayName: String {
        switch self {
        case .none: return NSLocalizedString("Original", comment: "Filter name")
        case .mono: return NSLocalizedString("Mono", comment: "Filter name")
        case .noir: return NSLocalizedString("Noir", comment: "Filter name")
        case .sepia: return NSLocalizedString("Sepia", comment: "Filter name")
        case .vintage: return NSLocalizedString("Vintage", comment: "Filter name")
        case .tonal: return NSLocalizedString("Tonal", comment: "Filter name")
        case .transfer: return NSLocalizedString("Transfer", comment: "Filter name")
        case .chrome: return NSLocalizedString("Chrome", comment: "Filter name")
        case .fade: return NSLocalizedString("Fade", comment: "Filter name")
        case .instant: return NSLocalizedString("Instant", comment: "Filter name")
        }
    }

    /// Core Image 滤镜名称（Apple 内置滤镜）
    public var ciFilterName: String? {
        switch self {
        case .none: return nil
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

    /// 是否支持强度调节
    /// - Note: 只有 CISepiaTone 原生支持 intensity 参数
    public var supportsIntensity: Bool {
        switch self {
        case .sepia: return true  // CISepiaTone 支持 intensity
        default: return false     // 其他 CIPhotoEffect* 不支持
        }
    }

    /// 滤镜描述
    public var description: String {
        switch self {
        case .none: return NSLocalizedString("No filter applied", comment: "Filter description")
        case .mono: return NSLocalizedString("Black and white with high contrast", comment: "Filter description")
        case .noir: return NSLocalizedString("Dramatic black and white film effect", comment: "Filter description")
        case .sepia: return NSLocalizedString("Warm brown tone", comment: "Filter description")
        case .vintage: return NSLocalizedString("Classic film processing", comment: "Filter description")
        case .tonal: return NSLocalizedString("Soft tonal color effect", comment: "Filter description")
        case .transfer: return NSLocalizedString("Color transfer effect", comment: "Filter description")
        case .chrome: return NSLocalizedString("Metallic chrome effect", comment: "Filter description")
        case .fade: return NSLocalizedString("Faded vintage photograph", comment: "Filter description")
        case .instant: return NSLocalizedString("Instant camera style", comment: "Filter description")
        }
    }
}
