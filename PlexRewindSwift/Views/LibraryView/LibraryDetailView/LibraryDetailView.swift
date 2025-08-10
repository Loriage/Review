import SwiftUI
import Charts

struct LibraryDetailView: View {
    @StateObject private var viewModel: LibraryDetailViewModel
    @ObservedObject private var library: DisplayLibrary
    @EnvironmentObject var serverViewModel: ServerViewModel
    @EnvironmentObject var authManager: PlexAuthManager
    @EnvironmentObject var statsViewModel: StatsViewModel

    @State private var showingSettings = false
    @State private var showingRefreshAlert = false
    @State private var showingAnalyzeAlert = false
    @State private var showingEmptyTrashAlert = false
    @State private var navigateToLibrarySettings = false
    @State private var sheetHeight: CGFloat = 250

    private let columns = [GridItem(.adaptive(minimum: 110), spacing: 10)]

    init(library: DisplayLibrary, serverViewModel: ServerViewModel, authManager: PlexAuthManager) {
        _viewModel = StateObject(wrappedValue: LibraryDetailViewModel(
            library: library,
            serverViewModel: serverViewModel,
            authManager: authManager
        ))
        self.library = library
    }

    var body: some View {
        ZStack {
            ScrollView {
                VStack(spacing: 12) {
                    statsSection
                    
                    if !viewModel.chartData.isEmpty {
                        MediaGrowthChartView(data: viewModel.chartData)
                    }
                    
                    switch viewModel.state {
                    case .loading:
                        ProgressView()
                            .padding(.top, 40)
                    case .content:
                        mediaGridView
                    case .error(let message):
                        Text(message)
                            .foregroundColor(.red)
                            .padding()
                    }
                }
                .padding(.horizontal)
            }
            .navigationTitle(viewModel.library.library.title)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showingSettings = true }) {
                        Image(systemName: "gearshape.fill")
                    }
                }
            }
            .sheet(isPresented: $showingSettings) {
                librarySettingsSheet
                    .presentationDetents([.height(sheetHeight)])
                    .presentationDragIndicator(.visible)
            }
            .navigationDestination(isPresented: $navigateToLibrarySettings) {
                LibrarySettingsView(library: library, serverViewModel: serverViewModel, authManager: authManager)
            }
            .alert("Êtes-vous sûr ?", isPresented: $showingRefreshAlert) {
                Button("Annuler", role: .cancel) {}
                Button("Actualiser", role: .destructive) {
                    Task {
                        await viewModel.refreshMetadata()
                    }
                }
            } message: {
                Text("Cette opération peut prendre du temps et consommer des ressources sur votre serveur Plex.")
            }
            .alert("Lancer une analyse complète ?", isPresented: $showingAnalyzeAlert) {
                Button("Annuler", role: .cancel) {}
                Button("Analyser", role: .destructive) {
                    Task {
                        await viewModel.analyzeLibrary()
                    }
                }
            } message: {
                Text("Analyse tous les médias de la bibliothèque.\n\nL'analyse permet à Plex de collecter des informations pour optimiser la lecture de chaque média.")
            }
            .alert("Vider la corbeille ?", isPresented: $showingEmptyTrashAlert) {
                Button("Annuler", role: .cancel) {}
                Button("Vider", role: .destructive) {
                    Task {
                        await viewModel.emptyTrash()
                    }
                }
            } message: {
                Text("Par défaut, le serveur de médias ne détruit pas immédiatement les informations concernant les médias.\n\nCela est utile quand un lecteur est temporairement déconnecté.\n\nLorsque vous videz la corbeille pour une section, toutes les informations sur les médias manquants sont supprimées.")
            }
            .task {
                await viewModel.loadInitialContent()
            }

            if let hudMessage = viewModel.hudMessage {
                HUDView(hudMessage: hudMessage)
                    .transition(.scale.combined(with: .opacity))
                    .animation(.spring(), value: viewModel.hudMessage)
            }
        }
    }

    private var mediaGridView: some View {
        VStack(alignment: .leading, spacing: 10) {
            LazyVGrid(columns: columns, spacing: 10) {
                ForEach(viewModel.mediaItems) { media in
                    mediaCell(for: media)
                }
            }
        }
    }

    private func mediaCell(for media: MediaMetadata) -> some View {
        NavigationLink(destination: MediaHistoryView(
            ratingKey: media.ratingKey,
            mediaType: media.type,
            grandparentRatingKey: media.type == "show" ? media.ratingKey : media.grandparentRatingKey,
            serverViewModel: serverViewModel,
            authManager: authManager,
            statsViewModel: statsViewModel
        )) {
            AsyncImageView(url: viewModel.posterURL(for: media))
                .aspectRatio(2/3, contentMode: .fill)
                .cornerRadius(8)
                .shadow(color: .black.opacity(0.25), radius: 2, y: 2)
        }
        .buttonStyle(.plain)
        .task(id: media.id) {
            await viewModel.loadMoreContentIfNeeded(currentItem: media)
        }
    }

    private var statsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 10) {
                if viewModel.library.library.type == "movie" {
                    InfoPill(
                        title: "Films",
                        value: library.fileCount != nil ? "\(library.fileCount!)" : "...",
                    )
                    InfoPill(
                        title: "Taille",
                        value: library.size != nil ? "\(formatBytes(library.size!))" : "...",
                    )
                } else if viewModel.library.library.type == "show" {
                    InfoPill(
                        title: "Séries",
                        value: library.fileCount != nil ? "\(library.fileCount!)" : "...",
                    )
                    InfoPill(
                        title: "Épisodes",
                        value: library.episodesCount != nil ? "\(library.episodesCount!)" : "...",
                    )
                    InfoPill(
                        title: "Taille",
                        value: library.size != nil ? "\(formatBytes(library.size!))" : "...",
                    )
                }
            }
        }
    }

    struct MediaGrowthChartView: View {
        let data: [(Date, Int)]
        
        var body: some View {
            VStack(alignment: .leading) {
                Text("Croissance de la bibliothèque")
                    .font(.headline.bold())
                    .padding(.bottom, 10)
                
                Chart {
                    ForEach(data, id: \.0) { date, count in
                        LineMark(
                            x: .value("Date", date),
                            y: .value("Nombre de médias", count)
                        )
                        .interpolationMethod(.linear)
                        .foregroundStyle(Color.accentColor)

                        AreaMark(
                            x: .value("Date", date),
                            y: .value("Nombre de médias", count)
                        )
                        .interpolationMethod(.linear)
                        .foregroundStyle(
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    Color.accentColor.opacity(0.4),
                                    Color.accentColor.opacity(0.01)
                                ]),
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                    }
                }
                .chartXAxis {
                    AxisMarks(values: .automatic(desiredCount: 5)) { value in
                        AxisGridLine()
                        AxisValueLabel(format: .dateTime.month(.twoDigits).year(.twoDigits))
                    }
                }
                .chartYAxis {
                    AxisMarks(position: .leading)
                }
                .frame(height: 180)
            }
            .padding()
            .background(.thinMaterial)
            .cornerRadius(16)
        }
    }

    private func formattedLibraryTypeName(for type: String) -> String {
        switch type {
        case "movie":
            return "films"
        case "show":
            return "séries"
        case "artist":
            return "musiques"
        case "photo":
            return "photos"
        default:
            return "éléments"
        }
    }

    private func formatBytes(_ bytes: Int64) -> String {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useGB, .useMB, .useTB]
        formatter.countStyle = .binary
        return formatter.string(fromByteCount: bytes)
    }

    @ViewBuilder
    private var librarySettingsSheet: some View {
        VStack(alignment: .leading, spacing: 24) {
            Button {
                showingSettings = false
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    navigateToLibrarySettings = true
                }
            } label: {
                Label("Paramètres de la bibliothèque", systemImage: "gearshape.fill")
            }

            Button {
                showingSettings = false
                Task {
                    await viewModel.scanLibrary()
                }
            } label: {
                Label("Scanner la bibliothèque", systemImage: "waveform.path.ecg")
            }
            
            Button {
                showingSettings = false
                showingRefreshAlert = true
            } label: {
                Label("Actualiser les métadonnées", systemImage: "arrow.trianglehead.counterclockwise")
            }
            
            Button {
                showingSettings = false
                showingAnalyzeAlert = true
            } label: {
                Label("Analyser", systemImage: "wand.and.rays")
            }
            
            Button {
                showingSettings = false
                showingEmptyTrashAlert = true
            } label: {
                Label("Vider la corbeille", systemImage: "trash")
            }
        }
        .font(.headline)
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal)
        .padding(.top, 20)
        .foregroundColor(.primary)
        .presentationBackground(.regularMaterial)
        .onAppear {
            sheetHeight = 260
        }
    }
}
