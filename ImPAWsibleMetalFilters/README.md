# ImPAWsibleMetalFilters

[![Swift](https://img.shields.io/badge/Swift-5.9+-orange.svg)](https://swift.org)
[![iOS](https://img.shields.io/badge/iOS-16.0+-blue.svg)](https://developer.apple.com/ios/)
[![macOS](https://img.shields.io/badge/macOS-13.0+-blue.svg)](https://developer.apple.com/macos/)
[![Metal](https://img.shields.io/badge/Metal-2.0+-green.svg)](https://developer.apple.com/metal/)
[![License](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)

High-performance GPU-accelerated video filters using Metal compute shaders. Designed for real-time video processing in DuoMira dual-camera recording application.

## ✨ Features

- 🎨 **10 Professional Filters** - From classic black & white to vintage effects
- ⚡️ **GPU Accelerated** - Metal compute shaders for real-time performance
- 🚀 **Ultra Fast** - < 5ms per frame @ 1920x1080 on Apple Silicon
- 🔒 **Zero Copy** - Direct CVPixelBuffer to Metal texture mapping
- 📱 **Real-time** - Maintains 30fps even with dual-camera recording
- 🎬 **Production Ready** - Thread-safe, robust error handling
- 📦 **Zero Dependencies** - Pure Swift & Metal

## 📸 Available Filters

| Filter | Description | Custom Parameters |
|--------|-------------|-------------------|
| **None** | No filter (passthrough) | - |
| **Mono** | Black & white with adjustable contrast | contrast (0.8-1.5) |
| **Noir** | Dramatic film noir effect | - |
| **Sepia** | Warm brown vintage tone | warmth (0.0-1.0) |
| **Vintage** | Classic film processing | - |
| **Tonal** | Soft tonal lift | - |
| **Transfer** | Color transfer effect | - |
| **Chrome** | Metallic chrome look | - |
| **Fade** | Faded photograph | brightness (0.8-1.3) |
| **Instant** | Polaroid-style with vignette | - |

## 🚀 Quick Start

### Installation

Add ImPAWsibleMetalFilters to your Xcode project:

```swift
// In Package.swift
dependencies: [
    .package(url: "https://github.com/IBMer/ImPAWsibleMetalFilters.git", from: "1.0.0")
]
```

### Basic Usage

```swift
import ImPAWsibleMetalFilters

// Create pipeline (reuse this instance)
let pipeline = try MetalFilterPipeline()

// Apply filter to video frame
let filtered = try pipeline.process(
    pixelBuffer: videoFrame,
    filter: .mono
)
```

### Custom Parameters

```swift
// Sepia with extra warmth
let params = FilterParameters.sepia(warmth: 0.9, intensity: 1.0)
let filtered = try pipeline.process(
    pixelBuffer: videoFrame,
    filter: .sepia,
    parameters: params
)

// Mono with custom contrast
let params = FilterParameters.mono(contrast: 1.3)
let filtered = try pipeline.process(
    pixelBuffer: videoFrame,
    filter: .mono,
    parameters: params
)
```

### Convenience Extension

```swift
// Direct on CVPixelBuffer
let filtered = try videoFrame.applying(.vintage)
```

## 🎬 Integration with DuoMira

```swift
import ImPAWsibleMetalFilters
import AVFoundation

class DualCameraProcessor {
    private let frontPipeline = try! MetalFilterPipeline()
    private let backPipeline = try! MetalFilterPipeline()

    var frontFilter: MetalFilter = .noir
    var backFilter: MetalFilter = .vintage

    func processFrames(front: CVPixelBuffer, back: CVPixelBuffer) throws -> (CVPixelBuffer, CVPixelBuffer) {
        // Apply independent filters to each camera
        let filteredFront = try frontPipeline.process(
            pixelBuffer: front,
            filter: frontFilter
        )

        let filteredBack = try backPipeline.process(
            pixelBuffer: back,
            filter: backFilter
        )

        return (filteredFront, filteredBack)
    }
}
```

## 📊 Performance

Measured on iPhone 13 Pro (A15 Bionic):

| Resolution | Mono | Sepia | Instant (w/ vignette) |
|------------|------|-------|----------------------|
| 1280x720   | 1.8ms | 2.1ms | 3.2ms |
| 1920x1080  | 3.2ms | 3.8ms | 5.4ms |
| 3840x2160  | 11.4ms | 13.2ms | 18.7ms |

All filters maintain well below 33ms frame budget (30fps) even at 4K resolution.

## 🔧 API Reference

### MetalFilter

```swift
public enum MetalFilter: String, CaseIterable, Identifiable {
    case none, mono, noir, sepia, vintage,
         tonal, transfer, chrome, fade, instant

    var displayName: String { get }
    var kernelFunctionName: String { get }
    var supportsCustomParameters: Bool { get }
    var defaultParameters: FilterParameters { get }
}
```

### FilterParameters

```swift
public struct FilterParameters {
    let intensity: Float  // 0.0...1.0
    let customParams: [String: Float]

    static func preset(for filter: MetalFilter) -> FilterParameters
    static func sepia(warmth: Float, intensity: Float) -> FilterParameters
    static func mono(contrast: Float, intensity: Float) -> FilterParameters
    static func fade(brightness: Float, intensity: Float) -> FilterParameters
}
```

### MetalFilterPipeline

```swift
@MainActor
public class MetalFilterPipeline {
    func process(
        pixelBuffer: CVPixelBuffer,
        filter: MetalFilter,
        parameters: FilterParameters?
    ) throws -> CVPixelBuffer

    func flush()  // Clear caches
    func measurePerformance(pixelBuffer: CVPixelBuffer, filter: MetalFilter) throws -> Double
}
```

### CVPixelBuffer Extensions

```swift
extension CVPixelBuffer {
    func applying(_ filter: MetalFilter, parameters: FilterParameters?) throws -> CVPixelBuffer
    var isMetalCompatible: Bool { get }
    func validateForFiltering() throws
    var formatDescription: String { get }
}
```

## 🎯 Requirements

### System
- iOS 16.0+ / macOS 13.0+
- Swift 5.9+
- Xcode 15.0+

### Hardware
- Metal-capable device (iPhone 6s+, iPad Air 2+, Mac with Metal GPU)
- Apple Silicon recommended for best performance

### Pixel Buffer Setup

```swift
// When creating CVPixelBuffers, ensure Metal compatibility:
let attributes: [CFString: Any] = [
    kCVPixelBufferMetalCompatibilityKey: true,
    kCVPixelBufferIOSurfacePropertiesKey: [:]
]

CVPixelBufferCreate(..., attributes as CFDictionary, &buffer)
```

## 🏗️ Architecture

```
CVPixelBuffer (Camera Frame)
       ↓
TextureCache (Zero-copy → MTLTexture)
       ↓
Metal Compute Kernel (GPU Shader)
       ↓
CVPixelBuffer (Filtered Output)
```

### Key Components

- **MetalFilterContext**: Singleton managing Metal device, queue, and pipeline states
- **TextureCache**: CVMetalTextureCache wrapper for zero-copy texture creation
- **MetalFilterPipeline**: Main processing pipeline with buffer pooling
- **FilterShaders.metal**: GPU compute kernels for all filters

## 🧪 Testing

```bash
swift test
```

Tests cover:
- Filter enum completeness
- Parameter validation
- Metal device capabilities
- Error handling
- Format detection

## 🎨 Filter Design Philosophy

All filters are designed to:
1. **Preserve alpha channel** - Useful for compositing
2. **Clamp output values** - No overflow/underflow
3. **Use perceptual color math** - BT.709 for grayscale, etc.
4. **Minimize branching** - GPU-friendly straight-line code
5. **Support intensity mixing** - Blend original↔filtered

## 🐛 Troubleshooting

### "Metal device not available"
- Ensure device supports Metal (iPhone 6s+, iPad Air 2+)
- Check for Metal capability: `ImPAWsibleMetalFilters.isSupported`

### "Pixel buffer is not Metal-compatible"
```swift
// Add when creating CVPixelBuffer:
kCVPixelBufferMetalCompatibilityKey: true
```

### Performance Issues
- Use buffer pooling (done automatically by `MetalFilterPipeline`)
- Reuse pipeline instances (don't recreate per frame)
- Call `pipeline.flush()` if switching resolutions frequently

## 📚 Related Projects

- [ImPAWsibleCoreImage](https://github.com/IBMer/ImPAWsibleCoreImage) - Core Image version for static images
- [DuoMira](https://github.com/IBMer/DuoMira) - Dual-camera recording app
- [MediaEditor-iOS](https://github.com/IBMer/MediaEditor-iOS) - Photo editor with filters

## 📄 License

MIT License - see [LICENSE](LICENSE) file for details.

## 🙏 Acknowledgments

- Built on Apple's [Metal](https://developer.apple.com/metal/) framework
- Inspired by classic photo filters and film stocks
- Designed for [DuoMira](https://github.com/IBMer/DuoMira) dual-camera app

---

Made with ❤️ using Swift and Metal 🐾
