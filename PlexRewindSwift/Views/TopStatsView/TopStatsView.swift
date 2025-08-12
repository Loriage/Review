import SwiftUI

struct TopStatsView: View {
    @EnvironmentObject var viewModel: TopStatsViewModel
    @EnvironmentObject var serverViewModel: ServerViewModel
    @EnvironmentObject var authManager: PlexAuthManager
    
    @State private var isShowingFilterSheet = false

    var body: some View {
        NavigationStack {
            Group {
                if viewModel.isLoading && !viewModel.hasFetchedOnce {
                    LoadingStateView(message: viewModel.loadingMessage)
                } else if let errorMessage = viewModel.errorMessage {
                    Text(errorMessage)
                        .foregroundColor(.red)
                        .padding()
                } else {
                    listContent
                }
            }
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
                    TopMediaSection(title: "Films les plus populaires", items: Array(viewModel.topMovies.prefix(5)), fullList: viewModel.topMovies)
                }
                if !viewModel.topShows.isEmpty {
                    TopMediaSection(title: "Séries les plus populaires", items: Array(viewModel.topShows.prefix(3)), fullList: viewModel.topShows)
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

private struct FunFactsSection: View {
    @ObservedObject var viewModel: TopStatsViewModel

    private func timeOfDayIcon(for timeOfDay: TimeOfDay) -> String {
        switch timeOfDay {
        case .morning: return "sunrise.fill"
        case .afternoon: return "sun.max.fill"
        case .evening: return "sunset.fill"
        case .night: return "moon.stars.fill"
        }
    }

    var body: some View {
        Section(header: Text("En bref").font(.headline)) {
            VStack(spacing: 10) {
                HStack(spacing: 10) {
                    if let totalPlays = viewModel.funFactTotalPlays, totalPlays > 0 {
                        StatPill(title: "Lectures", value: "\(totalPlays)", icon: "play.tv.fill", color: .blue)
                    }
                    if let formattedTime = viewModel.funFactFormattedWatchTime {
                        StatPill(title: "Temps total", value: formattedTime, icon: "hourglass", color: .purple)
                    }
                    if let mostActiveDay = viewModel.funFactMostActiveDay {
                        StatPill(title: "Jour favori", value: mostActiveDay, icon: "calendar", color: .red)
                    }
                }
                HStack(spacing: 10) {
                    if let topUser = viewModel.funFactTopUser {
                        StatPill(title: "Top Profil", value: topUser, icon: "person.fill", color: .orange)
                    }
                    if let timeOfDay = viewModel.funFactBusiestTimeOfDay {
                        StatPill(title: "Moment phare", value: timeOfDay.rawValue, icon: timeOfDayIcon(for: timeOfDay), color: .indigo)
                    }
                    if let activeUsers = viewModel.funFactActiveUsers, activeUsers > 0 {
                        StatPill(title: "Profils actifs", value: "\(activeUsers)", icon: "person.3.fill", color: .cyan)
                    }
                }
            }
            .listRowInsets(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0))
            .listRowBackground(Color.clear)
        }
    }
}

private struct TopMediaSection: View {
    @EnvironmentObject var serverViewModel: ServerViewModel
    @EnvironmentObject var authManager: PlexAuthManager
    @EnvironmentObject var statsViewModel: StatsViewModel
    
    let title: String
    let items: [TopMedia]
    let fullList: [TopMedia]

    var body: some View {
        Section {
            ForEach(items) { media in
                NavigationLink(destination: MediaHistoryView(
                    ratingKey: media.id,
                    mediaType: media.mediaType,
                    grandparentRatingKey: media.mediaType == "show" ? media.id : nil,
                    serverViewModel: serverViewModel,
                    authManager: authManager,
                    statsViewModel: statsViewModel
                )) {
                    MediaRow(media: media)
                }
            }
        } header: {
            SectionHeader(title: title, fullList: fullList, items: items)
        }
    }
}

private struct MediaRow: View {
    let media: TopMedia

    var body: some View {
        HStack(spacing: 15) {
            AsyncImageView(url: media.posterURL, contentMode: .fill)
                .frame(width: 60, height: 90)
                .cornerRadius(8)

            VStack(alignment: .leading, spacing: 4) {
                Text(media.title)
                    .font(.headline)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("Lectures: \(media.viewCount)")
                    Text("Durée: \(media.formattedWatchTime)")
                }
                .font(.subheadline)
                .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 5)
    }
}

private struct SectionHeader: View {
    let title: String
    let fullList: [TopMedia]
    let items: [TopMedia]

    var body: some View {
        HStack {
            Text(title).font(.headline)
            Spacer()
            if fullList.count > items.count {
                NavigationLink(destination: TopMediaDetailView(title: title, items: fullList)) {
                    Text("Voir plus")
                        .font(.subheadline)
                }
            }
        }
    }
}
