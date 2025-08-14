import Foundation
import SwiftUI

@MainActor
class EpisodeHistoryViewModel: ObservableObject {
    @Published var historyItems: [MediaHistoryItem] = []
    @Published var isLoading = true
    @Published var episodeDetails: MetadataItem?
    @Published var imageRefreshId = UUID()

    let episode: PlexEpisode
    let showRatingKey: String
    
    let serverViewModel: ServerViewModel
    let statsViewModel: StatsViewModel
    let authManager: PlexAuthManager
    private let metadataService: PlexMetadataService
    
    init(episode: PlexEpisode, showRatingKey: String, serverViewModel: ServerViewModel, statsViewModel: StatsViewModel, authManager: PlexAuthManager) {
        self.episode = episode
        self.showRatingKey = showRatingKey
        self.serverViewModel = serverViewModel
        self.statsViewModel = statsViewModel
        self.authManager = authManager
        self.metadataService = PlexMetadataService()
    }

    var ratingKeyForActions: String {
        return episode.ratingKey
    }

    var displayTitle: String {
        return episodeDetails?.title ?? episode.title
    }

    var displayPosterURL: URL? {
        guard let serverDetails = getServerDetails(),
              let thumbPath = episodeDetails?.thumb
        else {
            return nil
        }
        return URL(string: "\(serverDetails.url)\(thumbPath)?X-Plex-Token=\(serverDetails.token)")
    }

    var summary: String? {
        return episodeDetails?.summary
    }

    func loadData() async {
        guard isLoading else { return }

        await withTaskGroup(of: Void.self) { group in
            group.addTask { await self.fetchEpisodeDetails() }
            group.addTask { await self.fetchHistory() }
        }

        self.isLoading = false
    }
    
    private func getServerDetails() -> (url: String, token: String)? {
        guard let serverID = serverViewModel.selectedServerID,
              let server = serverViewModel.availableServers.first(where: { $0.id == serverID }),
              let connection = server.connections.first(where: { !$0.local }) ?? server.connections.first,
              let token = authManager.getPlexAuthToken()
        else { return nil }
        let resourceToken = server.accessToken ?? token
        return (url: connection.uri, token: resourceToken)
    }

    private func fetchEpisodeDetails() async {
        guard let serverDetails = getServerDetails() else { return }
        do {
            self.episodeDetails = try await metadataService.fetchMediaDetails(for: episode.ratingKey, serverURL: serverDetails.url, token: serverDetails.token)
        } catch {
             print("Failed to fetch episode details: \(error)")
        }
    }

    private func fetchHistory() async {
        let (sessions, _) = await statsViewModel.historyForMedia(ratingKey: episode.ratingKey, mediaType: "episode", grandparentRatingKey: showRatingKey)
        
        if serverViewModel.availableUsers.isEmpty, let serverID = serverViewModel.selectedServerID {
            await serverViewModel.loadUsers(for: serverID)
        }
        
        self.historyItems = sessions.map { session in
            let user = serverViewModel.availableUsers.first { $0.id == session.accountID }
            let userName = user?.title
            var userThumbURL: URL?
            if let thumbString = user?.thumb {
                userThumbURL = URL(string: thumbString)
            }
            return MediaHistoryItem(id: session.id, session: session, userName: userName, userThumbURL: userThumbURL)
        }
    }

    func refreshSessionDetails() async {
        if let url = displayPosterURL {
            ImageCache.shared.invalidate(url: url)
        }
        self.imageRefreshId = UUID()
        await fetchEpisodeDetails()
    }
}
