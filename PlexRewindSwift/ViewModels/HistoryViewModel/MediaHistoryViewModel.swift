import Foundation
import SwiftUI

@MainActor
class MediaHistoryViewModel: ObservableObject {
    @Published var historyItems: [MediaHistoryItem] = []
    @Published var isLoading = true
    @Published var mediaDetails: MetadataItem?
    @Published var imageRefreshId = UUID()
    @Published var seasons: [PlexSeason] = []

    let ratingKey: String
    let mediaType: String
    let grandparentRatingKey: String?
    
    let serverViewModel: ServerViewModel
    let statsViewModel: StatsViewModel
    let authManager: PlexAuthManager
    private let metadataService: PlexMetadataService
    
    init(ratingKey: String, mediaType: String, grandparentRatingKey: String?, serverViewModel: ServerViewModel, statsViewModel: StatsViewModel, authManager: PlexAuthManager) {
        self.ratingKey = ratingKey
        self.mediaType = mediaType
        self.grandparentRatingKey = grandparentRatingKey
        self.serverViewModel = serverViewModel
        self.statsViewModel = statsViewModel
        self.authManager = authManager
        self.metadataService = PlexMetadataService()
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
        guard let serverDetails = getServerDetails(),
              let thumbPath = mediaDetails?.thumb ?? mediaDetails?.grandparentThumb
        else {
            return nil
        }
        return URL(string: "\(serverDetails.url)\(thumbPath)?X-Plex-Token=\(serverDetails.token)")
    }
    
    func seasonPosterURL(for season: PlexSeason) -> URL? {
        guard let path = season.thumb, let serverDetails = getServerDetails() else { return nil }
        let urlString = "\(serverDetails.url)\(path)?X-Plex-Token=\(serverDetails.token)"
        return URL(string: urlString)
    }

    var summary: String? {
        return mediaDetails?.summary
    }

    func loadData() async {
        guard isLoading else { return }

        await withTaskGroup(of: Void.self) { group in
            group.addTask { await self.fetchMediaDetails() }
            group.addTask { await self.fetchHistory() }
            if mediaType == "show" || mediaType == "episode" {
                group.addTask { await self.fetchSeasons() }
            }
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
    
    private func fetchSeasons() async {
        guard let serverDetails = getServerDetails(),
              let showRatingKey = grandparentRatingKey ?? (mediaType == "show" ? ratingKey : nil)
        else {
            return
        }
        do {
            self.seasons = try await metadataService.fetchSeasons(for: showRatingKey, serverURL: serverDetails.url, token: serverDetails.token)
        } catch {
            print("Failed to fetch seasons: \(error)")
        }
    }

    private func fetchMediaDetails() async {
        guard let serverDetails = getServerDetails()
        else { return }
        
        let keyForDetails = (mediaType == "episode" || mediaType == "show") ? (grandparentRatingKey ?? ratingKey) : ratingKey
        
        do {
            self.mediaDetails = try await metadataService.fetchMediaDetails(for: keyForDetails, serverURL: serverDetails.url, token: serverDetails.token)
        } catch {
        }
    }

    private func fetchHistory() async {
        let result = await statsViewModel.historyForMedia(ratingKey: self.ratingKey, mediaType: self.mediaType, grandparentRatingKey: self.grandparentRatingKey)
        
        if serverViewModel.availableUsers.isEmpty, let serverID = serverViewModel.selectedServerID {
            await serverViewModel.loadUsers(for: serverID)
        }
        
        self.historyItems = result.sessions.map { session in
            let user = serverViewModel.availableUsers.first { $0.id == session.accountID }
            let userName = user?.title
            var userThumbURL: URL?
            if let thumbString = user?.thumb {
                userThumbURL = URL(string: thumbString)
            }
            return MediaHistoryItem(id: session.id, session: session, userName: userName, userThumbURL: userThumbURL)
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
