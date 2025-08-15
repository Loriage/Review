import SwiftUI

struct MediaHistoryView: View {
    @StateObject var viewModel: MediaHistoryViewModel
    @StateObject private var actionsViewModel: MediaActionsViewModel
    
    @EnvironmentObject var serverViewModel: ServerViewModel
    @EnvironmentObject var authManager: PlexAuthManager
    @EnvironmentObject var statsViewModel: StatsViewModel

    @State private var selectedTab: MediaHistoryTab = .information
    @State private var showingSettings = false
    @State private var showMediaDetails = false
    @State private var showImageSelector = false
    @State private var showFixMatchView = false
    @State private var showingAnalysisAlert = false
    @State private var sheetHeight: CGFloat = 250

    enum MediaHistoryTab {
        case history, information, seasons
    }

    init(ratingKey: String, mediaType: String, grandparentRatingKey: String?, serverViewModel: ServerViewModel, authManager: PlexAuthManager, statsViewModel: StatsViewModel) {
        _viewModel = StateObject(wrappedValue: MediaHistoryViewModel(
            ratingKey: ratingKey, mediaType: mediaType, grandparentRatingKey: grandparentRatingKey,
            serverViewModel: serverViewModel, statsViewModel: statsViewModel, authManager: authManager
        ))

        _actionsViewModel = StateObject(wrappedValue: MediaActionsViewModel(
            ratingKey: grandparentRatingKey ?? ratingKey,
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
                        if viewModel.mediaDetails != nil {
                            MediaHeaderView(viewModel: viewModel)
                        }
                        
                        Picker("tab.picker.label", selection: $selectedTab) {
                            Text("tab.information").tag(MediaHistoryTab.information)
                            Text("tab.history").tag(MediaHistoryTab.history)
                            if viewModel.mediaType == "show" || viewModel.mediaType == "episode" {
                                Text("tab.seasons").tag(MediaHistoryTab.seasons)
                            }
                        }
                        .pickerStyle(.segmented)
                        .padding(.horizontal)

                        switch selectedTab {
                        case .history:
                            HistoryListView(historyItems: viewModel.historyItems)
                        case .information:
                            MediaInfoView(viewModel: viewModel)
                                .padding(.horizontal)
                        case .seasons:
                            SeasonsView(viewModel: viewModel, showRatingKey: viewModel.ratingKeyForActions)
                        }
                    }
                    .padding(.vertical)
                }
                .refreshable { await viewModel.refreshData() }
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
        .sheet(isPresented: $showFixMatchView, onDismiss: refreshDetails, content: fixMatchView)
        .alert("library.detail.refresh.alert.title", isPresented: $showingAnalysisAlert, actions: analysisAlertActions, message: analysisAlertMessage)
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
        MediaSettingsSheet(
            viewModel: viewModel, actionsViewModel: actionsViewModel,
            showingSettings: $showingSettings, showMediaDetails: $showMediaDetails,
            showImageSelector: $showImageSelector, showFixMatchView: $showFixMatchView,
            showingAnalysisAlert: $showingAnalysisAlert
        )
        .presentationDetents([.height(sheetHeight)])
        .presentationDragIndicator(.visible)
        .onAppear { sheetHeight = viewModel.mediaType == "movie" ? 260 : 220 }
    }
    
    private func imageSelectorView() -> some View {
        ImageSelectorView(ratingKey: viewModel.ratingKeyForActions, serverViewModel: serverViewModel, authManager: authManager)
    }
    
    private func mediaDetailsView() -> some View {
        MediaDetailsView(ratingKey: viewModel.ratingKey, serverViewModel: serverViewModel, authManager: authManager)
    }
    
    private func fixMatchView() -> some View {
        FixMatchView(ratingKey: viewModel.ratingKeyForActions, serverViewModel: serverViewModel, authManager: authManager)
    }
    
    private func refreshDetails() {
        Task { await viewModel.refreshSessionDetails() }
    }
    
    @ViewBuilder
    private func analysisAlertActions() -> some View {
        Button("common.cancel", role: .cancel) {}
        Button("activity.settings.analyze", role: .destructive) {
            Task { await actionsViewModel.analyzeMedia() }
        }
    }
    
    private func analysisAlertMessage() -> some View {
        Text("library.detail.refresh.alert.message")
    }
}
