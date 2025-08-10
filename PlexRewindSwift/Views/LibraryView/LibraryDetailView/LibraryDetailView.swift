import SwiftUI

struct LibraryDetailView: View {
    @StateObject private var viewModel: LibraryDetailViewModel
    @ObservedObject private var library: DisplayLibrary
    @EnvironmentObject var serverViewModel: ServerViewModel
    @EnvironmentObject var authManager: PlexAuthManager
    @EnvironmentObject var statsViewModel: StatsViewModel

    private let columns = [GridItem(.adaptive(minimum: 150), spacing: 15)]

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
        LazyVGrid(columns: columns, spacing: 20) {
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
                .shadow(radius: 5)
        }
        .buttonStyle(.plain)
        .task(id: media.id) {
            await viewModel.loadMoreContentIfNeeded(currentItem: media)
        }
    }

    private var statsSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Statistiques")
                .font(.title2.bold())
                .padding(.top)

            if viewModel.library.library.type == "movie" {
                if let count = library.fileCount {
                    Text("Nombre de films: \(count)")
                } else {
                    ProgressView().scaleEffect(0.7)
                }
            } else if viewModel.library.library.type == "show" {
                if let showCount = library.fileCount {
                    Text("Nombre de séries: \(showCount)")
                } else {
                    ProgressView().scaleEffect(0.7)
                }

                HStack {
                    Text("Nombre d'épisodes:")
                    if let count = library.episodesCount {
                        Text("\(count)")
                    } else {
                        ProgressView().scaleEffect(0.7)
                    }
                }
            }
        }
    }
}
