/// ImPAWsibleCoreImageUI - SwiftUI Components for Filter Processing
///
/// This module provides SwiftUI views and components for integrating
/// ImPAWsibleCoreImage filters into your SwiftUI applications.
///
/// ## Features
/// - Ready-to-use SwiftUI views
/// - Automatic filter preview generation
/// - Interactive filter picker
/// - Loading states and error handling
///
/// ## Quick Start
///
/// ### Display a filtered image:
/// ```swift
/// FilteredImageView(image: myImage, filter: .mono)
/// ```
///
/// ### Let users pick a filter:
/// ```swift
/// @State private var selectedFilter: ImPAWsibleFilter = .none
///
/// FilterPickerView(
///     sourceImage: myImage,
///     selectedFilter: $selectedFilter
/// )
/// ```
///
/// ## Topics
///
/// ### Views
/// - ``FilteredImageView``
/// - ``FilterPickerView``

import Foundation

// Version information
public enum ImPAWsibleCoreImageUI {
    /// The current version of the UI library
    public static let version = "1.0.0"

    /// The library name
    public static let name = "ImPAWsibleCoreImageUI"
}
