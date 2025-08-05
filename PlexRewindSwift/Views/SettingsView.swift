import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var authManager: PlexAuthManager
    @EnvironmentObject var viewModel: RewindViewModel
    
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Picker("Serveur Plex", selection: $viewModel.selectedServerID) {
                        Text("Choisissez un serveur...").tag(String?.none)
                        ForEach(viewModel.availableServers) { server in
                            Text(server.name).tag(server.id as String?)
                        }
                    }
                    .disabled(viewModel.availableServers.isEmpty)
                    .onChange(of: viewModel.selectedServerID) { _, newServerID in
                        if let serverID = newServerID {
                            Task {
                                await viewModel.loadUsers(
                                    for: serverID,
                                    authManager: authManager
                                )
                                print(viewModel.availableUsers)
                            }
                        }
                    }

                    Button(action: {
                        Task {
                            await viewModel.syncFullHistory(
                                authManager: authManager
                            )
                        }
                    }) {
                        Text(
                            viewModel.isHistorySynced
                            ? "Re-synchroniser l'historique"
                            : "Synchroniser l'historique complet"
                        )
                    }
                    .disabled(
                        viewModel.selectedServerID == nil || viewModel.isLoading
                    )
                }
                header: {
                    Text("Paramètres Plex")
                }
                footer: {
                    if let formattedDateText = viewModel.formattedLastSyncDate {
                        Text(formattedDateText)
                    }
                }
                
                Section(header: Text("Création du Rewind")) {
                    Picker("Année", selection: $viewModel.selectedYear) {
                        ForEach(viewModel.availableYears, id: \.self) { year in
                            Text(String(year)).tag(year)
                        }
                    }

                    if !viewModel.availableUsers.isEmpty {
                        Picker(
                            "Utilisateur",
                            selection: $viewModel.selectedUserID
                        ) {
                            Text("Tous les utilisateurs").tag(Int?.none)
                            ForEach(viewModel.availableUsers) { user in
                                Text(user.title).tag(user.id as Int?)
                            }
                        }
                    }

                    Button(action: {
                        Task {
                            await viewModel.generateRewind(authManager: authManager)
                        }
                    }) {
                        HStack {
                            Spacer()
                            if viewModel.isLoading && !viewModel.loadingStatusMessage.isEmpty {
                                Text(viewModel.loadingStatusMessage)
                                    .font(.footnote)
                                    .foregroundColor(.secondary)
                            } else {
                                Text("Générer le Rewind")
                            }
                            Spacer()
                        }
                    }
                }
                .disabled(!viewModel.isHistorySynced || viewModel.isLoading)
                
                Section {
                    Button("Se déconnecter", role: .destructive, action: authManager.logout)
                }
            }
            .navigationTitle("Réglages")
            .onAppear {
                viewModel.updateFormattedSyncDate()

                if viewModel.availableServers.isEmpty && !viewModel.isLoading {
                    Task {
                        await viewModel.loadServers(authManager: authManager)
                    }
                }
            }
        }
    }
}
