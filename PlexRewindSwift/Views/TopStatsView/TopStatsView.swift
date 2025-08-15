import SwiftUI

struct TopStatsView: View {
    @EnvironmentObject var viewModel: TopStatsViewModel
    @EnvironmentObject var serverViewModel: ServerViewModel
    
    @State private var isShowingFilterSheet = false

    var body: some View {
        NavigationStack {
            content
                .navigationTitle("top.stats.view.title")
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
            LoadingStateView(message: LocalizedStringKey(viewModel.loadingMessage))
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
                    title: "empty.state.no.data.title",
                    message: "empty.state.no.data.message"
                )
            } else {
                if viewModel.hasFetchedOnce {
                    FunFactsSection(viewModel: viewModel)
                }
                if !viewModel.topMovies.isEmpty {
                    TopMediaSection(title: "\(String(localized: "top.stats.movies.title"))", items: Array(viewModel.topMovies.prefix(4)), fullList: viewModel.topMovies)
                }
                if !viewModel.topShows.isEmpty {
                    TopMediaSection(title: "\(String(localized: "top.stats.shows.title"))", items: Array(viewModel.topShows.prefix(4)), fullList: viewModel.topShows)
                }
            }
        }
        .refreshable { await viewModel.fetchTopMedia(forceRefresh: true) }
    }

    private var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .navigationBarTrailing) {
            Button(action: { isShowingFilterSheet = true }) {
                Label("filter.sheet.filters", systemImage: "line.3.horizontal.decrease.circle")
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
