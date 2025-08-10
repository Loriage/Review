import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var authManager: PlexAuthManager
    @EnvironmentObject var serverViewModel: ServerViewModel
    @EnvironmentObject var statsViewModel: StatsViewModel

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    if serverViewModel.isLoading {
                        ProgressView()
                    }
                    Picker("Serveur Plex", selection: $serverViewModel.selectedServerID) {
                        Text("Choisissez un serveur...").tag(String?.none)
                        ForEach(serverViewModel.availableServers) { server in
                            Text(server.name).tag(server.id as String?)
                        }
                    }
                    .disabled(serverViewModel.availableServers.isEmpty)
                }
                header: {
                    Text("Paramètres Plex")
                }

                Section(
                    header: Text("Création du Rewind"),
                    footer: Text("La génération du Rewind peut prendre du temps car elle récupère la durée de chaque film et épisode individuellement.").textCase(nil)
                ) {
                    Button(action: {
                        Task {
                            await statsViewModel.syncFullHistory()
                        }
                    }) {
                        Text(statsViewModel.isHistorySynced ? "Re-synchroniser l'historique" : "Synchroniser l'historique complet")
                    }
                    .disabled(serverViewModel.selectedServerID == nil || statsViewModel.isLoading)
                    
                    if let formattedDateText = statsViewModel.formattedLastSyncDate {
                        Text(formattedDateText).textCase(nil)
                    }

                    if statsViewModel.isHistorySynced {
                        Picker("Trier par", selection: $statsViewModel.selectedSortOption) {
                            ForEach(SortOption.allCases) { option in
                                Text(option.rawValue).tag(option)
                            }
                        }

                        Picker("Période", selection: $statsViewModel.selectedYear) {
                            Text("Toutes").tag(Int?.none)
                            ForEach(statsViewModel.availableYears, id: \.self) { year in
                                Text(String(year)).tag(year as Int?)
                            }
                        }
                        
                        if !serverViewModel.availableUsers.isEmpty {
                            Picker("Utilisateur", selection: $statsViewModel.selectedUserID) {
                                Text("Tous les utilisateurs").tag(Int?.none)
                                ForEach(serverViewModel.availableUsers) { user in
                                    Text(user.title).tag(user.id as Int?)
                                }
                            }
                        }

                        Button(action: {
                            Task {
                                await statsViewModel.generateRewind()
                            }
                        }) {
                            HStack {
                                Spacer()
                                if statsViewModel.isLoading && !statsViewModel.loadingStatusMessage.isEmpty {
                                    Text(statsViewModel.loadingStatusMessage)
                                        .font(.footnote)
                                        .foregroundColor(.secondary)
                                } else {
                                    Text("Générer le Rewind")
                                }
                                Spacer()
                            }
                        }
                        .disabled(statsViewModel.isLoading)
                    }
                }
                .disabled(!statsViewModel.isHistorySynced && serverViewModel.selectedServerID == nil)

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
