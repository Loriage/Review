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
        
        let libraryService = PlexLibraryService()
        let userService = PlexUserService()
        let activityService = PlexActivityService()
        let metadataService = PlexMetadataService()

        let serverVM = ServerViewModel(authManager: authManager, libraryService: libraryService, userService: userService)
        _serverViewModel = StateObject(wrappedValue: serverVM)
        
        _activityViewModel = StateObject(wrappedValue: ActivityViewModel(serverViewModel: serverVM, activityService: activityService))
        _statsViewModel = StateObject(wrappedValue: StatsViewModel(serverViewModel: serverVM, activityService: activityService, metadataService: metadataService))
        _topStatsViewModel = StateObject(wrappedValue: TopStatsViewModel(serverViewModel: serverVM, authManager: authManager, activityService: activityService, metadataService: metadataService))
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
