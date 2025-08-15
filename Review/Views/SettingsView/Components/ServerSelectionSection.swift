import SwiftUI

struct ServerSelectionSection: View {
    @EnvironmentObject var serverViewModel: ServerViewModel

    var body: some View {
        Section(header: Text("settings.server.selection.section.title")) {
            if serverViewModel.isLoading {
                ProgressView()
            }
            Picker("settings.server.picker.label", selection: $serverViewModel.selectedServerID) {
                Text("settings.server.picker.default.text").tag(String?.none)
                ForEach(serverViewModel.availableServers) { server in
                    Text(server.name).tag(server.id as String?)
                }
            }
            .disabled(serverViewModel.availableServers.isEmpty)
        }
    }
}
