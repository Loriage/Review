import SwiftUI

struct ServerDetailsView: View {
    let server: PlexResource

    var body: some View {
        Form {
            Section(header: Text("settings.server.details.general.sectio")) {
                InfoRow(label: LocalizedStringKey(server.product), value: server.productVersion)
                InfoRow(label: "settings.server.details.platform", value: server.platform)
                InfoRow(label: "settings.server.details.platform.version", value: server.platformVersion)
                InfoRow(label: "settings.server.details.public.ip", value: server.publicAddress)
                InfoRow(label: "settings.server.details.created.at", value: formatDate(server.createdAt))
            }
            
            Section(header: Text("settings.server.details.settings.section")) {
                NavigationLink(destination: PrefsView()) {
                    HStack(spacing: 10) {
                        Image(systemName: "gearshape")
                            .font(.title2)
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text("settings.server.details.preferences.title")
                                .font(.headline)
                            Text("settings.server.details.preferences.description")
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
                            Text("settings.server.details.charts.title")
                                .font(.headline)
                            Text("settings.server.details.charts.description")
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
                            Text("settings.server.details.logs.title")
                                .font(.headline)
                            Text("settings.server.details.logs.description")
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
        return "settings.server.details.unknown.date"
    }
}
