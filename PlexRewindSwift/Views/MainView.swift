import SwiftUI

struct MainView: View {
    @StateObject private var authManager = PlexAuthManager()
    
    var body: some View {
        if authManager.isAuthenticated {
            MainTabView()
                .environmentObject(authManager)
        }
        else if authManager.pin != nil {
            LoginPinView()
                .environmentObject(authManager)
        }
        else {
            OnboardingView()
                .environmentObject(authManager)
        }
    }
}
