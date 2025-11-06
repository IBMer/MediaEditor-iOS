# DuoMira 滤镜功能实施计划

## 项目概述

为 DuoMira 双摄像头应用添加实时滤镜功能，通过创建全新的 GPU Metal 加速滤镜框架 `ImPAWsibleMetalFilters`，实现前后摄像头独立的滤镜处理，同时保持 30fps 流畅录制性能。

---

## 设计决策总结

| 决策点 | 选择方案 | 理由 |
|--------|---------|------|
| **滤镜技术栈** | 全新 Metal 框架 | Core Image CPU 处理不适合实时视频，Metal GPU 加速是最优解 |
| **滤镜种类** | 复用 ImPAWsibleCoreImage 的 10 种滤镜 | 保持产品线一致性，用户熟悉度 |
| **参数设计** | 分层设计（预设 + 高级可选） | 普通用户一键应用，专业用户精细调节 |
| **链式滤镜** | 不支持（每次单滤镜） | 简化设计，避免性能开销，满足大多数场景 |
| **集成方式** | 独立滤镜管道（合成前应用） | 架构清晰，责任分离，易于测试和维护 |
| **应用时机** | 实时预览 + 录制应用 | 即时反馈，所见即所得 |
| **摄像头配置** | 前后摄像头独立滤镜选择 | 创意灵活性（如主画面怀旧 + PiP 黑白） |

---

## Phase 1: 创建 ImPAWsibleMetalFilters Package

### 1.1 项目结构

```
ImPAWsibleMetalFilters/
├── Package.swift
├── README.md
├── LICENSE
├── Sources/
│   ├── ImPAWsibleMetalFilters/
│   │   ├── ImPAWsibleMetalFilters.swift          // 模块入口
│   │   ├── Core/
│   │   │   ├── MetalFilterContext.swift          // Metal 设备/队列管理（单例）
│   │   │   ├── MetalFilterPipeline.swift         // 主处理管道
│   │   │   ├── TextureCache.swift                // CVPixelBuffer ↔ MTLTexture 缓存
│   │   │   └── FilterParameters.swift            // 滤镜参数抽象
│   │   ├── Filters/
│   │   │   ├── MetalFilter.swift                 // 滤镜枚举 + 协议
│   │   │   ├── FilterDefinitions.swift           // 10 种滤镜的参数预设
│   │   │   └── FilterError.swift                 // 错误类型
│   │   ├── Shaders/
│   │   │   ├── FilterShaders.metal               // 所有滤镜的 kernel 函数
│   │   │   └── ColorConversion.metal             // 辅助颜色空间函数
│   │   └── Extensions/
│   │       └── CVPixelBuffer+Metal.swift         // 便捷方法
│   └── ImPAWsibleMetalFiltersUI/                  // SwiftUI 组件（可选模块）
│       ├── ImPAWsibleMetalFiltersUI.swift
│       └── Views/
│           ├── FilterPickerView.swift            // 滤镜选择器（横向滚动）
│           └── FilterParameterEditor.swift       // 参数调节界面
└── Tests/
    └── ImPAWsibleMetalFiltersTests/
        ├── MetalFilterTests.swift                // 滤镜正确性测试
        ├── PerformanceTests.swift                // 性能基准测试
        └── TextureCacheTests.swift               // 内存管理测试
```

---

### 1.2 核心技术实现

#### A. MetalFilter 枚举定义

**文件**: `Sources/ImPAWsibleMetalFilters/Filters/MetalFilter.swift`

```swift
public enum MetalFilter: String, CaseIterable, Identifiable, Sendable {
    case none       // 无滤镜
    case mono       // 黑白（单色）
    case noir       // 黑白胶片
    case sepia      // 褐色（可调暖度）
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
        case .none: return NSLocalizedString("Original", comment: "")
        case .mono: return NSLocalizedString("Mono", comment: "")
        case .noir: return NSLocalizedString("Noir", comment: "")
        case .sepia: return NSLocalizedString("Sepia", comment: "")
        case .vintage: return NSLocalizedString("Vintage", comment: "")
        case .tonal: return NSLocalizedString("Tonal", comment: "")
        case .transfer: return NSLocalizedString("Transfer", comment: "")
        case .chrome: return NSLocalizedString("Chrome", comment: "")
        case .fade: return NSLocalizedString("Fade", comment: "")
        case .instant: return NSLocalizedString("Instant", comment: "")
        }
    }

    /// Metal 函数名
    public var kernelFunctionName: String {
        switch self {
        case .none: return ""  // 不需要处理
        case .mono: return "monoFilter"
        case .noir: return "noirFilter"
        case .sepia: return "sepiaFilter"
        case .vintage: return "vintageFilter"
        case .tonal: return "tonalFilter"
        case .transfer: return "transferFilter"
        case .chrome: return "chromeFilter"
        case .fade: return "fadeFilter"
        case .instant: return "instantFilter"
        }
    }

    /// 是否支持自定义参数
    public var supportsCustomParameters: Bool {
        switch self {
        case .sepia, .mono, .fade: return true
        default: return false
        }
    }

    /// 默认参数预设
    public var defaultParameters: FilterParameters {
        FilterParameters.preset(for: self)
    }
}
```

---

#### B. 滤镜参数系统

**文件**: `Sources/ImPAWsibleMetalFilters/Core/FilterParameters.swift`

```swift
/// 滤镜参数容器（支持预设 + 自定义）
public struct FilterParameters: Sendable {
    /// 通用强度（所有滤镜都支持，0.0 = 无效果，1.0 = 全效果）
    public let intensity: Float

    /// 滤镜特定参数（可选）
    public let customParams: [String: Float]

    public init(intensity: Float = 1.0, customParams: [String: Float] = [:]) {
        self.intensity = max(0.0, min(1.0, intensity))
        self.customParams = customParams
    }

    /// 预设参数（各滤镜推荐值）
    public static func preset(for filter: MetalFilter) -> FilterParameters {
        switch filter {
        case .none:
            return FilterParameters(intensity: 0.0)
        case .mono:
            return FilterParameters(intensity: 1.0, customParams: ["contrast": 1.1])
        case .sepia:
            return FilterParameters(intensity: 1.0, customParams: ["warmth": 0.7])
        case .fade:
            return FilterParameters(intensity: 0.8, customParams: ["brightness": 1.1])
        default:
            return FilterParameters(intensity: 1.0)
        }
    }

    /// 自定义 Sepia 参数
    public static func sepia(warmth: Float = 0.7, intensity: Float = 1.0) -> FilterParameters {
        FilterParameters(intensity: intensity, customParams: ["warmth": warmth])
    }

    /// 自定义 Mono 参数
    public static func mono(contrast: Float = 1.1, intensity: Float = 1.0) -> FilterParameters {
        FilterParameters(intensity: intensity, customParams: ["contrast": contrast])
    }

    /// 自定义 Fade 参数
    public static func fade(brightness: Float = 1.1, intensity: Float = 0.8) -> FilterParameters {
        FilterParameters(intensity: intensity, customParams: ["brightness": brightness])
    }
}
```

---

#### C. Metal 滤镜管道

**文件**: `Sources/ImPAWsibleMetalFilters/Core/MetalFilterPipeline.swift`

```swift
import Metal
import CoreVideo
import AVFoundation

/// 主滤镜处理管道（线程安全）
@MainActor
public class MetalFilterPipeline {

    private let context: MetalFilterContext
    private let textureCache: TextureCache

    public init() throws {
        self.context = try MetalFilterContext.shared
        self.textureCache = try TextureCache(device: context.device)
    }

    /// 处理单个 CVPixelBuffer（主方法）
    public func process(
        pixelBuffer: CVPixelBuffer,
        filter: MetalFilter,
        parameters: FilterParameters? = nil
    ) throws -> CVPixelBuffer {

        // 无滤镜直接返回
        guard filter != .none else {
            return pixelBuffer
        }

        // 1. 获取输入/输出纹理（零拷贝）
        let inputTexture = try textureCache.makeTexture(from: pixelBuffer, usage: .read)
        let outputBuffer = try createOutputBuffer(matching: pixelBuffer)
        let outputTexture = try textureCache.makeTexture(from: outputBuffer, usage: .write)

        // 2. 创建命令缓冲区
        guard let commandBuffer = context.commandQueue.makeCommandBuffer(),
              let encoder = commandBuffer.makeComputeCommandEncoder() else {
            throw FilterError.metalCommandCreationFailed
        }

        // 3. 设置计算管道
        let pipelineState = try context.pipelineState(for: filter)
        encoder.setComputePipelineState(pipelineState)

        // 4. 绑定纹理和参数
        encoder.setTexture(inputTexture, index: 0)
        encoder.setTexture(outputTexture, index: 1)

        let params = parameters ?? filter.defaultParameters
        var intensity = params.intensity
        encoder.setBytes(&intensity, length: MemoryLayout<Float>.size, index: 0)

        // 绑定自定义参数（如果有）
        if filter.supportsCustomParameters {
            try bindCustomParameters(params.customParams, to: encoder, for: filter)
        }

        // 5. 计算线程组大小
        let threadgroupSize = MTLSize(width: 16, height: 16, depth: 1)
        let threadgroups = MTLSize(
            width: (inputTexture.width + 15) / 16,
            height: (inputTexture.height + 15) / 16,
            depth: 1
        )

        // 6. 执行计算
        encoder.dispatchThreadgroups(threadgroups, threadsPerThreadgroup: threadgroupSize)
        encoder.endEncoding()

        // 7. 提交并等待完成（同步执行）
        commandBuffer.commit()
        commandBuffer.waitUntilCompleted()

        return outputBuffer
    }

    // MARK: - Private Helpers

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
                kCVPixelBufferIOSurfacePropertiesKey: [:]
            ] as CFDictionary,
            &outputBuffer
        )

        guard status == kCVReturnSuccess, let buffer = outputBuffer else {
            throw FilterError.pixelBufferCreationFailed
        }

        return buffer
    }

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
}
```

---

#### D. Metal 着色器实现

**文件**: `Sources/ImPAWsibleMetalFilters/Shaders/FilterShaders.metal`

```metal
#include <metal_stdlib>
using namespace metal;

// ============================================================
// 1. Mono Filter（黑白单色，可调对比度）
// ============================================================
kernel void monoFilter(
    texture2d<float, access::read> inTexture [[texture(0)]],
    texture2d<float, access::write> outTexture [[texture(1)]],
    constant float &intensity [[buffer(0)]],
    constant float &contrast [[buffer(1)]],
    uint2 gid [[thread_position_in_grid]]
) {
    if (gid.x >= outTexture.get_width() || gid.y >= outTexture.get_height()) {
        return;
    }

    float4 color = inTexture.read(gid);

    // ITU-R BT.709 亮度公式
    float gray = dot(color.rgb, float3(0.2126, 0.7152, 0.0722));

    // 应用对比度
    gray = (gray - 0.5) * contrast + 0.5;
    gray = clamp(gray, 0.0, 1.0);

    float3 monoColor = float3(gray);
    float3 finalColor = mix(color.rgb, monoColor, intensity);

    outTexture.write(float4(finalColor, color.a), gid);
}

// ============================================================
// 2. Noir Filter（戏剧性黑白胶片）
// ============================================================
kernel void noirFilter(
    texture2d<float, access::read> inTexture [[texture(0)]],
    texture2d<float, access::write> outTexture [[texture(1)]],
    constant float &intensity [[buffer(0)]],
    uint2 gid [[thread_position_in_grid]]
) {
    if (gid.x >= outTexture.get_width() || gid.y >= outTexture.get_height()) {
        return;
    }

    float4 color = inTexture.read(gid);

    // 高对比度黑白（压暗阴影，提亮高光）
    float gray = dot(color.rgb, float3(0.2126, 0.7152, 0.0722));

    // S 曲线对比度增强
    float enhanced = gray < 0.5
        ? 2.0 * gray * gray
        : 1.0 - 2.0 * (1.0 - gray) * (1.0 - gray);

    float3 noirColor = float3(enhanced);
    float3 finalColor = mix(color.rgb, noirColor, intensity);

    outTexture.write(float4(finalColor, color.a), gid);
}

// ============================================================
// 3. Sepia Filter（褐色，可调暖度）
// ============================================================
kernel void sepiaFilter(
    texture2d<float, access::read> inTexture [[texture(0)]],
    texture2d<float, access::write> outTexture [[texture(1)]],
    constant float &intensity [[buffer(0)]],
    constant float &warmth [[buffer(1)]],
    uint2 gid [[thread_position_in_grid]]
) {
    if (gid.x >= outTexture.get_width() || gid.y >= outTexture.get_height()) {
        return;
    }

    float4 color = inTexture.read(gid);

    // Sepia 矩阵（根据 warmth 动态调整）
    float3x3 sepiaMatrix = float3x3(
        0.393 + warmth * 0.1, 0.769, 0.189,
        0.349, 0.686 + warmth * 0.1, 0.168,
        0.272, 0.534, 0.131 + warmth * 0.2
    );

    float3 sepiaColor = sepiaMatrix * color.rgb;
    sepiaColor = clamp(sepiaColor, 0.0, 1.0);

    float3 finalColor = mix(color.rgb, sepiaColor, intensity);

    outTexture.write(float4(finalColor, color.a), gid);
}

// ============================================================
// 4. Vintage Filter（怀旧胶片）
// ============================================================
kernel void vintageFilter(
    texture2d<float, access::read> inTexture [[texture(0)]],
    texture2d<float, access::write> outTexture [[texture(1)]],
    constant float &intensity [[buffer(0)]],
    uint2 gid [[thread_position_in_grid]]
) {
    if (gid.x >= outTexture.get_width() || gid.y >= outTexture.get_height()) {
        return;
    }

    float4 color = inTexture.read(gid);

    // 怀旧色调：降低饱和度，增加黄-红色调
    float3 vintage = color.rgb;

    // 1. 降低饱和度
    float gray = dot(vintage, float3(0.299, 0.587, 0.114));
    vintage = mix(vintage, float3(gray), 0.3);

    // 2. 增加暖色调（黄-红）
    vintage.r = min(vintage.r * 1.1, 1.0);
    vintage.g = min(vintage.g * 1.05, 1.0);
    vintage.b = vintage.b * 0.9;

    // 3. 轻微褪色（降低对比度）
    vintage = (vintage - 0.5) * 0.85 + 0.5;

    float3 finalColor = mix(color.rgb, vintage, intensity);

    outTexture.write(float4(finalColor, color.a), gid);
}

// ============================================================
// 5. Tonal Filter（柔和色调）
// ============================================================
kernel void tonalFilter(
    texture2d<float, access::read> inTexture [[texture(0)]],
    texture2d<float, access::write> outTexture [[texture(1)]],
    constant float &intensity [[buffer(0)]],
    uint2 gid [[thread_position_in_grid]]
) {
    if (gid.x >= outTexture.get_width() || gid.y >= outTexture.get_height()) {
        return;
    }

    float4 color = inTexture.read(gid);

    // 柔和色调：轻微去饱和 + 提亮中间调
    float gray = dot(color.rgb, float3(0.299, 0.587, 0.114));
    float3 tonal = mix(color.rgb, float3(gray), 0.2);

    // 提亮中间调
    tonal = pow(tonal, float3(0.9));

    float3 finalColor = mix(color.rgb, tonal, intensity);

    outTexture.write(float4(finalColor, color.a), gid);
}

// ============================================================
// 6. Transfer Filter（色彩转移效果）
// ============================================================
kernel void transferFilter(
    texture2d<float, access::read> inTexture [[texture(0)]],
    texture2d<float, access::write> outTexture [[texture(1)]],
    constant float &intensity [[buffer(0)]],
    uint2 gid [[thread_position_in_grid]]
) {
    if (gid.x >= outTexture.get_width() || gid.y >= outTexture.get_height()) {
        return;
    }

    float4 color = inTexture.read(gid);

    // 色彩转移：增强绿色和青色
    float3 transfer = color.rgb;
    transfer.g = min(transfer.g * 1.15, 1.0);
    transfer.b = min(transfer.b * 1.1, 1.0);
    transfer.r = transfer.r * 0.95;

    float3 finalColor = mix(color.rgb, transfer, intensity);

    outTexture.write(float4(finalColor, color.a), gid);
}

// ============================================================
// 7. Chrome Filter（金属质感）
// ============================================================
kernel void chromeFilter(
    texture2d<float, access::read> inTexture [[texture(0)]],
    texture2d<float, access::write> outTexture [[texture(1)]],
    constant float &intensity [[buffer(0)]],
    uint2 gid [[thread_position_in_grid]]
) {
    if (gid.x >= outTexture.get_width() || gid.y >= outTexture.get_height()) {
        return;
    }

    float4 color = inTexture.read(gid);

    // 金属质感：高对比度 + 去饱和 + 锐化边缘
    float gray = dot(color.rgb, float3(0.299, 0.587, 0.114));
    float3 chrome = mix(color.rgb, float3(gray), 0.5);

    // 增强对比度（S 曲线）
    chrome = chrome < 0.5
        ? 2.0 * chrome * chrome
        : 1.0 - 2.0 * (1.0 - chrome) * (1.0 - chrome);

    float3 finalColor = mix(color.rgb, chrome, intensity);

    outTexture.write(float4(finalColor, color.a), gid);
}

// ============================================================
// 8. Fade Filter（褪色照片，可调亮度）
// ============================================================
kernel void fadeFilter(
    texture2d<float, access::read> inTexture [[texture(0)]],
    texture2d<float, access::write> outTexture [[texture(1)]],
    constant float &intensity [[buffer(0)]],
    constant float &brightness [[buffer(1)]],
    uint2 gid [[thread_position_in_grid]]
) {
    if (gid.x >= outTexture.get_width() || gid.y >= outTexture.get_height()) {
        return;
    }

    float4 color = inTexture.read(gid);

    // 褪色效果：降低对比度 + 轻微泛黄 + 提亮
    float3 faded = color.rgb;

    // 1. 降低对比度
    faded = (faded - 0.5) * 0.7 + 0.5;

    // 2. 轻微泛黄
    faded.r = min(faded.r * 1.05, 1.0);
    faded.g = min(faded.g * 1.03, 1.0);

    // 3. 应用亮度调整
    faded = faded * brightness;
    faded = clamp(faded, 0.0, 1.0);

    float3 finalColor = mix(color.rgb, faded, intensity);

    outTexture.write(float4(finalColor, color.a), gid);
}

// ============================================================
// 9. Instant Filter（即时相机风格）
// ============================================================
kernel void instantFilter(
    texture2d<float, access::read> inTexture [[texture(0)]],
    texture2d<float, access::write> outTexture [[texture(1)]],
    constant float &intensity [[buffer(0)]],
    uint2 gid [[thread_position_in_grid]]
) {
    if (gid.x >= outTexture.get_width() || gid.y >= outTexture.get_height()) {
        return;
    }

    float4 color = inTexture.read(gid);

    // 即时相机：高饱和度 + 轻微偏蓝绿 + 暗角
    float3 instant = color.rgb;

    // 1. 增加饱和度
    float gray = dot(instant, float3(0.299, 0.587, 0.114));
    instant = mix(float3(gray), instant, 1.3);

    // 2. 偏蓝绿色调
    instant.g = min(instant.g * 1.08, 1.0);
    instant.b = min(instant.b * 1.12, 1.0);

    // 3. 轻微暗角（边缘变暗）
    float2 uv = float2(gid) / float2(outTexture.get_width(), outTexture.get_height());
    float2 center = uv - 0.5;
    float vignette = 1.0 - dot(center, center) * 0.5;
    instant = instant * vignette;

    instant = clamp(instant, 0.0, 1.0);

    float3 finalColor = mix(color.rgb, instant, intensity);

    outTexture.write(float4(finalColor, color.a), gid);
}
```

---

### 1.3 性能优化要点

1. **纹理缓存复用**
   - `TextureCache` 使用 `CVMetalTextureCache` 避免重复创建
   - 零拷贝绑定：`CVPixelBuffer` 直接映射到 Metal 纹理

2. **命令缓冲区批处理**
   - 支持批量处理多个滤镜操作（未来扩展）

3. **线程组优化**
   - 使用 16x16 线程组（GPU warp 友好大小）
   - 根据纹理尺寸动态计算 threadgroup 数量

4. **Metal 函数缓存**
   - `MetalFilterContext` 缓存所有 `MTLComputePipelineState`
   - 避免重复编译着色器

5. **同步 vs 异步**
   - 默认同步执行（`waitUntilCompleted`）
   - 未来可添加异步接口（返回 `Task` 或 `async`）

---

### 1.4 测试计划

#### A. 正确性测试
- 每个滤镜的输出与参考图像对比（PSNR/SSIM 指标）
- 参数边界测试（intensity 0.0, 0.5, 1.0）
- 无滤镜直通测试（.none 应原样返回）

#### B. 性能基准测试
```swift
// 目标：1920x1080 @ 30fps
// 每帧预算：~33ms
// 滤镜处理目标：< 5ms/帧（单滤镜）

func testPerformance_1080p_MonoFilter() {
    let buffer = createTestBuffer(width: 1920, height: 1080)

    measure {
        _ = try! pipeline.process(pixelBuffer: buffer, filter: .mono)
    }
    // 期望：< 5ms per iteration
}
```

#### C. 内存泄漏测试
- 连续处理 1000 帧，监控内存稳定性
- 纹理缓存自动清理验证

---

## Phase 2: 集成到 DuoMira

