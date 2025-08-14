import SwiftUI

struct ServerDetailsView: View {
    let server: PlexResource

    var body: some View {
        Form {
            Section(header: Text("Informations générales")) {
                InfoRow(label: server.product, value: server.productVersion)
                InfoRow(label: "Plateforme", value: server.platform)
                InfoRow(label: "Version de la plateforme", value: server.platformVersion)
                InfoRow(label: "Adresse IP publique", value: server.publicAddress)
                InfoRow(label: "Créé le", value: formatDate(server.createdAt))
            }
            
            Section(header: Text("Paramètres")) {
                NavigationLink(destination: PrefsView()) {
                    HStack(spacing: 10) {
                        Image(systemName: "gearshape")
                            .font(.title2)
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Préférences")
                                .font(.headline)
                            Text("Configure ton serveur, tu en as le pouvoir !")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .padding(.vertical, 2)
                }
                .buttonStyle(.plain)

                NavigationLink(destination: InfoView()) {
                    HStack(spacing: 10) {
                        Image(systemName: "chart.xyaxis.line")
                            .font(.title2)
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Graphes")
                                .font(.headline)
                            Text("Découvre ce qui peut rendre ton serveur poussif.")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .padding(.vertical, 2)
                }
                .buttonStyle(.plain)

                
                NavigationLink(destination: LogsView()) {
                    HStack(spacing: 10) {
                        Image(systemName: "newspaper")
                            .font(.title2)
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Fichiers journaux")
                                .font(.headline)
                            Text("Parfois, il faut savoir défricher.")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .padding(.vertical, 2)
                }
                .buttonStyle(.plain)
            }
        }
        .navigationTitle(server.name)
        .navigationBarTitleDisplayMode(.inline)
    }

    private func formatDate(_ dateString: String) -> String {
        let formatter = ISO8601DateFormatter()
        if let date = formatter.date(from: dateString) {
            return date.formatted(date: .long, time: .shortened)
        }
        return "Date inconnue"
    }
}
