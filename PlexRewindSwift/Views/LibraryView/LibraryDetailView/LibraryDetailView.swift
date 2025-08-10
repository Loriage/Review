import SwiftUI

struct LibraryDetailView: View {
    @StateObject private var viewModel: LibraryDetailViewModel
    @ObservedObject private var library: DisplayLibrary
    @EnvironmentObject var serverViewModel: ServerViewModel
    @EnvironmentObject var authManager: PlexAuthManager
    @EnvironmentObject var statsViewModel: StatsViewModel

    private let columns = [GridItem(.adaptive(minimum: 110), spacing: 10)]

    init(library: DisplayLibrary, serverViewModel: ServerViewModel, authManager: PlexAuthManager) {
        _viewModel = StateObject(wrappedValue: LibraryDetailViewModel(
            library: library,
            serverViewModel: serverViewModel,
            authManager: authManager
        ))
        self.library = library
    }

    var body: some View {
        ScrollView {
            statsSection
                .padding(.horizontal)

            switch viewModel.state {
            case .loading:
                ProgressView()
                    .padding(.top, 40)
            case .content:
                mediaGridView
            case .error(let message):
                Text(message)
                    .foregroundColor(.red)
                    .padding()
            }
        }
        .navigationTitle(viewModel.library.library.title)
        .task {
            await viewModel.loadInitialContent()
        }
    }

    private var mediaGridView: some View {
        LazyVGrid(columns: columns, spacing: 10) {
            ForEach(viewModel.mediaItems) { media in
                mediaCell(for: media)
            }
        }
        .padding(.horizontal)
        .padding(.top)
    }

    private func mediaCell(for media: MediaMetadata) -> some View {
        NavigationLink(destination: MediaHistoryView(
            ratingKey: media.ratingKey,
            mediaType: media.type,
            grandparentRatingKey: media.type == "show" ? media.ratingKey : media.grandparentRatingKey,
            serverViewModel: serverViewModel,
            authManager: authManager,
            statsViewModel: statsViewModel
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

    private var statsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Statistiques")
                .font(.title2.bold())
                .padding(.top)

            HStack(spacing: 10) {
                if viewModel.library.library.type == "movie" {
                    InfoPill(
                        title: "Films",
                        value: library.fileCount != nil ? "\(library.fileCount!)" : "...",
                    )
                    InfoPill(
                        title: "Taille",
                        value: library.size != nil ? "\(formatBytes(library.size!))" : "...",
                    )
                } else if viewModel.library.library.type == "show" {
                    InfoPill(
                        title: "Séries",
                        value: library.fileCount != nil ? "\(library.fileCount!)" : "...",
                    )
                    InfoPill(
                        title: "Épisodes",
                        value: library.episodesCount != nil ? "\(library.episodesCount!)" : "...",
                    )
                    InfoPill(
                        title: "Taille",
                        value: library.size != nil ? "\(formatBytes(library.size!))" : "...",
                    )
                }
            }
        }
    }

    private func formatBytes(_ bytes: Int64) -> String {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useGB, .useMB, .useTB]
        formatter.countStyle = .binary
        return formatter.string(fromByteCount: bytes)
    }
}
