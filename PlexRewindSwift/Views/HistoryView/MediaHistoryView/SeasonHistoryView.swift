import SwiftUI

struct SeasonHistoryView: View {
    @StateObject private var viewModel: SeasonHistoryViewModel
    
    @EnvironmentObject var serverViewModel: ServerViewModel
    @EnvironmentObject var authManager: PlexAuthManager
    @EnvironmentObject var statsViewModel: StatsViewModel
    
    @State private var selectedTab: SeasonHistoryTab = .information

    enum SeasonHistoryTab {
        case episodes, information, history
    }

    init(season: PlexSeason, showRatingKey: String, serverViewModel: ServerViewModel, authManager: PlexAuthManager, statsViewModel: StatsViewModel) {
        _viewModel = StateObject(wrappedValue: SeasonHistoryViewModel(
            season: season,
            showRatingKey: showRatingKey,
            serverViewModel: serverViewModel,
            authManager: authManager,
            statsViewModel: statsViewModel
        ))
    }

    var body: some View {
        ZStack {
            if viewModel.isLoading {
                ProgressView("Chargement des épisodes...")
            } else {
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        SeasonsHeaderView(viewModel: viewModel)

                        Picker("Menu", selection: $selectedTab) {
                            Text("Informations").tag(SeasonHistoryTab.information)
                            Text("Historique").tag(SeasonHistoryTab.history)
                            Text("Épisodes").tag(SeasonHistoryTab.episodes)
                        }
                        .pickerStyle(.segmented)
                        .padding(.horizontal)

                        switch selectedTab {
                        case .episodes:
                            episodeList
                        case .history:
                            HistoryListView(historyItems: viewModel.historyItems)
                        case .information:
                            SeasonInfoView(viewModel: viewModel)
                                .padding(.horizontal)
                        }
                    }
                    .padding(.vertical)
                }
            }
        }
        .navigationTitle(viewModel.season.title)
        .task {
            await viewModel.loadData()
        }
    }
    
    private var episodeList: some View {
        VStack(alignment: .leading) {
            LazyVStack(spacing: 0) {
                ForEach(viewModel.episodes) { episode in
                    NavigationLink(destination: MediaHistoryView(
                        ratingKey: episode.ratingKey,
                        mediaType: "episode",
                        grandparentRatingKey: viewModel.season.key,
                        serverViewModel: serverViewModel,
                        authManager: authManager,
                        statsViewModel: statsViewModel
                    )) {
                        episodeRow(for: episode)
                    }
                    .buttonStyle(.plain)
                    
                    if episode.id != viewModel.episodes.last?.id {
                        Divider().padding(.leading, 16)
                    }
                }
            }
            .background(Color(.secondarySystemBackground))
            .cornerRadius(12)
        }
        .padding(.horizontal)
    }
    
    private func episodeRow(for episode: PlexEpisode) -> some View {
        HStack(spacing: 15) {
            AsyncImageView(url: viewModel.episodePosterURL(for: episode))
                .frame(width: 100, height: 58)
                .aspectRatio(16/9, contentMode: .fill)
                .cornerRadius(8)
            
            VStack(alignment: .leading) {
                Text("Épisode \(episode.index ?? 0)")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                Text(episode.title)
                    .font(.headline)
                    .lineLimit(2)
            }
            Spacer()
            Image(systemName: "chevron.right")
                .font(.body.weight(.semibold))
                .foregroundColor(.secondary.opacity(0.5))
        }
        .padding(.horizontal)
        .padding(.vertical, 12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .contentShape(Rectangle())
    }
}
