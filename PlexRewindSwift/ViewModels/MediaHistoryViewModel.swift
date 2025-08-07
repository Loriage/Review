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

    @Published var session: PlexActivitySession

    var activityViewModel: ActivityViewModel?

    private let serverViewModel: ServerViewModel
    private let statsViewModel: StatsViewModel

    init(session: PlexActivitySession, serverViewModel: ServerViewModel, statsViewModel: StatsViewModel) {
        self.session = session
        self.serverViewModel = serverViewModel
        self.statsViewModel = statsViewModel
    }

    func loadData() async {
        guard isLoading else { return }
        await fetchData()
    }

    func refreshData() async {
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
            }
        }
    }
}
