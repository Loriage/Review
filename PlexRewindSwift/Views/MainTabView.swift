import SwiftUI

struct MainTabView: View {
    @StateObject private var viewModel = RewindViewModel()
    
    var body: some View {
        TabView {
            RewindView()
                .tabItem {
                    Label("Rewind", systemImage: "play.rectangle.fill")
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
