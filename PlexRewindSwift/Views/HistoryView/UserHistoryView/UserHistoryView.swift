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
            .navigationTitle("user.history.view.title")
            .refreshable { await viewModel.refreshData() }
            .task { await viewModel.loadInitialData() }
    }

    @ViewBuilder
    private var content: some View {
        if viewModel.isLoading {
            ProgressView("loading.state.getting.history")
        } else {
            List {
                UserHeaderView(viewModel: viewModel)
                
                if viewModel.sessions.isEmpty {
                    EmptyDataView(
                        systemImageName: "person.fill",
                        title: "empty.state.no.history.item.title",
                        message: "empty.state.no.history.user.message"
                    )
                } else {
                    UserHistoryListView(viewModel: viewModel)
                }
            }
        }
    }
}
