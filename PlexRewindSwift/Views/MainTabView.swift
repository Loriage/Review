import SwiftUI

struct MainTabView: View {
    @StateObject var viewModel: PlexMonitorViewModel

    var body: some View {
        TabView {
            ActivityView()
                .tabItem {
                    Label("Activité", systemImage: "play.display")
                }
                .environmentObject(viewModel)

            RewindView()
                .tabItem {
                    Label("Stats", systemImage: "chart.bar.xaxis")
                }
                .environmentObject(viewModel)

            SettingsView()
                .tabItem {
                    Label("Réglages", systemImage: "gear")
                }
                .environmentObject(viewModel)
        }
    }
}
