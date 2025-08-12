import SwiftUI

struct TopStatsView: View {
    @EnvironmentObject var viewModel: TopStatsViewModel
    @EnvironmentObject var serverViewModel: ServerViewModel
    @EnvironmentObject var authManager: PlexAuthManager
    @EnvironmentObject var statsViewModel: StatsViewModel
    
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
                    List {
                        if viewModel.topMovies.isEmpty && viewModel.topShows.isEmpty && viewModel.hasFetchedOnce {
                            VStack(alignment: .center, spacing: 10) {
                                Image(systemName: "chart.bar.xaxis.ascending")
                                    .font(.system(size: 40))
                                    .foregroundColor(.secondary)
                                Text("Aucune donnée")
                                    .font(.title3.bold())
                                Text("Aucun historique de visionnage trouvé pour cette sélection.")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                    .multilineTextAlignment(.center)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 50)
                        } else {
                            if viewModel.hasFetchedOnce {
                                funFactsSection
                            }
                            if !viewModel.topMovies.isEmpty {
                                topMediaSection(
                                    title: "Films les plus populaires",
                                    items: Array(viewModel.topMovies.prefix(5)),
                                    fullList: viewModel.topMovies
                                )
                            }
                            if !viewModel.topShows.isEmpty {
                                topMediaSection(
                                    title: "Séries les plus populaires",
                                    items: Array(viewModel.topShows.prefix(3)),
                                    fullList: viewModel.topShows
                                )
                            }
                        }
                    }
                    .refreshable {
                        await viewModel.fetchTopMedia(forceRefresh: true)
                    }
                }
            }
            .navigationTitle("Top Stats")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { isShowingFilterSheet = true }) {
                        Label("Filtres", systemImage: "line.3.horizontal.decrease.circle")
                    }
                }
            }
            .sheet(isPresented: $isShowingFilterSheet) {
                FilterSheetView(
                    selectedUserID: $viewModel.selectedUserID,
                    selectedTimeFilter: $viewModel.selectedTimeFilter,
                    sortOption: $viewModel.sortOption
                )
                .presentationDetents([.large])
                .presentationDragIndicator(.visible)
            }
            .task {
                if serverViewModel.availableUsers.isEmpty && serverViewModel.selectedServerID != nil {
                    await serverViewModel.loadUsers(for: serverViewModel.selectedServerID!)
                }
                if !viewModel.hasFetchedOnce {
                    await viewModel.fetchTopMedia()
                }
            }
            .onChange(of: viewModel.selectedUserID) {
                Task { await viewModel.applyFiltersAndSort() }
            }
            .onChange(of: viewModel.selectedTimeFilter) {
                Task { await viewModel.applyFiltersAndSort() }
            }
            .onChange(of: viewModel.sortOption) {
                viewModel.sortMedia()
            }
        }
    }

    private func topMediaSection(title: String, items: [TopMedia], fullList: [TopMedia]) -> some View {
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
        } header: {
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

    @ViewBuilder
    private var funFactsSection: some View {
        FunFactsView(viewModel: viewModel)
    }
}

struct LoadingStateView: View {
    let message: String
    @State private var isAnimating = false

    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "film.stack")
                .font(.system(size: 50))
                .symbolEffect(.bounce.up.byLayer, value: isAnimating)
                .onAppear { isAnimating = true }
                .foregroundColor(.accentColor)
            
            Text(message)
                .font(.headline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .contentTransition(.numericText())
                .animation(.easeInOut, value: message)
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

struct FunFactsView: View {
    @ObservedObject var viewModel: TopStatsViewModel
    
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
    
    private func timeOfDayIcon(for timeOfDay: TimeOfDay) -> String {
        switch timeOfDay {
        case .morning: return "sunrise.fill"
        case .afternoon: return "sun.max.fill"
        case .evening: return "sunset.fill"
        case .night: return "moon.stars.fill"
        }
    }
}
