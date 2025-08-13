import SwiftUI

struct EpisodeHistoryView: View {
    @StateObject var viewModel: EpisodeHistoryViewModel
    
    @EnvironmentObject var serverViewModel: ServerViewModel
    @EnvironmentObject var authManager: PlexAuthManager
    @EnvironmentObject var statsViewModel: StatsViewModel

    @State private var selectedTab: EpisodeHistoryTab = .information

    enum EpisodeHistoryTab {
        case history, information
    }

    init(episode: PlexEpisode, showRatingKey: String, serverViewModel: ServerViewModel, authManager: PlexAuthManager, statsViewModel: StatsViewModel) {
        _viewModel = StateObject(wrappedValue: EpisodeHistoryViewModel(
            episode: episode,
            showRatingKey: showRatingKey,
            serverViewModel: serverViewModel,
            statsViewModel: statsViewModel,
            authManager: authManager
        ))
    }

    var body: some View {
        ZStack {
            if viewModel.isLoading {
                ProgressView("Chargement...")
            } else {
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        AsyncImageView(url: viewModel.displayPosterURL)
                            .aspectRatio(16/9, contentMode: .fit)
                            .cornerRadius(16)
                            .shadow(color: .black.opacity(0.25), radius: 5, y: 5)
                            .padding(.horizontal)
                        
                        Picker("Menu", selection: $selectedTab) {
                            Text("Informations").tag(EpisodeHistoryTab.information)
                            Text("Historique").tag(EpisodeHistoryTab.history)
                        }
                        .pickerStyle(.segmented)
                        .padding(.horizontal)

                        switch selectedTab {
                        case .history:
                            HistoryListView(historyItems: viewModel.historyItems)
                        case .information:
                           EpisodeInfoView(viewModel: viewModel)
                        }
                    }
                    .padding(.vertical)
                }
            }
        }
        .navigationTitle(viewModel.displayTitle)
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await viewModel.loadData()
        }
    }
}
