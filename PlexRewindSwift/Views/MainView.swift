import SwiftUI

struct MainView: View {
    @StateObject private var authManager = PlexAuthManager()

    var body: some View {
        if authManager.isAuthenticated {
            AuthenticatedContentView(authManager: authManager)
        } else if authManager.pin != nil {
            LoginPinView()
                .environmentObject(authManager)
        } else {
            OnboardingView()
                .environmentObject(authManager)
        }
    }
}

struct AuthenticatedContentView: View {
    @ObservedObject var authManager: PlexAuthManager
    @StateObject private var serverViewModel: ServerViewModel
    @StateObject private var activityViewModel: ActivityViewModel
    @StateObject private var statsViewModel: StatsViewModel
    @StateObject private var topStatsViewModel: TopStatsViewModel

    init(authManager: PlexAuthManager) {
        self.authManager = authManager
        let serverVM = ServerViewModel(authManager: authManager)
        _serverViewModel = StateObject(wrappedValue: serverVM)
        
        _activityViewModel = StateObject(wrappedValue: ActivityViewModel(serverViewModel: serverVM))
        _statsViewModel = StateObject(wrappedValue: StatsViewModel(serverViewModel: serverVM))
        _topStatsViewModel = StateObject(wrappedValue: TopStatsViewModel(serverViewModel: serverVM, authManager: authManager))
    }

    var body: some View {
        MainTabView()
            .environmentObject(authManager)
            .environmentObject(serverViewModel)
            .environmentObject(activityViewModel)
            .environmentObject(statsViewModel)
            .environmentObject(topStatsViewModel)
            .task {
                await serverViewModel.loadServers()
            }
    }
}
