import SwiftUI

struct ServerSelectionSection: View {
    @EnvironmentObject var serverViewModel: ServerViewModel

    var body: some View {
        Section(header: Text("Paramètres Plex")) {
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
    }
}
