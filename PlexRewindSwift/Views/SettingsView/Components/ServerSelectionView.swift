import SwiftUI

struct ServerSelectionView: View {
    @EnvironmentObject var serverViewModel: ServerViewModel

    var body: some View {
        Form {
            Section(header: Text("Serveurs disponibles")) {
                Picker("Serveur Plex", selection: $serverViewModel.selectedServerID) {
                    Text("Choisissez un serveur...").tag(String?.none)
                    ForEach(serverViewModel.availableServers) { server in
                        Text(server.name).tag(server.id as String?)
                    }
                }
                .pickerStyle(.inline)
                .labelsHidden()
            }
        }
        .navigationTitle("Changer de serveur")
        .navigationBarTitleDisplayMode(.inline)
    }
}
