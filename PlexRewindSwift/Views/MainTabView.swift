import SwiftUI

struct MainTabView: View {
    @EnvironmentObject var activityViewModel: ActivityViewModel
    @EnvironmentObject var statsViewModel: StatsViewModel
    @EnvironmentObject var serverViewModel: ServerViewModel
    @EnvironmentObject var authManager: PlexAuthManager
    @EnvironmentObject var topStatsViewModel: TopStatsViewModel

    var body: some View {
        TabView {
            ActivityView()
                .tabItem {
                    Label("Activité", systemImage: "play.display")
                }
                .environmentObject(activityViewModel)
                .environmentObject(statsViewModel)

            LibraryView(serverViewModel: serverViewModel, authManager: authManager)
                .tabItem {
                    Label("Bibliothèques", systemImage: "books.vertical.fill")
                }
            TopStatsView()
                .tabItem {
                    Label("Top Stats", systemImage: "star.fill")
                }
                .environmentObject(topStatsViewModel)

            StatsView()
                .tabItem {
                    Label("Stats", systemImage: "chart.bar.xaxis")
                }
                .environmentObject(statsViewModel)

            SettingsView()
                .tabItem {
                    Label("Réglages", systemImage: "gear")
                }
                .environmentObject(serverViewModel)
                .environmentObject(statsViewModel)
        }
    }
}
