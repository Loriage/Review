import SwiftUI

struct MainView: View {
    @StateObject private var authManager = PlexAuthManager()

    var body: some View {
        Group {
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
}
