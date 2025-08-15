import SwiftUI

struct EpisodeHistoryView: View {
    @StateObject var viewModel: EpisodeHistoryViewModel
    @StateObject private var actionsViewModel: MediaActionsViewModel
    
    @EnvironmentObject var serverViewModel: ServerViewModel
    @EnvironmentObject var authManager: PlexAuthManager
    @EnvironmentObject var statsViewModel: StatsViewModel

    @State private var selectedTab: EpisodeHistoryTab = .information
    @State private var showingSettings = false
    @State private var showMediaDetails = false
    @State private var showImageSelector = false
    @State private var sheetHeight: CGFloat = 220

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
        _actionsViewModel = StateObject(wrappedValue: MediaActionsViewModel(
            ratingKey: episode.ratingKey,
            actionsService: PlexActionsService(),
            serverViewModel: serverViewModel, authManager: authManager
        ))
    }

    var body: some View {
        ZStack {
            if viewModel.isLoading {
                ProgressView("common.loading")
            } else {
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        AsyncImageView(url: viewModel.displayPosterURL, refreshTrigger: viewModel.imageRefreshId)
                            .aspectRatio(16/9, contentMode: .fit)
                            .cornerRadius(16)
                            .shadow(color: .black.opacity(0.25), radius: 5, y: 5)
                            .padding(.horizontal)
                        
                        Picker("tab.picker.label", selection: $selectedTab) {
                            Text("tab.information").tag(EpisodeHistoryTab.information)
                            Text("tab.history").tag(EpisodeHistoryTab.history)
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
            if let hudMessage = actionsViewModel.hudMessage {
                HUDView(hudMessage: hudMessage)
                    .transition(.scale.combined(with: .opacity))
            }
        }
        .navigationTitle(LocalizedStringKey(viewModel.displayTitle))
        .navigationBarTitleDisplayMode(.inline)
        .toolbar { toolbarContent }
        .sheet(isPresented: $showingSettings, content: settingsSheet)
        .sheet(isPresented: $showImageSelector, onDismiss: refreshDetails, content: imageSelectorView)
        .sheet(isPresented: $showMediaDetails, content: mediaDetailsView)
        .task {
            await viewModel.loadData()
            actionsViewModel.update(ratingKey: viewModel.ratingKeyForActions)
        }
    }

    private var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .navigationBarTrailing) {
            Button(action: { showingSettings = true }) {
                Image(systemName: "gearshape.fill")
            }
        }
    }

    private func settingsSheet() -> some View {
        EpisodeSettingsSheet(
            actionsViewModel: actionsViewModel,
            showingSettings: $showingSettings,
            showMediaDetails: $showMediaDetails,
            showImageSelector: $showImageSelector
        )
        .presentationDetents([.height(sheetHeight)])
        .presentationDragIndicator(.visible)
    }

    private func imageSelectorView() -> some View {
        ImageSelectorView(ratingKey: viewModel.ratingKeyForActions, serverViewModel: serverViewModel, authManager: authManager)
    }

    private func mediaDetailsView() -> some View {
        MediaDetailsView(ratingKey: viewModel.ratingKeyForActions, serverViewModel: serverViewModel, authManager: authManager)
    }

    private func refreshDetails() {
        Task { await viewModel.refreshSessionDetails() }
    }
}
