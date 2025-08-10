import Foundation
import SwiftUI
import Combine

@MainActor
class LibraryViewModel: ObservableObject {
    @Published var displayLibraries: [DisplayLibrary] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let plexService: PlexAPIService
    private let serverViewModel: ServerViewModel
    private let authManager: PlexAuthManager
    
    private var currentServerDetails: (url: String, token: String)?
    private var cancellables = Set<AnyCancellable>()

    init(serverViewModel: ServerViewModel, authManager: PlexAuthManager, plexService: PlexAPIService = PlexAPIService()) {
        self.serverViewModel = serverViewModel
        self.authManager = authManager
        self.plexService = plexService
        
        serverViewModel.$selectedServerID
            .sink { [weak self] _ in
                self?.displayLibraries = []
            }
            .store(in: &cancellables)
    }
    
    func loadLibrariesIfNeeded() async {
        guard displayLibraries.isEmpty else { return }
        await fetchData()
    }

    func refreshData() async {
        self.displayLibraries = []
        await fetchData()
    }
    
    private func fetchData() async {
        guard let serverID = serverViewModel.selectedServerID,
              let server = serverViewModel.availableServers.first(where: { $0.id == serverID }),
              let connection = server.connections.first(where: { !$0.local }) ?? server.connections.first,
              let token = authManager.getPlexAuthToken()
        else {
            if displayLibraries.isEmpty { errorMessage = "Serveur non sélectionné ou informations manquantes." }
            return
        }
        
        if self.displayLibraries.isEmpty {
            isLoading = true
        }
        errorMessage = nil
        
        let serverURL = connection.uri
        let resourceToken = server.accessToken ?? token
        self.currentServerDetails = (url: serverURL, token: resourceToken)
        
        do {
            let fetchedLibraries = try await plexService.fetchLibraries(serverURL: serverURL, token: resourceToken)
            self.displayLibraries = fetchedLibraries.map { DisplayLibrary(id: $0.id, library: $0) }
            self.isLoading = false
            
            await fetchAllLibraryDetails()
            
        } catch {
            let nsError = error as NSError
            if !(nsError.domain == NSURLErrorDomain && nsError.code == NSURLErrorCancelled) {
                self.errorMessage = "Impossible de charger les médiathèques : \(error.localizedDescription)"
            }
        }
        
        isLoading = false
    }
    
    private func fetchAllLibraryDetails() async {
        await withTaskGroup(of: Void.self) { group in
            for i in displayLibraries.indices {
                group.addTask {
                    await self.fetchDetailsForLibrary(at: i)
                }
            }
        }
    }

    private func fetchDetailsForLibrary(at index: Int) async {
        guard let details = currentServerDetails, index < displayLibraries.count else { return }
        let library = displayLibraries[index].library
        
        async let recentsTask = getRecentItems(forLibrary: library)
        async let countsTask = calculateCounts(forLibrary: library)
        
        if let recents = await recentsTask {
            displayLibraries[index].recentItemURLs = recents.compactMap { item in
                guard let thumbPath = item.thumb else { return nil }
                return URL(string: "\(details.url)\(thumbPath)?X-Plex-Token=\(details.token)")
            }
        }

        if let result = await countsTask {
            displayLibraries[index].size = result.size
            displayLibraries[index].fileCount = result.shows
            if let episodes = result.episodes {
                displayLibraries[index].episodesCount = episodes
            }
        }
    }

    private func getRecentItems(forLibrary library: PlexLibrary) async -> [MediaMetadata]? {
        let mediaType = library.type == "show" ? 2 : 1
        guard let details = self.currentServerDetails else { return nil }

        do {
            let mediaItems = try await self.plexService.fetchAllMediaInSection(
                serverURL: details.url,
                token: details.token,
                libraryKey: library.key,
                mediaType: mediaType
            )

            let sortedItems = mediaItems.sorted {
                ($0.addedAt ?? 0) > ($1.addedAt ?? 0)
            }

            return Array(sortedItems)
            
        } catch {
            print("Erreur de récupération des ajouts récents pour la médiathèque \(library.key): \(error)")
            return nil
        }
    }

    private func calculateCounts(forLibrary library: PlexLibrary) async -> (size: Int64, shows: Int, episodes: Int?)? {
        guard let details = self.currentServerDetails else { return nil }
        
        do {
            if library.type == "show" {
                let shows = try await self.plexService.fetchAllMediaInSection(
                    serverURL: details.url,
                    token: details.token,
                    libraryKey: library.key,
                    mediaType: 2
                )
                
                let episodes = try await self.plexService.fetchAllMediaInSection(
                    serverURL: details.url,
                    token: details.token,
                    libraryKey: library.key,
                    mediaType: 4
                )

                let totalSize = episodes.reduce(Int64(0)) { $0 + ($1.media?.first?.parts.first?.size ?? 0) }
                
                return (totalSize, shows.count, episodes.count)
            } else {
                let movies = try await self.plexService.fetchAllMediaInSection(
                    serverURL: details.url,
                    token: details.token,
                    libraryKey: library.key,
                    mediaType: 1
                )
                
                let totalSize = movies.reduce(Int64(0)) { $0 + ($1.media?.first?.parts.first?.size ?? 0) }
                return (totalSize, movies.count, nil)
            }
            
        } catch {
            let nsError = error as NSError
            if !(nsError.domain == NSURLErrorDomain && nsError.code == NSURLErrorCancelled) {
                print("Erreur de calcul de la taille pour la médiathèque \(library.key): \(error)")
            }
            return nil
        }
    }
}
