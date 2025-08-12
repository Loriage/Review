import SwiftUI

struct MediaGridView: View {
    @ObservedObject var viewModel: LibraryDetailViewModel
    
    private let columns = [GridItem(.adaptive(minimum: 110), spacing: 10)]

    var body: some View {
        LazyVGrid(columns: columns, spacing: 10) {
            ForEach(viewModel.mediaItems) { media in
                mediaCell(for: media)
            }
        }
    }

    @ViewBuilder
    private func mediaCell(for media: MediaMetadata) -> some View {
        NavigationLink(destination: MediaHistoryView(
            ratingKey: media.ratingKey,
            mediaType: media.type,
            grandparentRatingKey: media.type == "show" ? media.ratingKey : media.grandparentRatingKey,
            serverViewModel: viewModel.serverViewModel,
            authManager: viewModel.authManager,
            statsViewModel: viewModel.statsViewModel
        )) {
            AsyncImageView(url: viewModel.posterURL(for: media))
                .aspectRatio(2/3, contentMode: .fill)
                .cornerRadius(8)
                .shadow(color: .black.opacity(0.25), radius: 2, y: 2)
        }
        .buttonStyle(.plain)
        .task(id: media.id) {
            await viewModel.loadMoreContentIfNeeded(currentItem: media)
        }
    }
}
