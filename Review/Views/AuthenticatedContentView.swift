import SwiftUI

struct AuthenticatedContentView: View {
    @ObservedObject var authManager: PlexAuthManager

    @StateObject private var serverViewModel: ServerViewModel
    @StateObject private var activityViewModel: ActivityViewModel
    @StateObject private var statsViewModel: StatsViewModel
    @StateObject private var topStatsViewModel: TopStatsViewModel
    @StateObject private var searchViewModel: SearchViewModel

    init(authManager: PlexAuthManager) {
        self.authManager = authManager
        
        let serverVM = ServerViewModel(authManager: authManager)
        let statsVM = StatsViewModel(serverViewModel: serverVM)

        _serverViewModel = StateObject(wrappedValue: serverVM)
        _activityViewModel = StateObject(wrappedValue: ActivityViewModel(serverViewModel: serverVM, authManager: authManager))
        _statsViewModel = StateObject(wrappedValue: statsVM)
        _topStatsViewModel = StateObject(wrappedValue: TopStatsViewModel(serverViewModel: serverVM, authManager: authManager))
        _searchViewModel = StateObject(wrappedValue: SearchViewModel(serverViewModel: serverVM, authManager: authManager))
    }

    var body: some View {
        MainTabView()
            .environmentObject(authManager)
            .environmentObject(serverViewModel)
            .environmentObject(activityViewModel)
            .environmentObject(statsViewModel)
            .environmentObject(topStatsViewModel)
            .environmentObject(searchViewModel)
            .task {
                await serverViewModel.loadServers()
            }
    }
}
