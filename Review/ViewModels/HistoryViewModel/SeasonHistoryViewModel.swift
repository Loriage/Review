import Foundation
import SwiftUI

@MainActor
class SeasonHistoryViewModel: ObservableObject {
    @Published var episodes: [PlexEpisode] = []
    @Published var isLoading = true
    @Published var seasonDetails: MetadataItem?
    @Published var historyItems: [MediaHistoryItem] = []

    let season: PlexSeason
    let showRatingKey: String
    private let serverViewModel: ServerViewModel
    private let authManager: PlexAuthManager
    private let statsViewModel: StatsViewModel
    private let metadataService: PlexMetadataService

    init(season: PlexSeason, showRatingKey: String, serverViewModel: ServerViewModel, authManager: PlexAuthManager, statsViewModel: StatsViewModel) {
        self.season = season
        self.showRatingKey = showRatingKey
        self.serverViewModel = serverViewModel
        self.authManager = authManager
        self.statsViewModel = statsViewModel
        self.metadataService = PlexMetadataService()
    }

    var seasonPosterURL: URL? {
        guard let path = season.thumb, let serverDetails = getServerDetails() else { return nil }
        return URL(string: "\(serverDetails.url)\(path)?X-Plex-Token=\(serverDetails.token)")
    }
    
    func loadData() async {
        isLoading = true
        await withTaskGroup(of: Void.self) { group in
            group.addTask { await self.fetchEpisodes() }
            group.addTask { await self.fetchSeasonDetails() }
        }
        await fetchHistory()
        isLoading = false
    }
    
    private func fetchEpisodes() async {
        guard let serverDetails = getServerDetails() else { return }
        do {
            episodes = try await metadataService.fetchEpisodes(for: season.ratingKey, serverURL: serverDetails.url, token: serverDetails.token)
        } catch {
            print("Failed to fetch episodes: \(error)")
        }
    }
    
    private func fetchSeasonDetails() async {
        guard let serverDetails = getServerDetails() else { return }
        let (seasonDetailsResult, showDetailsResult) = await (
            try? metadataService.fetchMediaDetails(for: season.ratingKey, serverURL: serverDetails.url, token: serverDetails.token),
            try? metadataService.fetchMediaDetails(for: showRatingKey, serverURL: serverDetails.url, token: serverDetails.token)
        )

        var combinedDetails = seasonDetailsResult
        if let showDetails = showDetailsResult {
            combinedDetails?.genre = showDetails.genre
            combinedDetails?.director = showDetails.director
            combinedDetails?.writer = showDetails.writer
            combinedDetails?.role = showDetails.role
            combinedDetails?.studio = showDetails.studio
        }
        self.seasonDetails = combinedDetails ?? nil
    }

    private func fetchHistory() async {
        let (sessions, _) = await statsViewModel.historyForMedia(ratingKey: showRatingKey, mediaType: "show", grandparentRatingKey: showRatingKey)
        let episodeRatingKeys = Set(episodes.map { $0.ratingKey })
        
        let seasonSessions = sessions.filter { session in
            guard let ratingKey = session.ratingKey else { return false }
            return episodeRatingKeys.contains(ratingKey)
        }
        
        self.historyItems = seasonSessions.map { session in
            let user = serverViewModel.availableUsers.first { $0.id == session.accountID }
            let userName = user?.title
            var userThumbURL: URL?
            if let thumbString = user?.thumb {
                userThumbURL = URL(string: thumbString)
            }
            return MediaHistoryItem(id: session.id, session: session, userName: userName, userThumbURL: userThumbURL)
        }
    }
    
    func episodePosterURL(for episode: PlexEpisode) -> URL? {
        guard let path = episode.thumb, let serverDetails = getServerDetails() else { return nil }
        return URL(string: "\(serverDetails.url)\(path)?X-Plex-Token=\(serverDetails.token)")
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
}
