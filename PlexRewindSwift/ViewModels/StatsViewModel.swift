import Foundation

@MainActor
class StatsViewModel: ObservableObject {
    
    @Published var isHistorySynced = false
    @Published var isLoading = false
    @Published var loadingStatusMessage = ""
    @Published var errorMessage: String?
    @Published var lastSyncDate: Date?
    @Published var formattedLastSyncDate: String?
    
    // Propriétés pour l'ancienne vue Rewind - SUPPRIMÉES
    // @Published var userStats: UserStats?
    // @Published var selectedUserID: Int?
    // @Published var selectedYear: Int? = nil
    // @Published var availableYears: [Int] = []
    // @Published var selectedSortOption: SortOption = .byPlays
    // @Published var selectedMediaDetail: MediaDetail?
    
    private let serverViewModel: ServerViewModel
    private let activityService: PlexActivityService
    private let metadataService: PlexMetadataService
    private var fullHistory: [WatchSession] = []
    
    init(serverViewModel: ServerViewModel, activityService: PlexActivityService = PlexActivityService(), metadataService: PlexMetadataService = PlexMetadataService()) {
        self.serverViewModel = serverViewModel
        self.activityService = activityService
        self.metadataService = metadataService
    }
    
    func updateFormattedSyncDate() {
        if let date = lastSyncDate {
            self.formattedLastSyncDate = "Dernière synchro : \(date.formatted(.relative(presentation: .named)))"
        } else {
            self.formattedLastSyncDate = nil
        }
    }

    func syncFullHistory() async {
        guard let serverID = serverViewModel.selectedServerID,
              let server = serverViewModel.availableServers.first(where: { $0.id == serverID }),
              let connection = server.connections.first(where: { !$0.local }) ?? server.connections.first,
              let token = serverViewModel.authManager.getPlexAuthToken()
        else {
            errorMessage = "Veuillez sélectionner un serveur valide."
            return
        }
        
        isLoading = true
        isHistorySynced = false
        loadingStatusMessage = "Analyse de votre historique complet..."

        do {
            let serverURL = connection.uri
            let resourceToken = server.accessToken ?? token
            
            self.fullHistory = try await activityService.fetchWatchHistory(serverURL: serverURL, token: resourceToken, year: 0, userID: nil) { count in
                await MainActor.run {
                    self.loadingStatusMessage = "Analyse de \(count) visionnages..."
                }
            }
            
            self.isHistorySynced = !self.fullHistory.isEmpty
            if self.isHistorySynced {
                self.lastSyncDate = Date()
                updateFormattedSyncDate()
            }
            
        } catch {
            errorMessage = "Impossible de récupérer l'historique. \(error.localizedDescription)"
        }
        isLoading = false
        loadingStatusMessage = ""
    }

    func historyForMedia(ratingKey: String, mediaType: String, grandparentRatingKey: String?) async -> (sessions: [WatchSession], summary: String?) {
        if !isHistorySynced {
            await syncFullHistory()
        }
        
        guard let serverID = serverViewModel.selectedServerID,
              let server = serverViewModel.availableServers.first(where: { $0.id == serverID }),
              let connection = server.connections.first(where: { !$0.local }) ?? server.connections.first,
              let token = serverViewModel.authManager.getPlexAuthToken()
        else {
            return ([], nil)
        }
        
        let serverURL = connection.uri
        let resourceToken = server.accessToken ?? token
        
        var filteredSessions: [WatchSession] = []
        var summary: String? = nil
        var ratingKeyForSummary: String?

        ratingKeyForSummary = ratingKey
        
        if mediaType == "movie" {
            let representativeSession = fullHistory.first { $0.ratingKey == ratingKey }
            if let movieTitle = representativeSession?.title, !movieTitle.isEmpty {
                filteredSessions = fullHistory.filter { $0.title == movieTitle && $0.type == "movie" }
            }
        } else if mediaType == "episode" {
            if let gprk = grandparentRatingKey {
                filteredSessions = fullHistory.filter { $0.computedGrandparentRatingKey == gprk }
            }
            if filteredSessions.isEmpty {
                let representativeSession = fullHistory.first { $0.ratingKey == ratingKey }
                if let showTitle = representativeSession?.grandparentTitle, !showTitle.isEmpty {
                    filteredSessions = fullHistory.filter { $0.grandparentTitle == showTitle }
                }
            }
            ratingKeyForSummary = grandparentRatingKey
            
        } else if mediaType == "show" {
            filteredSessions = fullHistory.filter { $0.computedGrandparentRatingKey == ratingKey }
            ratingKeyForSummary = ratingKey
        }
        
        if let finalRatingKey = grandparentRatingKey ?? ratingKeyForSummary {
            let details = try? await metadataService.fetchMediaDetails(for: finalRatingKey, serverURL: serverURL, token: resourceToken)
            summary = details?.summary
        }
        
        return (filteredSessions.sorted(by: { ($0.viewedAt ?? 0) > ($1.viewedAt ?? 0) }), summary)
    }

    func historyForUser(userID: Int) async -> [WatchSession] {
        if !isHistorySynced {
            await syncFullHistory()
        }
        guard userID != 0 else { return [] }
        return fullHistory.filter { $0.accountID == userID }
    }
}
