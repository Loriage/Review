import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var authManager: PlexAuthManager
    @EnvironmentObject var serverViewModel: ServerViewModel
    @StateObject private var viewModel: SettingsViewModel

    init(authManager: PlexAuthManager) {
        _viewModel = StateObject(wrappedValue: SettingsViewModel(authManager: authManager))
    }

    private var selectedServer: PlexResource? {
        serverViewModel.availableServers.first { $0.id == serverViewModel.selectedServerID }
    }
    
    var body: some View {
        NavigationStack {
            Form {
                if viewModel.isLoading {
                    ProgressView()
                } else if let account = viewModel.account {
                    Section(header: Text("Compte")) {
                        HStack(spacing: 10) {
                            AsyncImageView(url: URL(string: account.thumb ?? ""))
                                .frame(width: 50, height: 50)
                                .clipShape(Circle())

                            VStack(alignment: .leading) {
                                Text(account.username)
                                    .font(.headline)
                                if account.subscription?.active == true {
                                    HStack(spacing: 4) {
                                        Image(systemName: "ticket")
                                        Text("Plex Pass")
                                    }
                                    .font(.subheadline)
                                    .foregroundColor(.accentColor)
                                }
                            }
                        }
                    }
                }

                Section(header: Text("Serveur")) {
                    if let server = selectedServer {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(server.name)
                                .font(.headline)
                            Text("Version \(server.productVersion)")
                                .foregroundColor(.secondary)
                                .font(.subheadline)
                        }
                        NavigationLink("Détails du serveur") {
                            ServerDetailsView(server: server)
                        }
                    } else {
                        Text("Aucun serveur trouvé.")
                            .foregroundColor(.secondary)
                    }
                }

                Section {
                    Button("Se déconnecter", role: .destructive, action: authManager.logout)
                        .frame(maxWidth: .infinity, alignment: .center)
                }
            }
            .navigationTitle("Réglages")
            .navigationBarTitleDisplayMode(.inline)
            .task {
                await viewModel.loadAccountDetails()
            }
        }
    }
}
