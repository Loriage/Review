import SwiftUI

struct MainView: View {
    @StateObject private var authManager = PlexAuthManager()
    
    var body: some View {
        if authManager.isAuthenticated {
            let serverViewModel = ServerViewModel(authManager: authManager)
            let activityViewModel = ActivityViewModel(serverViewModel: serverViewModel)
            let statsViewModel = StatsViewModel(serverViewModel: serverViewModel)
            /*let topStatsViewModel = TopStatsViewModel(serverViewModel: serverViewModel, authManager: authManager)*/
            
            MainTabView()
                .environmentObject(authManager)
                .environmentObject(serverViewModel)
                .environmentObject(activityViewModel)
                .environmentObject(statsViewModel)
                /*.environmentObject(topStatsViewModel)*/
        } else if authManager.pin != nil {
            LoginPinView()
                .environmentObject(authManager)
        } else {
            OnboardingView()
                .environmentObject(authManager)
        }
    }
}
