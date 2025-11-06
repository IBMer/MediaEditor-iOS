import SwiftUI
import ImPAWsibleCoreImage

/// A SwiftUI view that displays a scrollable picker of available filters
///
/// This view shows thumbnails of the source image with each filter applied,
/// allowing users to preview and select filters interactively.
///
/// Example usage:
/// ```swift
/// @State private var selectedFilter: ImPAWsibleFilter = .none
///
/// FilterPickerView(
///     sourceImage: myImage,
///     selectedFilter: $selectedFilter,
///     thumbnailSize: 80
/// )
/// ```
@available(iOS 16.0, macOS 13.0, *)
public struct FilterPickerView: View {
    // MARK: - Properties

    /// The source image to preview filters on
    let sourceImage: UIImage

    /// Binding to the currently selected filter
    @Binding var selectedFilter: ImPAWsibleFilter

    /// Size of each filter thumbnail
    let thumbnailSize: CGFloat

    /// The filters to display (defaults to all)
    let filters: [ImPAWsibleFilter]

    /// Whether to show filter names
    let showFilterNames: Bool

    /// Corner radius for thumbnails
    let cornerRadius: CGFloat

    /// Selected border color
    let selectedBorderColor: Color

    /// Selected border width
    let selectedBorderWidth: CGFloat

    // MARK: - Initialization

    /// Creates a new filter picker view
    /// - Parameters:
    ///   - sourceImage: The image to preview filters on
    ///   - selectedFilter: Binding to the selected filter
    ///   - thumbnailSize: Size of each thumbnail (default: 80)
    ///   - filters: Specific filters to show (default: all)
    ///   - showFilterNames: Whether to display filter names (default: true)
    ///   - cornerRadius: Corner radius for thumbnails (default: 8)
    ///   - selectedBorderColor: Color for selected border (default: .blue)
    ///   - selectedBorderWidth: Width of selected border (default: 3)
    public init(
        sourceImage: UIImage,
        selectedFilter: Binding<ImPAWsibleFilter>,
        thumbnailSize: CGFloat = 80,
        filters: [ImPAWsibleFilter] = ImPAWsibleFilter.allCases,
        showFilterNames: Bool = true,
        cornerRadius: CGFloat = 8,
        selectedBorderColor: Color = .blue,
        selectedBorderWidth: CGFloat = 3
    ) {
        self.sourceImage = sourceImage
        self._selectedFilter = selectedFilter
        self.thumbnailSize = thumbnailSize
        self.filters = filters
        self.showFilterNames = showFilterNames
        self.cornerRadius = cornerRadius
        self.selectedBorderColor = selectedBorderColor
        self.selectedBorderWidth = selectedBorderWidth
    }

    // MARK: - Body

    public var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(filters) { filter in
                    FilterThumbnailCell(
                        sourceImage: sourceImage,
                        filter: filter,
                        size: thumbnailSize,
                        isSelected: selectedFilter == filter,
                        showName: showFilterNames,
                        cornerRadius: cornerRadius,
                        selectedBorderColor: selectedBorderColor,
                        selectedBorderWidth: selectedBorderWidth
                    )
                    .onTapGesture {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            selectedFilter = filter
                        }
                    }
                }
            }
            .padding(.horizontal)
        }
    }
}

/// Individual filter thumbnail cell
@available(iOS 16.0, macOS 13.0, *)
private struct FilterThumbnailCell: View {
    let sourceImage: UIImage
    let filter: ImPAWsibleFilter
    let size: CGFloat
    let isSelected: Bool
    let showName: Bool
    let cornerRadius: CGFloat
    let selectedBorderColor: Color
    let selectedBorderWidth: CGFloat

    @State private var thumbnail: UIImage?
    @State private var isLoading = true

    var body: some View {
        VStack(spacing: 6) {
            ZStack {
                if let thumbnail {
                    Image(uiImage: thumbnail)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: size, height: size)
                        .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
                        .overlay(
                            RoundedRectangle(cornerRadius: cornerRadius)
                                .strokeBorder(
                                    isSelected ? selectedBorderColor : Color.clear,
                                    lineWidth: selectedBorderWidth
                                )
                        )
                } else if isLoading {
                    RoundedRectangle(cornerRadius: cornerRadius)
                        .fill(Color.gray.opacity(0.2))
                        .frame(width: size, height: size)
                        .overlay {
                            ProgressView()
                        }
                }
            }
            .animation(.easeInOut(duration: 0.2), value: isSelected)

            if showName {
                Text(filter.displayName)
                    .font(.caption)
                    .foregroundColor(isSelected ? selectedBorderColor : .primary)
                    .lineLimit(1)
            }
        }
        .frame(width: size)
        .task {
            await generateThumbnail()
        }
    }

    private func generateThumbnail() async {
        do {
            let result = try await sourceImage.filterThumbnail(
                filter,
                maxDimension: size * 2 // 2x for retina
            )
            await MainActor.run {
                thumbnail = result
                isLoading = false
            }
        } catch {
            // Fallback to original image
            await MainActor.run {
                thumbnail = sourceImage
                isLoading = false
            }
        }
    }
}

// MARK: - Previews

#Preview("Filter Picker") {
    struct PreviewWrapper: View {
        @State private var selectedFilter: ImPAWsibleFilter = .none

        var body: some View {
            VStack {
                if let image = UIImage(systemName: "photo.fill") {
                    FilteredImageView(image: image, filter: selectedFilter)
                        .frame(height: 300)
                        .padding()

                    Divider()

                    FilterPickerView(
                        sourceImage: image,
                        selectedFilter: $selectedFilter
                    )
                    .frame(height: 110)

                    Text("Selected: \(selectedFilter.displayName)")
                        .font(.headline)
                        .padding()
                }
            }
        }
    }

    return PreviewWrapper()
}

#Preview("Compact Picker") {
    struct PreviewWrapper: View {
        @State private var selectedFilter: ImPAWsibleFilter = .sepia

        var body: some View {
            VStack {
                FilterPickerView(
                    sourceImage: UIImage(systemName: "photo.fill")!,
                    selectedFilter: $selectedFilter,
                    thumbnailSize: 60,
                    showFilterNames: false
                )
                .frame(height: 80)
            }
        }
    }

    return PreviewWrapper()
}
