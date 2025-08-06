import SwiftUI

struct HistoryDetailView: View {
    let title: String
    let sessions: [WatchSession]
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationStack {
            List(sessions) { session in
                VStack(alignment: .leading) {
                    Text(session.showTitle)
                        .font(.headline)
                    if let viewedAt = session.viewedAt {
                        Text("Vu le: \(Date(timeIntervalSince1970: viewedAt).formatted())")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }
            }
            .navigationTitle(title)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Fermer") {
                        dismiss()
                    }
                }
            }
        }
    }
}
