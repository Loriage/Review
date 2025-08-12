import Foundation
import SwiftUI
import Combine

@MainActor
class LibraryViewModel: ObservableObject {
    @Published var displayLibraries: [DisplayLibrary] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let libraryService: PlexLibraryService
    private let serverViewModel: ServerViewModel
    private let authManager: PlexAuthManager
    
    private var currentServerDetails: (url: String, token: String)?
    private var cancellables = Set<AnyCancellable>()

    init(serverViewModel: ServerViewModel, authManager: PlexAuthManager, libraryService: PlexLibraryService = PlexLibraryService()) {
        self.serverViewModel = serverViewModel
        self.authManager = authManager
        self.libraryService = libraryService
        
        serverViewModel.$selectedServerID
            .sink { [weak self] _ in
                self?.displayLibraries = []
            }
            .store(in: &cancellables)

        NotificationCenter.default.addObserver(self, selector: #selector(handleLibraryUpdate), name: .didUpdateLibraryPreferences, object: nil)
    }

    func startFetchingDetailsFor(libraryID: String) {
        guard let libraryToUpdate = displayLibraries.first(where: { $0.id == libraryID }) else { return }
        guard libraryToUpdate.loadingState == .idle else { return }
        
        libraryToUpdate.loadingState = .loading

        Task {
            await self.fetchDetails(for: libraryToUpdate)
        }
    }
    
    func loadLibrariesIfNeeded() async {
        guard displayLibraries.isEmpty else { return }
        await fetchData()
    }

    @objc private func handleLibraryUpdate() {
        Task {
            await refreshData()
        }
    }

    func refreshData() async {
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
            let fetchedPlexLibs = try await libraryService.fetchLibraries(serverURL: serverURL, token: resourceToken)
            let fetchedLibsDict = Dictionary(uniqueKeysWithValues: fetchedPlexLibs.map { ($0.uuid, $0) })

            self.displayLibraries.removeAll { fetchedLibsDict[$0.id] == nil }

            for plexLib in fetchedPlexLibs {
                if let existingDisplayLib = self.displayLibraries.first(where: { $0.id == plexLib.uuid }) {
                    existingDisplayLib.library = plexLib
                } else {
                    self.displayLibraries.append(DisplayLibrary(id: plexLib.uuid, library: plexLib))
                }
            }
            self.isLoading = false
        } catch {
            let nsError = error as NSError
            if !(nsError.domain == NSURLErrorDomain && nsError.code == NSURLErrorCancelled) {
                self.errorMessage = "Impossible de charger les médiathèques : \(error.localizedDescription)"
            }
        }
        
        isLoading = false
    }

    private func fetchDetails(for libraryToUpdate: DisplayLibrary) async {
        guard let details = currentServerDetails else {
            libraryToUpdate.loadingState = .error
            return
        }
        
        let library = libraryToUpdate.library
        
        async let recentsTask = getRecentItems(forLibrary: library)
        async let countsTask = calculateCounts(forLibrary: library)
        
        if let recents = await recentsTask {
            libraryToUpdate.recentItemURLs = recents.compactMap { item in
                guard let thumbPath = item.thumb else { return nil }
                return URL(string: "\(details.url)\(thumbPath)?X-Plex-Token=\(details.token)")
            }
        }

        if let result = await countsTask {
            libraryToUpdate.size = result.size
            libraryToUpdate.fileCount = result.shows
            if let episodes = result.episodes {
                libraryToUpdate.episodesCount = episodes
            }
            libraryToUpdate.loadingState = .loaded
        } else {
            libraryToUpdate.loadingState = .error
        }
    }

    private func getRecentItems(forLibrary library: PlexLibrary) async -> [MediaMetadata]? {
        let mediaType = library.type == "show" ? 2 : 1
        guard let details = self.currentServerDetails else { return nil }

        do {
            let mediaItems = try await self.libraryService.fetchAllMediaInSection(
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
            return nil
        }
    }

    private func calculateCounts(forLibrary library: PlexLibrary) async -> (size: Int64, shows: Int, episodes: Int?)? {
        guard let details = self.currentServerDetails else { return nil }
        
        do {
            if library.type == "show" {
                let shows = try await self.libraryService.fetchAllMediaInSection(
                    serverURL: details.url,
                    token: details.token,
                    libraryKey: library.key,
                    mediaType: 2
                )
                
                let episodes = try await self.libraryService.fetchAllMediaInSection(
                    serverURL: details.url,
                    token: details.token,
                    libraryKey: library.key,
                    mediaType: 4
                )

                let totalSize = episodes.reduce(Int64(0)) { $0 + ($1.media?.first?.parts.first?.size ?? 0) }
                
                return (totalSize, shows.count, episodes.count)
            } else {
                let movies = try await self.libraryService.fetchAllMediaInSection(
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
            }
            return nil
        }
    }
}
