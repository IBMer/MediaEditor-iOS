# ImPAWsibleCoreImage

[![Swift](https://img.shields.io/badge/Swift-5.9+-orange.svg)](https://swift.org)
[![iOS](https://img.shields.io/badge/iOS-16.0+-blue.svg)](https://developer.apple.com/ios/)
[![macOS](https://img.shields.io/badge/macOS-13.0+-blue.svg)](https://developer.apple.com/macos/)
[![License](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)

A modern, Swift-first library for applying professional photo filters to images and videos. Built on top of Apple's Core Image framework with full SwiftUI support and Swift Concurrency (async/await).

## ✨ Features

- 🎨 **10 Professional Filters** - From classic black & white to vintage effects
- ⚡️ **Modern Swift** - Async/await API with Swift Concurrency
- 🎭 **SwiftUI Ready** - Ready-to-use SwiftUI components
- 🚀 **High Performance** - Optimized with shared Core Image context
- 🔒 **Thread Safe** - Actor-based architecture for safe concurrent processing
- 📦 **Zero Dependencies** - Pure Swift & Core Image
- 🧪 **Fully Tested** - Comprehensive unit test coverage
- 📱 **Cross-Platform** - iOS and macOS support

## 📸 Available Filters

| Filter | Description | Core Image Filter |
|--------|-------------|-------------------|
| **None** | Original image | - |
| **Mono** | Black and white with high contrast | CIPhotoEffectMono |
| **Noir** | Dramatic black and white film effect | CIPhotoEffectNoir |
| **Sepia** | Warm brown tone (supports intensity) | CISepiaTone |
| **Vintage** | Classic film processing look | CIPhotoEffectProcess |
| **Tonal** | Soft tonal color effect | CIPhotoEffectTonal |
| **Transfer** | Color transfer effect | CIPhotoEffectTransfer |
| **Chrome** | Metallic chrome effect | CIPhotoEffectChrome |
| **Fade** | Faded vintage photograph look | CIPhotoEffectFade |
| **Instant** | Instant camera photograph style | CIPhotoEffectInstant |

## 📦 Installation

### Swift Package Manager

Add ImPAWsibleCoreImage to your project via Xcode:

1. File → Add Package Dependencies...
2. Enter: `https://github.com/IBMer/ImPAWsibleCoreImage.git`
3. Select the modules you need:
   - `ImPAWsibleCoreImage` - Core filter processing
   - `ImPAWsibleCoreImageUI` - SwiftUI components (optional)

Or add to your `Package.swift`:

```swift
dependencies: [
    .package(url: "https://github.com/IBMer/ImPAWsibleCoreImage.git", from: "1.0.0")
],
targets: [
    .target(
        name: "YourTarget",
        dependencies: [
            .product(name: "ImPAWsibleCoreImage", package: "ImPAWsibleCoreImage"),
            .product(name: "ImPAWsibleCoreImageUI", package: "ImPAWsibleCoreImage"), // Optional
        ]
    )
]
```

## 🚀 Quick Start

### Basic Usage

```swift
import ImPAWsibleCoreImage

// Apply a filter to an image
let filteredImage = try await myImage.applying(.mono)

// Apply filter with intensity (for supported filters like Sepia)
let sepiaImage = try await myImage.applying(.sepia, intensity: 0.8)

// Synchronous version (blocks thread)
let filtered = try myImage.applyingSync(.noir)
```

### SwiftUI Integration

```swift
import SwiftUI
import ImPAWsibleCoreImage
import ImPAWsibleCoreImageUI

struct PhotoEditorView: View {
    @State private var selectedFilter: ImPAWsibleFilter = .none
    let image: UIImage

    var body: some View {
        VStack {
            // Display filtered image
            FilteredImageView(
                image: image,
                filter: selectedFilter,
                contentMode: .fit
            )
            .frame(height: 400)

            Divider()

            // Filter picker
            FilterPickerView(
                sourceImage: image,
                selectedFilter: $selectedFilter,
                thumbnailSize: 80
            )
            .frame(height: 110)
        }
    }
}
```

### Advanced Usage

#### Batch Processing

```swift
// Process multiple images concurrently
let images = [image1, image2, image3]
let filteredImages = try await UIImage.applyingBatch(images, filter: .vintage)
```

#### Generate Filter Previews

```swift
// Generate thumbnails for all filters (great for filter pickers)
let previews = try await myImage.generateFilterPreviews(maxDimension: 128)

// Access preview for specific filter
if let monoPreview = previews[.mono] {
    // Use preview image
}
```

#### Using FilterProcessor Directly

```swift
let processor = FilterProcessor()

// Process single image
let filtered = try await processor.process(image, filter: .chrome)

// Generate thumbnail
let thumbnail = try await processor.generateThumbnail(
    image,
    filter: .sepia,
    maxDimension: 256,
    intensity: 0.9
)

// Batch processing
let results = try await processor.processBatch(images, filter: .fade)
```

## 🎨 SwiftUI Components

### FilteredImageView

Displays an image with a filter applied, handling loading states automatically.

```swift
FilteredImageView(
    image: myImage,
    filter: .mono,
    intensity: 1.0,
    contentMode: .fit,
    showLoadingIndicator: true
)
```

**Parameters:**
- `image`: The source UIImage
- `filter`: The filter to apply (default: `.none`)
- `intensity`: Filter intensity 0.0-1.0 (default: `1.0`)
- `contentMode`: SwiftUI ContentMode (default: `.fit`)
- `showLoadingIndicator`: Show progress view while filtering (default: `true`)

### FilterPickerView

An interactive horizontal scrollable filter picker with thumbnails.

```swift
@State private var selectedFilter: ImPAWsibleFilter = .none

FilterPickerView(
    sourceImage: myImage,
    selectedFilter: $selectedFilter,
    thumbnailSize: 80,
    showFilterNames: true,
    cornerRadius: 8,
    selectedBorderColor: .blue,
    selectedBorderWidth: 3
)
```

**Parameters:**
- `sourceImage`: Image to preview filters on
- `selectedFilter`: Binding to selected filter
- `thumbnailSize`: Size of each thumbnail (default: `80`)
- `filters`: Specific filters to show (default: all)
- `showFilterNames`: Display filter names (default: `true`)
- `cornerRadius`: Thumbnail corner radius (default: `8`)
- `selectedBorderColor`: Selected border color (default: `.blue`)
- `selectedBorderWidth`: Selected border width (default: `3`)

## 🔧 API Reference

### ImPAWsibleFilter

The main filter enum with all available filters.

```swift
public enum ImPAWsibleFilter: String, CaseIterable, Identifiable, Sendable {
    case none, mono, noir, sepia, vintage, tonal,
         transfer, chrome, fade, instant

    public var displayName: String { get }
    public var ciFilterName: String { get }
    public var description: String { get }
    public var supportsIntensity: Bool { get }
}
```

### FilterProcessor

High-performance filter processor with async and sync APIs.

```swift
public final class FilterProcessor: Sendable {
    // Async API (recommended)
    public func process(
        _ image: UIImage,
        filter: ImPAWsibleFilter,
        intensity: Double = 1.0
    ) async throws -> UIImage

    public func processBatch(
        _ images: [UIImage],
        filter: ImPAWsibleFilter,
        intensity: Double = 1.0
    ) async throws -> [UIImage]

    public func generateThumbnail(
        _ image: UIImage,
        filter: ImPAWsibleFilter,
        maxDimension size: CGFloat = 256,
        intensity: Double = 1.0
    ) async throws -> UIImage

    // Sync API
    public func processSync(
        _ image: UIImage,
        filter: ImPAWsibleFilter,
        intensity: Double = 1.0
    ) throws -> UIImage
}
```

### UIImage Extensions

Convenient methods added to UIImage.

```swift
extension UIImage {
    // Async methods
    func applying(_ filter: ImPAWsibleFilter, intensity: Double = 1.0) async throws -> UIImage
    func filterThumbnail(_ filter: ImPAWsibleFilter, maxDimension: CGFloat = 256, intensity: Double = 1.0) async throws -> UIImage
    func generateFilterPreviews(maxDimension: CGFloat = 128, filters: [ImPAWsibleFilter] = ImPAWsibleFilter.allCases) async throws -> [ImPAWsibleFilter: UIImage]

    // Sync methods
    func applyingSync(_ filter: ImPAWsibleFilter, intensity: Double = 1.0) throws -> UIImage

    // Static batch method
    static func applyingBatch(_ images: [UIImage], filter: ImPAWsibleFilter, intensity: Double = 1.0) async throws -> [UIImage]
}
```

### Error Handling

```swift
public enum FilterError: LocalizedError {
    case filterNotAvailable(String)
    case filterProcessingFailed(String)
    case renderingFailed
    case invalidInputImage
    case invalidIntensity(Double)

    public var errorDescription: String? { get }
}
```

## 📱 Example App

Check out the example app in the repository for a complete implementation:

```swift
import SwiftUI
import ImPAWsibleCoreImage
import ImPAWsibleCoreImageUI

@main
struct PhotoFilterApp: App {
    var body: some Scene {
        WindowGroup {
            PhotoEditorView()
        }
    }
}

struct PhotoEditorView: View {
    @State private var selectedFilter: ImPAWsibleFilter = .none
    @State private var selectedImage: UIImage?

    var body: some View {
        NavigationView {
            VStack {
                if let image = selectedImage {
                    FilteredImageView(image: image, filter: selectedFilter)
                        .frame(maxHeight: 400)

                    FilterPickerView(
                        sourceImage: image,
                        selectedFilter: $selectedFilter
                    )
                    .frame(height: 110)
                    .padding(.vertical)

                    Text(selectedFilter.description)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding()
                } else {
                    ContentUnavailableView(
                        "No Image Selected",
                        systemImage: "photo",
                        description: Text("Tap the button to select a photo")
                    )
                }
            }
            .navigationTitle("Photo Filters")
            .toolbar {
                Button("Select Photo") {
                    // Image picker implementation
                }
            }
        }
    }
}
```

## 🎯 Performance Tips

1. **Use Async API**: Always prefer the async/await API for better performance and UI responsiveness
2. **Thumbnail Previews**: Generate thumbnails for filter pickers instead of full-resolution images
3. **Batch Processing**: Use batch methods when processing multiple images with the same filter
4. **Shared Context**: The library automatically uses a shared Core Image context for optimal performance
5. **Background Processing**: Filter processing happens off the main thread automatically with async API

## 🔍 Technical Details

### Architecture

- **Thread Safety**: Uses Swift actors for thread-safe Core Image context management
- **Concurrency**: Built with Swift Concurrency (async/await, TaskGroup)
- **Performance**: Shared CIContext with optimized settings
- **Memory**: Efficient thumbnail generation and batch processing

### Requirements

- iOS 16.0+ / macOS 13.0+
- Swift 5.9+
- Xcode 15.0+

### Core Image Filters Used

All filters are built on Apple's Core Image framework:
- Photo Effect filters: Available since iOS 7.0 / macOS 10.9
- Sepia Tone: Available since iOS 5.0 / macOS 10.4

## 🤝 Contributing

Contributions are welcome! Please feel free to submit a Pull Request. For major changes, please open an issue first to discuss what you would like to change.

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🙏 Acknowledgments

- Built with Apple's [Core Image](https://developer.apple.com/documentation/coreimage) framework
- Inspired by the classic photo effects in iOS and macOS
- Named with a playful pun on "impossible" 🐾

## 📚 Resources

- [Core Image Filter Reference](https://developer.apple.com/library/archive/documentation/GraphicsImaging/Reference/CoreImageFilterReference/)
- [Core Image Programming Guide](https://developer.apple.com/library/archive/documentation/GraphicsImaging/Conceptual/CoreImaging/ci_intro/ci_intro.html)
- [Swift Concurrency Documentation](https://docs.swift.org/swift-book/LanguageGuide/Concurrency.html)

## 🐛 Issues

Found a bug? Please [open an issue](https://github.com/IBMer/ImPAWsibleCoreImage/issues) with:
- Description of the problem
- Steps to reproduce
- Expected vs actual behavior
- iOS/macOS version and device information

---

Made with ❤️ using Swift and Core Image
