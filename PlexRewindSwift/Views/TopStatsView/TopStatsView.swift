import SwiftUI

struct TopStatsView: View {
    @StateObject private var viewModel: TopStatsViewModel
    @EnvironmentObject var serverViewModel: ServerViewModel
    @EnvironmentObject var authManager: PlexAuthManager
    @EnvironmentObject var statsViewModel: StatsViewModel
    
    @State private var isShowingFilterSheet = false

    init(serverViewModel: ServerViewModel, authManager: PlexAuthManager) {
        _viewModel = StateObject(wrappedValue: TopStatsViewModel(
            serverViewModel: serverViewModel,
            authManager: authManager
        ))
    }

    var body: some View {
        NavigationStack {
            Group {
                if viewModel.isLoading {
                    LoadingStateView(message: viewModel.loadingMessage)
                } else if let errorMessage = viewModel.errorMessage {
                    Text(errorMessage)
                        .foregroundColor(.red)
                        .padding()
                } else {
                    List {
                        if viewModel.topMovies.isEmpty && viewModel.topShows.isEmpty {
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
                        await viewModel.fetchTopMedia()
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
                if viewModel.topMovies.isEmpty && viewModel.topShows.isEmpty && !viewModel.hasFetchedOnce {
                    await viewModel.fetchTopMedia()
                }
            }
            .onChange(of: viewModel.selectedUserID) {
                Task { await viewModel.fetchTopMedia() }
            }
            .onChange(of: viewModel.selectedTimeFilter) {
                 Task { await viewModel.fetchTopMedia() }
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
                                if let lastViewed = media.lastViewedAt {
                                    Text("Dernier visionnage: \(lastViewed.formatted(.relative(presentation: .named)))")
                                }
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
