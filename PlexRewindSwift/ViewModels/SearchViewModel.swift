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

    private var searchableMediaCache: [MediaMetadata] = []
    private var isCacheLoading = false

    private let serverViewModel: ServerViewModel
    private let authManager: PlexAuthManager
    private let libraryService: PlexLibraryService
    private var cancellables = Set<AnyCancellable>()

    init(serverViewModel: ServerViewModel, authManager: PlexAuthManager, libraryService: PlexLibraryService = PlexLibraryService()) {
        self.serverViewModel = serverViewModel
        self.authManager = authManager
        self.libraryService = libraryService

        $searchText
            .debounce(for: .milliseconds(300), scheduler: DispatchQueue.main)
            .removeDuplicates()
            .sink { [weak self] query in
                self?.performLocalSearch(query: query)
            }
            .store(in: &cancellables)
    }

    func cacheAllSearchableMedia() async {
        guard searchableMediaCache.isEmpty, !isCacheLoading, let serverDetails = getServerDetails() else { return }
        
        isCacheLoading = true
        state = .loading
        do {
            let allMedia = try await libraryService.fetchAllSearchableMedia(serverURL: serverDetails.url, token: serverDetails.token)

            self.searchableMediaCache = allMedia
            self.state = .idle
        } catch {
            self.state = .error("Impossible de charger le catalogue pour la recherche.")
        }
        isCacheLoading = false
    }

    private func performLocalSearch(query: String) {
        if query.trimmingCharacters(in: .whitespaces).isEmpty {
            self.searchResults = []
            self.state = .idle
            return
        }
        
        let normalizedQuery = query.folding(options: [.diacriticInsensitive, .caseInsensitive], locale: .current)
        let queryWords = normalizedQuery.components(separatedBy: .whitespacesAndNewlines).filter { !$0.isEmpty }
        
        let filteredResults = searchableMediaCache.filter { media in
            guard let title = media.title else { return false }
            
            let normalizedTitle = title.folding(options: [.diacriticInsensitive, .caseInsensitive], locale: .current)

            if normalizedTitle.contains(normalizedQuery) {
                return true
            }

            if StringSimilarityHelper.levenshteinDistance(a: normalizedQuery, b: normalizedTitle) <= 2 {
                return true
            }

            if queryWords.count == 1 {
                let singleQueryWord = queryWords[0]
                let wordsInTitle = normalizedTitle.components(separatedBy: .whitespacesAndNewlines)
                for titleWord in wordsInTitle {
                    if StringSimilarityHelper.levenshteinDistance(a: singleQueryWord, b: titleWord) <= 1 {
                        return true
                    }
                }
            }
            
            return false
        }
        
        self.searchResults = filteredResults.map { media in
            SearchResult(
                ratingKey: media.ratingKey,
                key: media.key,
                type: media.type,
                title: media.title ?? "",
                summary: media.summary,
                thumb: media.thumb,
                year: media.year,
                leafCount: media.leafCount,
                index: nil,
                parentIndex: nil,
                grandparentKey: media.grandparentKey,
                grandparentRatingKey: media.grandparentRatingKey,
                grandparentTitle: media.grandparentTitle,
                grandparentThumb: media.grandparentThumb
            )
        }
        
        self.state = self.searchResults.isEmpty ? .empty : .loaded
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
