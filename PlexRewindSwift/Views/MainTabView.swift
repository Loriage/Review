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
        itemAppearance.normal.badgeTextAttributes = [
            .foregroundColor: UIColor.white
        ]

        itemAppearance.selected.badgeBackgroundColor = .systemGray

        itemAppearance.normal.badgePositionAdjustment = UIOffset(horizontal: 2, vertical: 0)
        itemAppearance.selected.badgePositionAdjustment = UIOffset(horizontal: 2, vertical: 0)

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

            Tab("Bibliothèques", systemImage: "books.vertical.fill") {
                LibraryView(serverViewModel: serverViewModel, authManager: authManager)
            }

            Tab("Recherche", systemImage: "magnifyingglass", role: .search) {
                SearchView(serverViewModel: serverViewModel, authManager: authManager, statsViewModel: statsViewModel)
            }

            Tab("Stats", systemImage: "list.number") {
                TopStatsView()
                    .environmentObject(topStatsViewModel)
            }
        }
    }
}
