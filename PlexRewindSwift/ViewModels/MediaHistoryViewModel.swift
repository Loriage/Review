import Foundation

struct MediaHistoryItem: Identifiable {
    let id: String
    let session: WatchSession
    let userName: String?
}

@MainActor
class MediaHistoryViewModel: ObservableObject {
    @Published var historyItems: [MediaHistoryItem] = []
    @Published var summary: String?
    @Published var isLoading = true
    
    let session: PlexActivitySession
    
    private let plexService: PlexAPIService
    private let serverViewModel: ServerViewModel
    private let authManager: PlexAuthManager

    init(session: PlexActivitySession, plexService: PlexAPIService, serverViewModel: ServerViewModel, authManager: PlexAuthManager) {
        self.session = session
        self.plexService = plexService
        self.serverViewModel = serverViewModel
        self.authManager = authManager
    }

    func loadData() async {
        guard isLoading else { return }
        await fetchData()
    }

    func refreshData() async {
        await fetchData()
    }
    
    private func fetchData() async {
        self.isLoading = true
        
        guard let serverID = serverViewModel.selectedServerID,
              let server = serverViewModel.availableServers.first(where: { $0.id == serverID }),
              let connection = server.connections.first(where: { !$0.local }) ?? server.connections.first,
              let token = authManager.getPlexAuthToken()
        else {
            self.isLoading = false
            return
        }
        
        let serverURL = connection.uri
        let resourceToken = server.accessToken ?? token

        let fullHistory = try? await plexService.fetchWatchHistory(serverURL: serverURL, token: resourceToken, year: 0, userID: nil) { _ in }
        
        if serverViewModel.availableUsers.isEmpty {
            await serverViewModel.loadUsers(for: serverID)
        }
        
        let filteredSessions: [WatchSession]
        let ratingKeyForSummary: String?

        if session.type == "movie" {
            filteredSessions = fullHistory?.filter { $0.ratingKey == session.ratingKey } ?? []
            ratingKeyForSummary = session.ratingKey
        } else {
            filteredSessions = fullHistory?.filter { $0.grandparentTitle == session.grandparentTitle } ?? []
            ratingKeyForSummary = filteredSessions.first?.grandparentRatingKey
        }

        if let ratingKey = ratingKeyForSummary {
            self.summary = try? await plexService.fetchMediaDetails(for: ratingKey, serverURL: serverURL, token: resourceToken)?.summary
        }
        
        self.historyItems = filteredSessions.map { session in
            let userName = serverViewModel.availableUsers.first { $0.id == session.accountID }?.title
            return MediaHistoryItem(id: session.id, session: session, userName: userName)
        }

        self.isLoading = false
    }
}
