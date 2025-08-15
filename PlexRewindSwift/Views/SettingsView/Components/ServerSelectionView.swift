import SwiftUI

struct ServerSelectionView: View {
    @EnvironmentObject var serverViewModel: ServerViewModel

    var body: some View {
        Form {
            Section(header: Text("Serveurs disponibles")) {
                Picker("settings.server.selection.section.title", selection: $serverViewModel.selectedServerID) {
                    Text("settings.server.picker.default.text").tag(String?.none)
                    ForEach(serverViewModel.availableServers) { server in
                        Text(server.name).tag(server.id as String?)
                    }
                }
                .pickerStyle(.inline)
                .labelsHidden()
            }
        }
        .navigationTitle("settings.server.change.title")
        .navigationBarTitleDisplayMode(.inline)
    }
}
