/// ImPAWsibleCoreImage - Modern Swift Core Image Filter Library
///
/// A modern, Swift-first library for applying professional photo filters to images.
/// Built on top of Apple's Core Image framework with SwiftUI support.
///
/// ## Features
/// - 10 professional photo filters (Mono, Noir, Sepia, Vintage, etc.)
/// - Async/await API for optimal performance
/// - SwiftUI components for easy integration
/// - Thread-safe filter processing
/// - Batch processing support
/// - Thumbnail generation for previews
///
/// ## Quick Start
///
/// ### Apply a filter to an image:
/// ```swift
/// import ImPAWsibleCoreImage
///
/// let filtered = try await myImage.applying(.mono)
/// ```
///
/// ### Use in SwiftUI:
/// ```swift
/// import ImPAWsibleCoreImageUI
///
/// struct ContentView: View {
///     var body: some View {
///         FilteredImageView(image: myImage, filter: .sepia)
///     }
/// }
/// ```
///
/// ## Topics
///
/// ### Filters
/// - ``ImPAWsibleFilter``
///
/// ### Processing
/// - ``FilterProcessor``
/// - ``FilterContext``
///
/// ### Errors
/// - ``FilterError``
///
/// ### Extensions
/// - ``UIImage``

import Foundation

// Version information
public enum ImPAWsibleCoreImage {
    /// The current version of the library
    public static let version = "1.0.0"

    /// The library name
    public static let name = "ImPAWsibleCoreImage"
}
