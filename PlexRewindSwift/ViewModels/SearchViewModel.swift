import Foundation
import Combine

@MainActor
class SearchViewModel: ObservableObject {

    enum SearchState {
        case idle
        case loading
        case loaded
        case empty
        case error(String)
    }

    @Published var searchText = ""
    @Published private(set) var searchResults: [SearchResult] = []
    @Published private(set) var state: SearchState = .idle

    private let serverViewModel: ServerViewModel
    private let authManager: PlexAuthManager
    private let libraryService: PlexLibraryService
    private var cancellables = Set<AnyCancellable>()

    init(serverViewModel: ServerViewModel, authManager: PlexAuthManager, libraryService: PlexLibraryService = PlexLibraryService()) {
        self.serverViewModel = serverViewModel
        self.authManager = authManager
        self.libraryService = libraryService

        $searchText
            .debounce(for: .milliseconds(500), scheduler: DispatchQueue.main)
            .removeDuplicates()
            .sink { [weak self] query in
                Task {
                    await self?.performSearch(query: query)
                }
            }
            .store(in: &cancellables)
    }

    func performSearch(query: String) async {
        guard !query.trimmingCharacters(in: .whitespaces).isEmpty else {
            self.searchResults = []
            self.state = .idle
            return
        }
        
        guard let serverDetails = getServerDetails() else {
            self.state = .error("Aucun serveur sélectionné.")
            return
        }
        
        self.state = .loading
        
        do {
            let apiResults = try await libraryService.searchContent(serverURL: serverDetails.url, token: serverDetails.token, query: query)

            let filteredResults = apiResults.filter { result in
                result.title.localizedCaseInsensitiveContains(query)
            }

            self.searchResults = filteredResults
            self.state = filteredResults.isEmpty ? .empty : .loaded
            
        } catch {
            self.state = .error("Erreur lors de la recherche : \(error.localizedDescription)")
        }
    }

    func posterURL(for result: SearchResult) -> URL? {
        guard let path = result.posterPath, let serverDetails = getServerDetails() else {
            return nil
        }
        return URL(string: "\(serverDetails.url)\(path)?X-Plex-Token=\(serverDetails.token)")
    }

    private func getServerDetails() -> (url: String, token: String)? {
        guard let serverID = serverViewModel.selectedServerID,
              let server = serverViewModel.availableServers.first(where: { $0.id == serverID }),
              let connection = server.connections.first(where: { !$0.local }) ?? server.connections.first,
              let token = authManager.getPlexAuthToken()
        else {
            return nil
        }
        let resourceToken = server.accessToken ?? token
        return (url: connection.uri, token: resourceToken)
    }
}
