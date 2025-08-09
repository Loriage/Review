import Foundation
import SwiftUI
import Combine

@MainActor
class LibraryDetailViewModel: ObservableObject {
    @Published var library: DisplayLibrary
    @Published var allMedia: [MediaMetadata] = []
    @Published var episodesCount: Int = 0
    @Published var isLoading = false
    @Published var errorMessage: String?

    private let plexService: PlexAPIService
    private let serverViewModel: ServerViewModel
    private let authManager: PlexAuthManager
    private var cancellables = Set<AnyCancellable>()

    init(library: DisplayLibrary, serverViewModel: ServerViewModel, authManager: PlexAuthManager, plexService: PlexAPIService = PlexAPIService()) {
        self.library = library
        self.serverViewModel = serverViewModel
        self.authManager = authManager
        self.plexService = plexService
    }

    func loadLibraryContent() async {
        guard let serverID = serverViewModel.selectedServerID,
              let server = serverViewModel.availableServers.first(where: { $0.id == serverID }),
              let connection = server.connections.first(where: { !$0.local }) ?? server.connections.first,
              let token = authManager.getPlexAuthToken()
        else {
            errorMessage = "Serveur non sélectionné ou informations manquantes."
            return
        }

        isLoading = true
        errorMessage = nil

        let serverURL = connection.uri
        let resourceToken = server.accessToken ?? token

        do {
            let mediaType = library.library.type == "movie" ? 1 : 2
            self.allMedia = try await plexService.fetchAllMediaInSection(serverURL: serverURL, token: resourceToken, libraryKey: library.library.key, mediaType: mediaType)

            if library.library.type == "show" {
                 let episodes = try await plexService.fetchAllMediaInSection(serverURL: serverURL, token: resourceToken, libraryKey: library.library.key, mediaType: 4)
                self.episodesCount = episodes.count
            }

        } catch {
            errorMessage = "Impossible de charger le contenu de la médiathèque: \(error.localizedDescription)"
        }
        isLoading = false
    }

    func posterURL(for item: MediaMetadata) -> URL? {
        guard let thumbPath = item.thumb,
              let serverID = serverViewModel.selectedServerID,
              let server = serverViewModel.availableServers.first(where: { $0.id == serverID }),
              let connection = server.connections.first(where: { !$0.local }) ?? server.connections.first,
              let token = authManager.getPlexAuthToken()
        else {
            return nil
        }

        let resourceToken = server.accessToken ?? token
        let urlString = "\(connection.uri)\(thumbPath)?X-Plex-Token=\(resourceToken)"
        return URL(string: urlString)
    }
}
