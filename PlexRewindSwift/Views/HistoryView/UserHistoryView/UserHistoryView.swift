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
        content
            .navigationBarTitleDisplayMode(.inline)
            .navigationTitle("Historique des écoutes")
            .refreshable { await viewModel.refreshData() }
            .task { await viewModel.loadInitialData() }
    }

    @ViewBuilder
    private var content: some View {
        if viewModel.isLoading {
            ProgressView("Chargement de l'historique...")
        } else {
            List {
                UserHeaderView(viewModel: viewModel)
                
                if viewModel.sessions.isEmpty {
                    EmptyDataView(
                        systemImageName: "person.fill",
                        title: "Aucun historique trouvé",
                        message: "L'historique pour cet utilisateur est vide."
                    )
                } else {
                    UserHistoryListView(viewModel: viewModel)
                }
            }
        }
    }
}
