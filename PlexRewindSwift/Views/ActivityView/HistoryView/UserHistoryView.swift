import SwiftUI

struct UserHistoryView: View {
    let userName: String
    let sessionsFetcher: () async -> [WatchSession]
    
    @State private var sessions: [WatchSession] = []
    @State private var isLoading = true

    var body: some View {
        Group {
            if isLoading {
                VStack(spacing: 20) {
                    ProgressView().scaleEffect(1.5)
                    Text("Chargement de l'historique...")
                        .foregroundColor(.secondary)
                }
            } else if sessions.isEmpty {
                VStack(spacing: 15) {
                    Image(systemName: "person.fill")
                        .font(.system(size: 60))
                        .foregroundColor(.secondary)
                    Text("Aucun historique trouvé")
                        .font(.title2.bold())
                    Text("L'historique pour cet utilisateur est vide.")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
            } else {
                List(sessions) { session in
                    VStack(alignment: .leading, spacing: 4) {
                        Text(session.showTitle)
                            .font(.headline)

                        if session.type == "episode" {
                            Text(session.title ?? "Épisode inconnu")
                                .font(.subheadline)
                        }
                        
                        if let viewedAt = session.viewedAt {
                            Text("Vu le: \(Date(timeIntervalSince1970: viewedAt).formatted(date: .long, time: .shortened))")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding(.vertical, 4)
                }
                .refreshable {
                    await refreshData()
                }
            }
        }
        .navigationTitle(userName)
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await loadInitialData()
        }
    }

    private func loadInitialData() async {
        if sessions.isEmpty {
            isLoading = true
            self.sessions = await sessionsFetcher()
            isLoading = false
        }
    }
    
    private func refreshData() async {
        self.sessions = await sessionsFetcher()
    }
}
