import SwiftUI

struct UserHistoryView: View {
    @StateObject var viewModel: UserHistoryViewModel

    init(userID: Int, userName: String, statsViewModel: StatsViewModel, serverViewModel: ServerViewModel, authManager: PlexAuthManager) {
        _viewModel = StateObject(wrappedValue: UserHistoryViewModel(
            userID: userID,
            userName: userName,
            statsViewModel: statsViewModel,
            serverViewModel: serverViewModel,
            authManager: authManager
        ))
    }

    var body: some View {
        Group {
            if viewModel.isLoading {
                VStack(spacing: 20) {
                    ProgressView().scaleEffect(1.5)
                    Text("Chargement de l'historique...")
                        .foregroundColor(.secondary)
                }
            } else if viewModel.sessions.isEmpty {
                List {
                    userHeaderSection
                    emptyStateSection
                }
            } else {
                List {
                    userHeaderSection
                    historySection
                }
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .navigationTitle("Historique des écoutes")
        .refreshable {
            await viewModel.refreshData()
        }
        .task {
            await viewModel.loadInitialData()
        }
    }

    private var userHeaderSection: some View {
        Section {
            VStack(spacing: 15) {
                AsyncImageView(url: viewModel.userProfileImageURL)
                    .frame(width: 100, height: 100)
                    .clipShape(Circle())
                    .shadow(color: .black.opacity(0.25), radius: 5, y: 5)
                
                Text(viewModel.userName)
                    .font(.title.bold())
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 20)
        }
        .listRowInsets(EdgeInsets())
        .listRowSeparator(.hidden)
        .listRowBackground(Color.clear)
    }

    private var emptyStateSection: some View {
        Section {
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
            .frame(maxWidth: .infinity, alignment: .center)
            .padding(.vertical, 30)
        }
        .listRowBackground(Color.clear)
    }

    private var historySection: some View {
        Section(header: Text("Historique des visionnages")) {
            ForEach(viewModel.sessions) { session in
                HStack(spacing: 15) {
                    AsyncImageView(url: viewModel.posterURL(for: session), contentMode: .fill)
                    .frame(width: 60, height: 90)
                    .cornerRadius(8)

                    VStack(alignment: .leading, spacing: 4) {
                        if session.type == "movie" {
                            Text(session.title ?? "Titre inconnu")
                                .font(.headline)
                        } else if session.type == "episode" {
                            Text(session.grandparentTitle ?? "Série inconnue")
                                .font(.headline)
                            Text(session.title ?? "Épisode inconnu")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            Text("S\(session.parentIndex ?? 0) - E\(session.index ?? 0)")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        
                        if let viewedAt = session.viewedAt {
                            Text("\(Date(timeIntervalSince1970: viewedAt).formatted(.relative(presentation: .named)))")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding(.vertical, 4)
                }
            }
        }
    }
}
