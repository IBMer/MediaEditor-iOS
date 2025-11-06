import SwiftUI
import ImPAWsibleCoreImage

/// A SwiftUI view that displays an image with a filter applied
///
/// This view automatically applies the specified filter to the image and
/// handles loading states. The filter processing happens asynchronously
/// to keep the UI responsive.
///
/// Example usage:
/// ```swift
/// FilteredImageView(
///     image: myUIImage,
///     filter: .mono,
///     contentMode: .fit
/// )
/// ```
@available(iOS 16.0, macOS 13.0, *)
public struct FilteredImageView: View {
    // MARK: - Properties

    /// The source image to filter
    let sourceImage: UIImage

    /// The filter to apply
    let filter: ImPAWsibleFilter

    /// The filter intensity (0.0 - 1.0)
    let intensity: Double

    /// Content mode for the image
    let contentMode: ContentMode

    /// Whether to show a loading indicator while processing
    let showLoadingIndicator: Bool

    /// State to hold the filtered image
    @State private var filteredImage: UIImage?

    /// State to track loading
    @State private var isLoading = false

    /// State to track errors
    @State private var error: Error?

    // MARK: - Initialization

    /// Creates a new filtered image view
    /// - Parameters:
    ///   - image: The source UIImage to filter
    ///   - filter: The filter to apply (default: .none)
    ///   - intensity: The filter intensity between 0.0 and 1.0 (default: 1.0)
    ///   - contentMode: How the image should be scaled (default: .fit)
    ///   - showLoadingIndicator: Whether to show loading indicator (default: true)
    public init(
        image: UIImage,
        filter: ImPAWsibleFilter = .none,
        intensity: Double = 1.0,
        contentMode: ContentMode = .fit,
        showLoadingIndicator: Bool = true
    ) {
        self.sourceImage = image
        self.filter = filter
        self.intensity = intensity
        self.contentMode = contentMode
        self.showLoadingIndicator = showLoadingIndicator
    }

    // MARK: - Body

    public var body: some View {
        Group {
            if let filteredImage {
                Image(uiImage: filteredImage)
                    .resizable()
                    .aspectRatio(contentMode: contentMode)
            } else if isLoading && showLoadingIndicator {
                ProgressView()
            } else if error != nil {
                errorView
            } else {
                Color.clear
            }
        }
        .task(id: filter) {
            await applyFilter()
        }
        .task(id: intensity) {
            await applyFilter()
        }
    }

    // MARK: - Private Views

    private var errorView: some View {
        VStack(spacing: 8) {
            Image(systemName: "exclamationmark.triangle")
                .font(.largeTitle)
                .foregroundColor(.red)
            Text("Failed to apply filter")
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }

    // MARK: - Private Methods

    private func applyFilter() async {
        isLoading = true
        error = nil

        do {
            // Apply filter
            let result = try await sourceImage.applying(filter, intensity: intensity)
            await MainActor.run {
                filteredImage = result
                isLoading = false
            }
        } catch {
            await MainActor.run {
                self.error = error
                self.filteredImage = sourceImage // Fallback to original
                isLoading = false
            }
        }
    }
}

// MARK: - Previews

#Preview("Single Filter") {
    if let image = UIImage(systemName: "photo") {
        VStack {
            FilteredImageView(image: image, filter: .mono)
                .frame(width: 200, height: 200)
        }
    }
}

#Preview("Multiple Filters") {
    if let image = UIImage(systemName: "photo") {
        ScrollView {
            VStack(spacing: 20) {
                ForEach(ImPAWsibleFilter.allCases.prefix(4)) { filter in
                    VStack {
                        Text(filter.displayName)
                            .font(.headline)
                        FilteredImageView(image: image, filter: filter)
                            .frame(height: 200)
                    }
                }
            }
            .padding()
        }
    }
}
