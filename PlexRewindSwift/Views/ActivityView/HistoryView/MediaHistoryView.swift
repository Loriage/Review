
import SwiftUI

struct MediaHistoryView: View {
    @StateObject private var viewModel: MediaHistoryViewModel
    @ScaledMetric var width: CGFloat = 50

    init(session: PlexActivitySession, serverViewModel: ServerViewModel, authManager: PlexAuthManager) {
        _viewModel = StateObject(wrappedValue: MediaHistoryViewModel(
            session: session,
            plexService: PlexAPIService(),
            serverViewModel: serverViewModel,
            authManager: authManager
        ))
    }

    var body: some View {
        Group {
            if viewModel.isLoading {
                loadingView
            } else if viewModel.historyItems.isEmpty {
                emptyView
            } else {
                contentView
            }
        }
        .navigationTitle(viewModel.session.showTitle)
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await viewModel.loadData()
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
            await viewModel.refreshData()
        }
    }
    
    private var headerSection: some View {
        Section {
            VStack(spacing: 20) {
                HStack {
                    Spacer()
                    AsyncImageView(url: viewModel.session.posterURL, contentMode: .fit)
                        .frame(height: 250)
                        .cornerRadius(16)
                        .shadow(color: .black.opacity(0.25), radius: 5, y: 5)
                    Spacer()
                }
                .padding(.top, 5)
                .padding(.bottom, 20)

                HStack {
                    HStack {
                        Image(systemName: "pencil")
                            .frame(width: width, alignment: .center)
                            .foregroundColor(.gray)
                    }
                    HStack {
                        Image(systemName: "photo.badge.magnifyingglass")
                            .frame(width: width, alignment: .center)
                            .foregroundColor(.gray)
                    }
                    HStack {
                        Image(systemName: "magnifyingglass")
                            .frame(width: width, alignment: .center)
                            .foregroundColor(.gray)
                    }
                }
                .font(.title2)

                if let summary = viewModel.session.summary, !summary.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Résumé")
                            .font(.title2.bold())
                            .padding(.horizontal)
                        Text(summary)
                            .font(.body)
                            .foregroundColor(.secondary)
                            .padding(.horizontal)
                    }
                }
            }
            .padding(.bottom)
        }
        .listRowInsets(EdgeInsets())
        .listRowSeparator(.hidden)
        .listRowBackground(Color.clear)
    }
    
    private var historySection: some View {
        Section(header: Text("Historique des visionnages")) {
            ForEach(viewModel.historyItems, id: \MediaHistoryItem.id) { item in
                VStack(alignment: .leading, spacing: 5) {
                    if item.session.type == "episode" {
                        Text(item.session.showTitle)
                            .font(.headline)
                    } else {
                        Text(item.session.title ?? "Titre inconnu")
                            .font(.headline)
                    }
                    
                    if item.session.type == "episode" {
                        Text("S\(item.session.parentIndex ?? 0) - E\(item.session.index ?? 0) - \(item.session.title ?? "Titre inconnu")")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    
                    if let viewedAt = item.session.viewedAt {
                        Text("\(item.userName ?? "Utilisateur inconnu") - \(Date(timeIntervalSince1970: viewedAt).formatted(.relative(presentation: .named)))")
                            .font(.subheadline)
                            .foregroundColor(.secondary.opacity(0.8))
                    }
                }
                .padding(.vertical, 8)
            }
        }
    }
}
