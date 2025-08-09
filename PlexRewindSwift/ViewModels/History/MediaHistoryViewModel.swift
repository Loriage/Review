import Foundation
import SwiftUI

@MainActor
class MediaHistoryViewModel: ObservableObject {
    @Published var historyItems: [MediaHistoryItem] = []
    @Published var isLoading = true
    @Published var mediaDetails: MetadataItem?
    @Published var imageRefreshId = UUID()

    let ratingKey: String
    let mediaType: String
    let grandparentRatingKey: String?
    
    private let serverViewModel: ServerViewModel
    private let statsViewModel: StatsViewModel
    private let authManager: PlexAuthManager
    private let plexService: PlexAPIService
    
    init(ratingKey: String, mediaType: String, grandparentRatingKey: String?, serverViewModel: ServerViewModel, statsViewModel: StatsViewModel, authManager: PlexAuthManager) {
        self.ratingKey = ratingKey
        self.mediaType = mediaType
        self.grandparentRatingKey = grandparentRatingKey
        self.serverViewModel = serverViewModel
        self.statsViewModel = statsViewModel
        self.authManager = authManager
        self.plexService = PlexAPIService()
    }

    var displayTitle: String {
        return mediaDetails?.title ?? (mediaType == "movie" ? "Film inconnu" : "Série inconnue")
    }

    var ratingKeyForActions: String {
        if mediaType == "show" {
            return ratingKey
        }
        return mediaDetails?.grandparentRatingKey ?? grandparentRatingKey ?? ratingKey
    }

    var displayPosterURL: URL? {
        guard let serverID = serverViewModel.selectedServerID,
              let server = serverViewModel.availableServers.first(where: { $0.id == serverID }),
              let connection = server.connections.first(where: { !$0.local }) ?? server.connections.first,
              let token = authManager.getPlexAuthToken(),
              let thumbPath = mediaDetails?.thumb ?? mediaDetails?.grandparentThumb
        else {
            return nil
        }
        
        let resourceToken = server.accessToken ?? token
        return URL(string: "\(connection.uri)\(thumbPath)?X-Plex-Token=\(resourceToken)")
    }

    var summary: String? {
        return mediaDetails?.summary
    }

    func loadData() async {
        guard isLoading else { return }

        await withTaskGroup(of: Void.self) { group in
            group.addTask { await self.fetchMediaDetails() }
            group.addTask { await self.fetchHistory() }
        }
        
        self.isLoading = false
    }
    
    private func fetchMediaDetails() async {
        guard let serverID = serverViewModel.selectedServerID,
              let server = serverViewModel.availableServers.first(where: { $0.id == serverID }),
              let connection = server.connections.first(where: { !$0.local }) ?? server.connections.first,
              let token = authManager.getPlexAuthToken()
        else { return }
        
        let keyForDetails = (mediaType == "episode" || mediaType == "show") ? (grandparentRatingKey ?? ratingKey) : ratingKey
        
        do {
            self.mediaDetails = try await plexService.fetchMediaDetails(for: keyForDetails, serverURL: connection.uri, token: server.accessToken ?? token)
        } catch {
            print("Erreur lors de la récupération des détails du média : \(error)")
        }
    }

    private func fetchHistory() async {
        let result = await statsViewModel.historyForMedia(ratingKey: self.ratingKey, mediaType: self.mediaType, grandparentRatingKey: self.grandparentRatingKey)
        
        if serverViewModel.availableUsers.isEmpty, let serverID = serverViewModel.selectedServerID {
            await serverViewModel.loadUsers(for: serverID)
        }
        
        self.historyItems = result.sessions.map { session in
            let userName = serverViewModel.availableUsers.first { $0.id == session.accountID }?.title
            return MediaHistoryItem(id: session.id, session: session, userName: userName)
        }
    }

    func refreshData() async {
        await statsViewModel.syncFullHistory()
        await loadData()
    }

    func refreshSessionDetails() async {
        if let url = displayPosterURL {
            ImageCache.shared.invalidate(url: url)
        }
        self.imageRefreshId = UUID()
        await fetchMediaDetails()
    }
}
