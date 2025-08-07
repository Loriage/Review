
import SwiftUI

struct MediaHistoryView: View {
    @StateObject var viewModel: MediaHistoryViewModel
    @StateObject private var actionsViewModel: MediaActionsViewModel

    @EnvironmentObject var activityViewModel: ActivityViewModel

    @ScaledMetric var width: CGFloat = 50
    @State private var showingSettings = false
    @State private var showImageSelector = false
    @State private var dominantColor: Color = Color(.systemGray4)

    init(session: PlexActivitySession, serverViewModel: ServerViewModel, authManager: PlexAuthManager, statsViewModel: StatsViewModel) {
        _viewModel = StateObject(wrappedValue: MediaHistoryViewModel(
            session: session,
            serverViewModel: serverViewModel,
            statsViewModel: statsViewModel
        ))
        _actionsViewModel = StateObject(wrappedValue: MediaActionsViewModel(
            session: session,
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
                } else if viewModel.historyItems.isEmpty {
                    emptyView
                } else {
                    contentView
                }
            }
            if let hudMessage = actionsViewModel.hudMessage {
                HUDView(hudMessage: hudMessage)
                    .transition(.scale.combined(with: .opacity))
                    .onAppear {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                            if hudMessage == actionsViewModel.hudMessage {
                                actionsViewModel.hudMessage = nil
                            }
                        }
                    }
            }
        }
        .navigationTitle(viewModel.session.showTitle)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: {
                    showingSettings = true
                }) {
                    Image(systemName: "gearshape.fill")
                }
            }
        }
        .sheet(isPresented: $showingSettings) {
            VStack(spacing: 0) {
                HStack(alignment: .center) {
                    Capsule()
                        .fill(Color.secondary)
                        .frame(width: 40, height: 5)
                        .padding(.top, 10)
                        .padding(.bottom, 30)
                }
                
                VStack(alignment: .leading, spacing: 24) {
                    Button {
                        showingSettings = false
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                            showImageSelector = true
                        }
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
                        Task { await actionsViewModel.analyzeMedia() }
                    } label: {
                        Label("Analyse", systemImage: "wand.and.rays")
                    }
                    
                    Button {
                        showingSettings = false
                        Task { await actionsViewModel.fixMatch() }
                    } label: {
                        Label("Corriger l'association...", systemImage: "pencil")
                    }
                }
                .font(.headline)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal)
                
                Spacer()
            }
            .buttonStyle(.plain)
            .foregroundColor(.primary)
            .presentationDetents([.height(220)])
            .presentationBackground(.thinMaterial)
        }
        .sheet(isPresented: $showImageSelector, onDismiss: {
            Task {
                await viewModel.refreshSession()
            }
        }) {
            ImageSelectorView(
                session: viewModel.session,
                serverViewModel: actionsViewModel.serverViewModel,
                authManager: actionsViewModel.authManager
            )
        }
        .animation(.spring(), value: actionsViewModel.hudMessage)
        .task {
            viewModel.activityViewModel = self.activityViewModel
            await viewModel.loadData()
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
        VStack(spacing: 15) {
            Image(systemName: "film.stack")
                .font(.system(size: 60))
                .foregroundColor(.secondary)
            Text("Aucun historique trouvé")
                .font(.title2.bold())
            Text("L'historique pour ce média est vide.")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        }
    }

    private var contentView: some View {
        List {
            headerSection
            historySection
        }
        .refreshable {
            await viewModel.refreshData()
        }
    }
    
    private var headerSection: some View {
        Section {
            VStack(spacing: 20) {
                HStack {
                    Spacer()

                    AsyncImageView(url: viewModel.session.posterURL, contentMode: .fit) { color in
                        self.dominantColor = color
                    }
                        .frame(height: 250)
                        .cornerRadius(16)
                        .shadow(color: .black.opacity(0.25), radius: 5, y: 5)
                    Spacer()
                }
                .padding(.top, 5)
                .padding(.bottom, 20)

                if let summary = viewModel.session.summary, !summary.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Résumé")
                            .font(.title2.bold())
                            .padding(.horizontal)
                        Text(summary)
                            .font(.body)
                            .foregroundColor(.secondary)
                            .padding(.horizontal)
                    }
                }
            }
            .padding(.bottom)
        }
        .listRowInsets(EdgeInsets())
        .listRowSeparator(.hidden)
        .listRowBackground(Color.clear)
    }
    
    private var historySection: some View {
        Section(header: Text("Historique des visionnages")) {
            ForEach(viewModel.historyItems, id: \MediaHistoryItem.id) { item in
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
                            .foregroundColor(.secondary.opacity(0.8))
                    }
                }
                .padding(.vertical, 8)
            }
        }
    }
}
