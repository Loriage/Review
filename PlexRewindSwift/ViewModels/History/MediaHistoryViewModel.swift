import Foundation

@MainActor
class MediaHistoryViewModel: ObservableObject {
    @Published var historyItems: [MediaHistoryItem] = []
    @Published var summary: String?
    @Published var isLoading = true

    @Published var session: PlexActivitySession
    @Published var imageRefreshId = UUID()

    var activityViewModel: ActivityViewModel?

    private let serverViewModel: ServerViewModel
    private let statsViewModel: StatsViewModel
    private let authManager: PlexAuthManager

    init(session: PlexActivitySession, serverViewModel: ServerViewModel, statsViewModel: StatsViewModel, authManager: PlexAuthManager) {
        self.session = session
        self.serverViewModel = serverViewModel
        self.statsViewModel = statsViewModel
        self.authManager = authManager
    }

    var displayPosterURL: URL? {
        let ratingKey = session.type == "episode" ? session.grandparentRatingKey : session.ratingKey
        
        guard let key = ratingKey,
              let serverID = serverViewModel.selectedServerID,
              let server = serverViewModel.availableServers.first(where: { $0.id == serverID }),
              let connection = server.connections.first(where: { !$0.local }) ?? server.connections.first,
              let token = authManager.getPlexAuthToken()
        else {
            return session.posterURL
        }
        
        let resourceToken = server.accessToken ?? token
        let urlString = "\(connection.uri)/library/metadata/\(key)/thumb?X-Plex-Token=\(resourceToken)"
        
        return URL(string: urlString)
    }

    func loadData() async {
        guard isLoading else { return }
        await fetchData()
    }

    func refreshData() async {
        await statsViewModel.syncFullHistory()
        await fetchData()
    }
    
    private func fetchData() async {
        let result = await statsViewModel.historyForMedia(session: self.session)
        let filteredSessions = result.sessions
        self.summary = result.summary
        
        if serverViewModel.availableUsers.isEmpty, let serverID = serverViewModel.selectedServerID {
            await serverViewModel.loadUsers(for: serverID)
        }
        
        self.historyItems = filteredSessions.map { session in
            let userName = serverViewModel.availableUsers.first { $0.id == session.accountID }?.title
            return MediaHistoryItem(id: session.id, session: session, userName: userName)
        }
        
        self.isLoading = false
    }

    func refreshSession() async {
        guard let activityViewModel = activityViewModel else { return }

        await activityViewModel.refreshActivity()

        if case .content(let sessions) = activityViewModel.state {
            if let updatedSession = sessions.first(where: { $0.id == self.session.id }) {
                self.session = updatedSession
                self.imageRefreshId = UUID()
            }
        }
    }
}
