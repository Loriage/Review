import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var authManager: PlexAuthManager
    @EnvironmentObject var viewModel: PlexMonitorViewModel

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
                            .textCase(nil)
                    }
                }

                Section(
                    header: Text("Création du Rewind"),
                    footer: Text(
                        "La génération du Rewind peut prendre du temps car elle récupère la durée de chaque film et épisode individuellement."
                    )
                    .textCase(nil)
                ) {
                    Picker("Trier par", selection: $viewModel.selectedSortOption) {
                        ForEach(SortOption.allCases) { option in
                            Text(option.rawValue).tag(option)
                        }
                    }

                    Picker("Période", selection: $viewModel.selectedYear) {
                        Text("Toutes").tag(Int?.none)
                        ForEach(viewModel.availableYears, id: \.self) { year in
                            Text(String(year)).tag(year as Int?)
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
                            await viewModel.generateRewind(
                                authManager: authManager
                            )
                        }
                    }) {
                        HStack {
                            Spacer()
                            if viewModel.isLoading
                                && !viewModel.loadingStatusMessage.isEmpty
                            {
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
                    Button(
                        "Se déconnecter",
                        role: .destructive,
                        action: authManager.logout
                    )
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
