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
                        title: "search.view.empty.title",
                        message: "search.view.empty.message"
                    )
                case .loading:
                    ProgressView()
                case .empty:
                    EmptyDataView(
                        systemImageName: "questionmark.folder",
                        title: "empty.state.no.results.title",
                        message: "empty.state.no.results.message \(viewModel.searchText)"
                    )
                case .loaded:
                    List {
                        if !movies.isEmpty {
                            Section(header: Text("search.view.movies.section")) {
                                ForEach(movies) { result in
                                    NavigationLink(destination: mediaHistoryDestination(for: result)) {
                                        SearchResultRow(result: result, posterURL: viewModel.posterURL(for: result))
                                    }
                                }
                            }
                        }

                        if !shows.isEmpty {
                            Section(header: Text("search.view.shows.section")) {
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
            .navigationTitle("search.view.title")
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
