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
                ProgressView("Chargement...")
            } else {
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        if viewModel.mediaDetails != nil {
                            MediaHeaderView(viewModel: viewModel)
                        }
                        
                        Picker("Menu", selection: $selectedTab) {
                            Text("Informations").tag(MediaHistoryTab.information)
                            Text("Historique").tag(MediaHistoryTab.history)
                            if viewModel.mediaType == "show" || viewModel.mediaType == "episode" {
                                Text("Saisons").tag(MediaHistoryTab.seasons)
                            }
                        }
                        .pickerStyle(.segmented)
                        .padding(.horizontal)

                        switch selectedTab {
                        case .history:
                            HistoryListView(viewModel: viewModel)
                        case .information:
                            MediaInfoView(viewModel: viewModel)
                                .padding(.horizontal)
                        case .seasons:
                            SeasonsView(viewModel: viewModel)
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
        .navigationTitle(viewModel.displayTitle)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar { toolbarContent }
        .sheet(isPresented: $showingSettings, content: settingsSheet)
        .sheet(isPresented: $showImageSelector, onDismiss: refreshDetails, content: imageSelectorView)
        .sheet(isPresented: $showMediaDetails, content: mediaDetailsView)
        .sheet(isPresented: $showFixMatchView, onDismiss: refreshDetails, content: fixMatchView)
        .alert("Êtes-vous sûr ?", isPresented: $showingAnalysisAlert, actions: analysisAlertActions, message: analysisAlertMessage)
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
        Button("Annuler", role: .cancel) {}
        Button("Analyser", role: .destructive) {
            Task { await actionsViewModel.analyzeMedia() }
        }
    }
    
    private func analysisAlertMessage() -> some View {
        Text("Cette opération peut prendre quelques minutes et consommer des ressources sur votre serveur.")
    }
}
