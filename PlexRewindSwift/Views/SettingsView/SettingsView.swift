import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var authManager: PlexAuthManager
    @EnvironmentObject var serverViewModel: ServerViewModel
    @EnvironmentObject var statsViewModel: StatsViewModel

    var body: some View {
        NavigationStack {
            Form {
                ServerSelectionSection()
                HistorySyncSection()
                
                Section {
                    Button("Se déconnecter", role: .destructive, action: authManager.logout)
                }
            }
            .navigationTitle("Réglages")
            .navigationBarTitleDisplayMode(.inline)
            .onAppear {
                if serverViewModel.availableServers.isEmpty && !serverViewModel.isLoading {
                    Task {
                        await serverViewModel.loadServers()
                    }
                }
            }
        }
    }
}
