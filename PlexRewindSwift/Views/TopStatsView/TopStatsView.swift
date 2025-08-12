import SwiftUI

struct TopStatsView: View {
    @EnvironmentObject var viewModel: TopStatsViewModel
    @EnvironmentObject var serverViewModel: ServerViewModel
    
    @State private var isShowingFilterSheet = false

    var body: some View {
        NavigationStack {
            content
                .navigationTitle("Top Stats")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar { toolbarContent }
                .sheet(isPresented: $isShowingFilterSheet, content: filterSheet)
                .task { await initialLoad() }
                .onChange(of: viewModel.selectedUserID) { Task { await viewModel.applyFiltersAndSort() } }
                .onChange(of: viewModel.selectedTimeFilter) { Task { await viewModel.applyFiltersAndSort() } }
                .onChange(of: viewModel.sortOption) { viewModel.sortMedia() }
        }
    }

    @ViewBuilder
    private var content: some View {
        if viewModel.isLoading && !viewModel.hasFetchedOnce {
            LoadingStateView(message: viewModel.loadingMessage)
        } else if let errorMessage = viewModel.errorMessage {
            Text(errorMessage).foregroundColor(.red).padding()
        } else {
            listContent
        }
    }

    private var listContent: some View {
        List {
            if viewModel.topMovies.isEmpty && viewModel.topShows.isEmpty && viewModel.hasFetchedOnce {
                EmptyDataView(
                    systemImageName: "chart.bar.xaxis.ascending",
                    title: "Aucune donnée",
                    message: "Aucun historique de visionnage trouvé pour cette sélection."
                )
            } else {
                if viewModel.hasFetchedOnce {
                    FunFactsSection(viewModel: viewModel)
                }
                if !viewModel.topMovies.isEmpty {
                    TopMediaSection(title: "Films les plus populaires", items: Array(viewModel.topMovies.prefix(4)), fullList: viewModel.topMovies)
                }
                if !viewModel.topShows.isEmpty {
                    TopMediaSection(title: "Séries les plus populaires", items: Array(viewModel.topShows.prefix(4)), fullList: viewModel.topShows)
                }
            }
        }
        .refreshable { await viewModel.fetchTopMedia(forceRefresh: true) }
    }

    private var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .navigationBarTrailing) {
            Button(action: { isShowingFilterSheet = true }) {
                Label("Filtres", systemImage: "line.3.horizontal.decrease.circle")
            }
        }
    }

    private func filterSheet() -> some View {
        FilterSheetView(
            selectedUserID: $viewModel.selectedUserID,
            selectedTimeFilter: $viewModel.selectedTimeFilter,
            sortOption: $viewModel.sortOption
        )
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
    }

    private func initialLoad() async {
        if serverViewModel.availableUsers.isEmpty && serverViewModel.selectedServerID != nil {
            await serverViewModel.loadUsers(for: serverViewModel.selectedServerID!)
        }
        if !viewModel.hasFetchedOnce {
            await viewModel.fetchTopMedia()
        }
    }
}
