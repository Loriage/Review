import SwiftUI

struct ConfigurationView: View {
    let servers: [PlexResource]
    @Binding var selectedServerID: String?
    let isHistoryReady: Bool
    var onGenerate: () -> Void
    
    var body: some View {
        Form {
            Section(header: Text("Sélection du serveur")) {
                Picker("Serveur Plex", selection: $selectedServerID) {
                    Text("Choisissez un serveur...").tag(String?.none)
                    ForEach(servers) { server in
                        Text(server.name).tag(server.id as String?)
                    }
                }
                .disabled(servers.isEmpty)
            }
            
            if isHistoryReady {
                Button(action: onGenerate) {
                    HStack {
                        Spacer()
                        Text("Générer mon Rewind")
                            .font(.headline)
                        Spacer()
                    }
                }
                .padding()
                .disabled(selectedServerID == nil)
            }
        }
    }
}
