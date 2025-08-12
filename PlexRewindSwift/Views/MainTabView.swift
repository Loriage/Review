import SwiftUI

struct MainTabView: View {
    @EnvironmentObject var activityViewModel: ActivityViewModel
    @EnvironmentObject var statsViewModel: StatsViewModel
    @EnvironmentObject var serverViewModel: ServerViewModel
    @EnvironmentObject var authManager: PlexAuthManager
    @EnvironmentObject var topStatsViewModel: TopStatsViewModel

    init() {
        let tabBarAppearance = UITabBarAppearance()
        let itemAppearance = UITabBarItemAppearance()

        itemAppearance.normal.badgeBackgroundColor = .accent
        tabBarAppearance.stackedLayoutAppearance = itemAppearance
        UITabBar.appearance().standardAppearance = tabBarAppearance
        UITabBar.appearance().scrollEdgeAppearance = tabBarAppearance
    }

    var body: some View {
        TabView {
            Tab("Activité", systemImage: "play.circle") {
                ActivityView()
                    .environmentObject(activityViewModel)
                    .environmentObject(statsViewModel)
            }
            .badge(activityViewModel.activityCount)

            Tab("Médias", systemImage: "books.vertical.fill") {
                LibraryView(serverViewModel: serverViewModel, authManager: authManager)
            }

            Tab("Search", systemImage: "magnifyingglass", role: .search) {
                    SearchView()
            }

            Tab("Stats", systemImage: "list.number") {
                TopStatsView()
                    .environmentObject(topStatsViewModel)
            }
        }
    }
}
