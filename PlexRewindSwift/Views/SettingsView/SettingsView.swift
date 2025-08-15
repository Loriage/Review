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
                    Section(header: Text("settings.account.section.title")) {
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

                Section(header: Text("settings.server.section.title")) {
                    if let server = selectedServer {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(server.name)
                                .font(.headline)
                            Text("settings.server.version \(server.productVersion)")
                                .foregroundColor(.secondary)
                                .font(.subheadline)
                        }
                        NavigationLink("settings.server.details.button") {
                            ServerDetailsView(server: server)
                        }
                    } else {
                        Text("settings.server.no.server.found")
                            .foregroundColor(.secondary)
                    }
                }

                Section {
                    Button("settings.button.logout", role: .destructive, action: authManager.logout)
                        .frame(maxWidth: .infinity, alignment: .center)
                }
            }
            .navigationTitle("settings.title")
            .navigationBarTitleDisplayMode(.inline)
            .task {
                await viewModel.loadAccountDetails()
            }
        }
    }
}
