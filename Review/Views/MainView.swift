import SwiftUI

struct MainView: View {
    @StateObject private var authManager = PlexAuthManager()
    @EnvironmentObject var themeManager: ThemeManager

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
        .preferredColorScheme(mapThemeToColorScheme(themeManager.selectedTheme))
    }
    
    private func mapThemeToColorScheme(_ theme: Int) -> ColorScheme? {
        switch Theme(rawValue: theme) {
        case .light:
            return .light
        case .dark:
            return .dark
        default:
            return nil
        }
    }
}
