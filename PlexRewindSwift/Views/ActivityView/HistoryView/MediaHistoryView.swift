import SwiftUI

struct MediaHistoryView: View {
    let title: String
    let posterURL: URL?
    let sessionsFetcher: () async -> (sessions: [WatchSession], summary: String?)
    
    @State private var sessions: [WatchSession] = []
    @State private var summary: String?
    @State private var isLoading = true

    var body: some View {
        Group {
            if isLoading {
                loadingView
            } else if sessions.isEmpty {
                emptyView
            } else {
                contentView
            }
        }
        .navigationTitle(title)
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await loadInitialData()
        }
    }

    private var loadingView: some View {
        VStack(spacing: 20) {
            ProgressView().scaleEffect(1.5)
            Text("Chargement de l'historique...")
                .foregroundColor(.secondary)
        }
    }

    private var emptyView: some View {
        VStack(spacing: 15) {
            Image(systemName: "film.stack")
                .font(.system(size: 60))
                .foregroundColor(.secondary)
            Text("Aucun historique trouvé")
                .font(.title2.bold())
            Text("L'historique pour ce média est vide.")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        }
    }

    private var contentView: some View {
        List {
            headerSection
            historySection
        }
        .refreshable {
            await refreshData()
        }
    }

    private var headerSection: some View {
        Section {
            VStack {
                HStack {
                    Spacer()
                    AsyncImageView(url: posterURL, contentMode: .fit)
                        .frame(height: 250)
                        .cornerRadius(16)
                        .shadow(color: .black.opacity(0.25), radius: 5, y: 5)
                    Spacer()
                }
                .padding(.top, 5)
                .padding(.bottom, 20)

                if let summary = summary, !summary.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Résumé")
                            .font(.title2.bold())
                            .padding(.bottom, 2)
                        Text(summary)
                            .font(.body)
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
        .listRowInsets(EdgeInsets())
        .listRowBackground(Color.clear)
    }

    private var historySection: some View {
        Section(header: Text("Historique des visionnages")) {
            ForEach(sessions) { session in
                VStack(alignment: .leading, spacing: 4) {
                    if session.type == "episode" {
                        Text(session.title ?? "Épisode inconnu")
                            .font(.headline)
                    } else {
                        Text(session.title ?? "Titre inconnu")
                            .font(.headline)
                    }
                    
                    if let viewedAt = session.viewedAt {
                        Text("Vu le: \(Date(timeIntervalSince1970: viewedAt).formatted(date: .long, time: .shortened))")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                .padding(.vertical, 8)
            }
        }
    }

    private func loadInitialData() async {
        if sessions.isEmpty {
            isLoading = true
            let result = await sessionsFetcher()
            self.sessions = result.sessions
            self.summary = result.summary
            isLoading = false
        }
    }

    private func refreshData() async {
        let result = await sessionsFetcher()
        self.sessions = result.sessions
        self.summary = result.summary
    }
}
