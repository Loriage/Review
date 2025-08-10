import SwiftUI

struct MediaHistoryView: View {
    @StateObject var viewModel: MediaHistoryViewModel
    @StateObject private var actionsViewModel: MediaActionsViewModel
    
    @EnvironmentObject var serverViewModel: ServerViewModel
    @EnvironmentObject var authManager: PlexAuthManager
    @EnvironmentObject var statsViewModel: StatsViewModel

    @State private var showingSettings = false
    @State private var showMediaDetails = false
    @State private var showImageSelector = false
    @State private var showFixMatchView = false
    @State private var showingAnalysisAlert = false
    @State private var sheetHeight: CGFloat = 250

    init(ratingKey: String, mediaType: String, grandparentRatingKey: String?, serverViewModel: ServerViewModel, authManager: PlexAuthManager, statsViewModel: StatsViewModel) {
        _viewModel = StateObject(wrappedValue: MediaHistoryViewModel(
            ratingKey: ratingKey,
            mediaType: mediaType,
            grandparentRatingKey: grandparentRatingKey,
            serverViewModel: serverViewModel,
            statsViewModel: statsViewModel,
            authManager: authManager
        ))

        _actionsViewModel = StateObject(wrappedValue: MediaActionsViewModel(
            ratingKey: grandparentRatingKey ?? ratingKey,
            plexService: PlexAPIService(),
            serverViewModel: serverViewModel,
            authManager: authManager
        ))
    }

    var body: some View {
        ZStack{
            Group {
                if viewModel.isLoading {
                    loadingView
                } else {
                    contentView
                }
            }
            if let hudMessage = actionsViewModel.hudMessage {
                HUDView(hudMessage: hudMessage)
                    .transition(.scale.combined(with: .opacity))
            }
        }
        .navigationTitle(viewModel.displayTitle)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: { showingSettings = true }) {
                    Image(systemName: "gearshape.fill")
                }
            }
        }
        .sheet(isPresented: $showingSettings) {
            mediaSettingsSheet
                .presentationDetents([.height(sheetHeight)])
                .presentationDragIndicator(.visible)
        }
        .alert("Êtes-vous sûr ?", isPresented: $showingAnalysisAlert) {
            Button("Annuler", role: .cancel) {}
            Button("Analyser", role: .destructive) {
                Task { await actionsViewModel.analyzeMedia() }
            }
        } message: {
            Text("Cette opération peut prendre quelques minutes et consommer des ressources sur votre serveur.")
        }
        .sheet(isPresented: $showImageSelector, onDismiss: { Task { await viewModel.refreshSessionDetails() } }) {
             ImageSelectorView(
                 ratingKey: viewModel.ratingKeyForActions,
                 serverViewModel: serverViewModel,
                 authManager: authManager
             )
        }
        .sheet(isPresented: $showMediaDetails) {
            MediaDetailsView(
                ratingKey: viewModel.ratingKey,
                serverViewModel: serverViewModel,
                authManager: authManager
            )
        }
        .sheet(isPresented: $showFixMatchView, onDismiss: { Task { await viewModel.refreshSessionDetails() } }) {
            FixMatchView(
                ratingKey: viewModel.ratingKeyForActions,
                serverViewModel: serverViewModel,
                authManager: authManager
            )
        }
        .task {
            await viewModel.loadData()
            actionsViewModel.update(ratingKey: viewModel.ratingKeyForActions)
        }
    }

    private var loadingView: some View {
        VStack(spacing: 20) {
            ProgressView().scaleEffect(1.5)
            Text("Chargement de l'historique...")
                .foregroundColor(.secondary)
        }
    }

    private var emptyView: some View {
        Section{
            VStack(spacing: 10) {
                Image(systemName: "film.stack")
                    .font(.system(size: 20))
                    .foregroundColor(.secondary)
                Text("Aucun historique trouvé")
                    .font(.title3.bold())
                Text("L'historique pour ce média est vide.")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }
            .frame(maxWidth: .infinity)
        }
        .listRowInsets(EdgeInsets())
        .listRowSeparator(.hidden)
        .listRowBackground(Color.clear)
    }

    private var contentView: some View {
        List {
            headerSection

            if viewModel.historyItems.isEmpty {
                emptyView
            } else {
                historySection
            }
        }
        .refreshable {
            await viewModel.refreshData()
        }
    }
    
    @ViewBuilder
    private var headerSection: some View {
        if viewModel.mediaDetails != nil {
            Section {
                VStack(spacing: 0) {
                    HStack {
                        AsyncImageView(url: viewModel.displayPosterURL, refreshTrigger: viewModel.imageRefreshId, contentMode: .fit)
                            .aspectRatio(2/3, contentMode: .fit)
                            .frame(height: 250)
                            .cornerRadius(16)
                            .shadow(color: .black.opacity(0.25), radius: 5, y: 5)
                    }
                    .padding(.top, 5)
                    .padding(.bottom, 20)
                    
                    if let summary = viewModel.summary, !summary.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Résumé")
                                .font(.title2.bold())
                            Text(summary)
                                .font(.body)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.bottom)
            }
            .listRowInsets(EdgeInsets())
            .listRowSeparator(.hidden)
            .listRowBackground(Color.clear)
        }
    }
    
    private var historySection: some View {
        Section(header: Text("Historique des visionnages")) {
            ForEach(viewModel.historyItems, id: \.id) { item in
                VStack(alignment: .leading, spacing: 5) {
                    if item.session.type == "episode" {
                        Text(item.session.showTitle)
                            .font(.headline)
                    } else {
                        Text(item.session.title ?? "Titre inconnu")
                            .font(.headline)
                    }
                    
                    if item.session.type == "episode" {
                        Text("S\(item.session.parentIndex ?? 0) - E\(item.session.index ?? 0) - \(item.session.title ?? "Titre inconnu")")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    
                    if let viewedAt = item.session.viewedAt {
                        Text("\(item.userName ?? "Utilisateur inconnu") - \(Date(timeIntervalSince1970: viewedAt).formatted(.relative(presentation: .named)))")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }
                .padding(.vertical, 8)
            }
        }
    }

    @ViewBuilder
    private var mediaSettingsSheet: some View {
        VStack(alignment: .leading, spacing: 24) {
            if viewModel.mediaType == "movie" {
                Button {
                    showingSettings = false
                    showMediaDetails = true
                } label: {
                    Label("Détails du média", systemImage: "info.circle")
                }
            }
            
            Button {
                showingSettings = false
                showImageSelector = true
            } label: {
                Label("Modifier l'image", systemImage: "photo")
            }
            
            Button {
                showingSettings = false
                Task { await actionsViewModel.refreshMetadata() }
            } label: {
                Label("Actualiser les métadonnées", systemImage: "arrow.clockwise")
            }
            
            Button {
                showingSettings = false
                showingAnalysisAlert = true
            } label: {
                Label("Analyser", systemImage: "wand.and.rays")
            }
            
            Button {
                showingSettings = false
                showFixMatchView = true
            } label: {
                Label("Corriger l'association...", systemImage: "pencil")
            }
        }
        .font(.headline)
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal)
        .buttonStyle(.plain)
        .foregroundColor(.primary)
        .presentationBackground(.ultraThinMaterial)
        .onAppear {
            sheetHeight = viewModel.mediaType == "movie" ? 240 : 200
        }
    }
}
