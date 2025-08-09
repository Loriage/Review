import Foundation
import SwiftUI

@MainActor
class MediaHistoryViewModel: ObservableObject {
    @Published var historyItems: [MediaHistoryItem] = []
    @Published var isLoading = true
    @Published var representativeSession: WatchSession?
    @Published var summary: String?
    @Published var imageRefreshId = UUID()

    let ratingKey: String
    let mediaType: String
    let grandparentRatingKey: String?
    
    private let serverViewModel: ServerViewModel
    private let statsViewModel: StatsViewModel
    private let authManager: PlexAuthManager
    
    init(ratingKey: String, mediaType: String, grandparentRatingKey: String?, serverViewModel: ServerViewModel, statsViewModel: StatsViewModel, authManager: PlexAuthManager) {
        self.ratingKey = ratingKey
        self.mediaType = mediaType
        self.grandparentRatingKey = grandparentRatingKey
        self.serverViewModel = serverViewModel
        self.statsViewModel = statsViewModel
        self.authManager = authManager
    }

    var displayTitle: String {
        guard let session = representativeSession else { return "Chargement..." }
        return (mediaType == "movie") ? (session.title ?? "Film inconnu") : (session.grandparentTitle ?? "Série inconnue")
    }

    var ratingKeyForActions: String {
        if mediaType == "episode" || mediaType == "show" {
            return representativeSession?.grandparentRatingKey ?? grandparentRatingKey ?? ratingKey
        }
        return representativeSession?.ratingKey ?? ratingKey
    }

    var displayPosterURL: URL? {
        guard let session = representativeSession,
              let serverID = serverViewModel.selectedServerID,
              let server = serverViewModel.availableServers.first(where: { $0.id == serverID }),
              let connection = server.connections.first(where: { !$0.local }) ?? server.connections.first,
              let token = authManager.getPlexAuthToken()
        else {
            return nil
        }
        
        let thumbPath = (mediaType == "episode" || mediaType == "show") ? session.grandparentThumb : session.thumb
        guard let path = thumbPath else { return nil }
        
        let resourceToken = server.accessToken ?? token
        return URL(string: "\(connection.uri)\(path)?X-Plex-Token=\(resourceToken)")
    }

    func loadData() async {
        guard isLoading else { return }

        let result = await statsViewModel.historyForMedia(ratingKey: self.ratingKey, mediaType: self.mediaType, grandparentRatingKey: self.grandparentRatingKey)
        let sessions = result.sessions
        self.summary = result.summary
        
        if let firstSession = sessions.first {
            self.representativeSession = firstSession
        }
        
        if serverViewModel.availableUsers.isEmpty, let serverID = serverViewModel.selectedServerID {
            await serverViewModel.loadUsers(for: serverID)
        }
        
        self.historyItems = sessions.map { session in
            let userName = serverViewModel.availableUsers.first { $0.id == session.accountID }?.title
            return MediaHistoryItem(id: session.id, session: session, userName: userName)
        }
        
        self.isLoading = false
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
    }
}
