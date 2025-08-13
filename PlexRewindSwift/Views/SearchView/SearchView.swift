import SwiftUI

struct SearchView: View {
    @StateObject private var viewModel: SearchViewModel
    @EnvironmentObject var serverViewModel: ServerViewModel
    @EnvironmentObject var authManager: PlexAuthManager
    @EnvironmentObject var statsViewModel: StatsViewModel

    private var movies: [SearchResult] {
        viewModel.searchResults.filter { $0.type == "movie" }
    }

    private var shows: [SearchResult] {
        viewModel.searchResults.filter { $0.type == "show" || $0.type == "episode" }
    }

    init(serverViewModel: ServerViewModel, authManager: PlexAuthManager, statsViewModel: StatsViewModel) {
        _viewModel = StateObject(wrappedValue: SearchViewModel(
            serverViewModel: serverViewModel,
            authManager: authManager
        ))
    }

    var body: some View {
        NavigationStack {
            Group {
                switch viewModel.state {
                case .idle:
                    EmptyDataView(
                        systemImageName: "magnifyingglass",
                        title: "Rechercher",
                        message: "Recherchez des films, séries et plus encore sur votre serveur Plex."
                    )
                case .loading:
                    ProgressView()
                case .empty:
                    EmptyDataView(
                        systemImageName: "questionmark.folder",
                        title: "Aucun résultat",
                        message: "Aucun résultat trouvé pour \"\(viewModel.searchText)\"."
                    )
                case .loaded:
                    List {
                        if !movies.isEmpty {
                            Section(header: Text("Films")) {
                                ForEach(movies) { result in
                                    NavigationLink(destination: mediaHistoryDestination(for: result)) {
                                        SearchResultRow(result: result, posterURL: viewModel.posterURL(for: result))
                                    }
                                }
                            }
                        }

                        if !shows.isEmpty {
                            Section(header: Text("Séries")) {
                                ForEach(shows) { result in
                                    NavigationLink(destination: mediaHistoryDestination(for: result)) {
                                        SearchResultRow(result: result, posterURL: viewModel.posterURL(for: result))
                                    }
                                }
                            }
                        }
                    }
                case .error(let message):
                    VStack {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundColor(.red)
                        Text(message)
                            .padding()
                            .multilineTextAlignment(.center)
                    }
                }
            }
            .navigationTitle("Recherche")
            .navigationBarTitleDisplayMode(.inline)
        }
        .searchable(text: $viewModel.searchText, placement: .navigationBarDrawer(displayMode: .always))
        .onAppear {
            Task {
                await viewModel.cacheAllSearchableMedia()
            }
        }
    }
    
    private func mediaHistoryDestination(for result: SearchResult) -> some View {
        MediaHistoryView(
            ratingKey: result.ratingKey,
            mediaType: result.type,
            grandparentRatingKey: result.effectiveGrandparentRatingKey,
            serverViewModel: serverViewModel,
            authManager: authManager,
            statsViewModel: statsViewModel
        )
    }
}
