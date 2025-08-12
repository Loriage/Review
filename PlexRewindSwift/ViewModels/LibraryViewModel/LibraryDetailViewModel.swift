import Foundation
import SwiftUI
import Combine

@MainActor
class LibraryDetailViewModel: ObservableObject {
    let library: DisplayLibrary
    @Published var mediaItems: [MediaMetadata] = []

    @Published var chartData: [(Date, Int)] = []
    @Published var state: ViewState = .loading
    @Published var hudMessage: HUDMessage?

    @Published var canLoadMoreMedia = true
    private var currentPage = 0
    private var totalMediaCount: Int? = nil
    private let pageSize = 30

    private let libraryService: PlexLibraryService
    private let actionsService: PlexActionsService
    let serverViewModel: ServerViewModel
    let authManager: PlexAuthManager
    let statsViewModel: StatsViewModel

    private var cancellables = Set<AnyCancellable>()
    private var hudDismissTask: Task<Void, Never>?

    enum ViewState {
        case loading
        case content
        case error(String)
    }

    init(library: DisplayLibrary, serverViewModel: ServerViewModel, authManager: PlexAuthManager, statsViewModel: StatsViewModel, libraryService: PlexLibraryService = PlexLibraryService(), actionsService: PlexActionsService = PlexActionsService()) {
        self.library = library
        self.serverViewModel = serverViewModel
        self.authManager = authManager
        self.statsViewModel = statsViewModel
        self.libraryService = libraryService
        self.actionsService = actionsService
    }

    func loadInitialContent() async {
        guard case .loading = state else { return }

        async let fetchMediaTask: () = fetchMediaPage()
        async let generateChartDataTask: () = generateChartData()
        
        _ = await (fetchMediaTask, generateChartDataTask)
    }

    func loadMoreContentIfNeeded(currentItem item: MediaMetadata?) async {
        guard case .content = state, canLoadMoreMedia, let item = item else {
            return
        }

        let thresholdIndex = mediaItems.index(mediaItems.endIndex, offsetBy: -5)
        if mediaItems.firstIndex(where: { $0.id == item.id }) == thresholdIndex {
            await fetchMediaPage()
        }
    }

    private func generateChartData() async {
        guard let serverDetails = getServerDetails() else { return }
        
        do {
            let mediaType = library.library.type == "movie" ? 1 : (library.library.type == "show" ? 2 : 4)

            let allMedia = try await libraryService.fetchAllMediaInSection(
                serverURL: serverDetails.url,
                token: serverDetails.token,
                libraryKey: library.library.key,
                mediaType: mediaType
            )

            let sortedMedia = allMedia
                .compactMap { item -> Date? in
                    guard let addedAtTimestamp = item.addedAt else { return nil }
                    return Date(timeIntervalSince1970: TimeInterval(addedAtTimestamp))
                }
                .sorted()
            
            var cumulativeCount = 0
            let dataPoints = sortedMedia.map { date -> (Date, Int) in
                cumulativeCount += 1
                return (date, cumulativeCount)
            }
            
            self.chartData = dataPoints
            
        } catch {
        }
    }

    private func fetchMediaPage() async {
        guard let serverDetails = getServerDetails() else {
            state = .error("Serveur non sélectionné ou informations manquantes.")
            return
        }
        
        do {
            let mediaType = library.library.type == "movie" ? 1 : 2
            let (newMedia, totalCount) = try await libraryService.fetchMediaFromSection(
                serverURL: serverDetails.url,
                token: serverDetails.token,
                libraryKey: library.library.key,
                mediaType: mediaType,
                page: currentPage,
                pageSize: pageSize
            )

            if self.totalMediaCount == nil {
                self.totalMediaCount = totalCount
            }

            self.mediaItems.append(contentsOf: newMedia)
            self.currentPage += 1

            if self.mediaItems.count >= self.totalMediaCount ?? 0 {
                self.canLoadMoreMedia = false
            }

            self.state = .content

        } catch {
            state = .error("Impossible de charger le contenu: \(error.localizedDescription)")
            self.canLoadMoreMedia = false
        }
    }

    private func getServerDetails() -> (url: String, token: String)? {
        guard let serverID = serverViewModel.selectedServerID,
              let server = serverViewModel.availableServers.first(where: { $0.id == serverID }),
              let connection = server.connections.first(where: { !$0.local }) ?? server.connections.first,
              let token = authManager.getPlexAuthToken()
        else {
            return nil
        }
        let resourceToken = server.accessToken ?? token
        return (url: connection.uri, token: resourceToken)
    }

    func posterURL(for item: MediaMetadata) -> URL? {
        guard let thumbPath = item.thumb,
              let serverDetails = getServerDetails()
        else {
            return nil
        }
        let urlString = "\(serverDetails.url)\(thumbPath)?X-Plex-Token=\(serverDetails.token)"
        return URL(string: urlString)
    }

    func scanLibrary() async {
        guard let details = getServerDetails() else {
            showHUD(message: HUDMessage(iconName: "xmark.circle.fill", text: "Détails du serveur indisponibles.", maxWidth: 180))
            return
        }
        
        showHUD(message: HUDMessage(iconName: "waveform.path.ecg", text: "Lancement du scan...", maxWidth: 180))
        
        do {
            try await libraryService.scanLibrary(serverURL: details.url, token: details.token, libraryKey: library.library.key)
            showHUD(message: HUDMessage(iconName: "checkmark", text: "Scan de la bibliothèque démarré.", maxWidth: 180))
        } catch {
            showHUD(message: HUDMessage(iconName: "xmark", text: "Erreur lors du lancement du scan.", maxWidth: 180))
        }
    }

    func refreshMetadata() async {
        guard let details = getServerDetails() else {
            showHUD(message: HUDMessage(iconName: "xmark.circle.fill", text: "Détails du serveur indisponibles.", maxWidth: 180))
            return
        }
        
        showHUD(message: HUDMessage(iconName: "arrow.trianglehead.counterclockwise", text: "Lancement de l'actualisation...", maxWidth: 180))
        
        do {
            try await libraryService.scanLibrary(serverURL: details.url, token: details.token, libraryKey: library.library.key, force: true)
            showHUD(message: HUDMessage(iconName: "checkmark", text: "Actualisation démarrée.", maxWidth: 180))
        } catch {
            showHUD(message: HUDMessage(iconName: "xmark", text: "Erreur lors de l'actualisation.", maxWidth: 180))
        }
    }

    func analyzeLibrary() async {
        guard let details = getServerDetails() else {
            showHUD(message: HUDMessage(iconName: "xmark.circle.fill", text: "Détails du serveur indisponibles.", maxWidth: 180))
            return
        }
        
        showHUD(message: HUDMessage(iconName: "wand.and.rays", text: "Lancement de l'analyse...", maxWidth: 180))
        
        do {
            try await actionsService.analyzeLibrarySection(libraryKey: library.library.key, serverURL: details.url, token: details.token)
            showHUD(message: HUDMessage(iconName: "checkmark", text: "Analyse de la bibliothèque démarrée.", maxWidth: 180))
        } catch {
            showHUD(message: HUDMessage(iconName: "xmark", text: "Erreur lors du lancement de l'analyse.", maxWidth: 180))
        }
    }

    func emptyTrash() async {
        guard let details = getServerDetails() else {
            showHUD(message: HUDMessage(iconName: "xmark.circle.fill", text: "Détails du serveur indisponibles.", maxWidth: 180))
            return
        }
        
        showHUD(message: HUDMessage(iconName: "trash", text: "Lancement du nettoyage...", maxWidth: 180))
        
        do {
            try await actionsService.emptyLibraryTrash(libraryKey: library.library.key, serverURL: details.url, token: details.token)
            showHUD(message: HUDMessage(iconName: "checkmark", text: "Corbeille de la bibliothèque vidée."))
        } catch {
            showHUD(message: HUDMessage(iconName: "xmark", text: "Erreur lors du nettoyage de la corbeille."))
        }
    }

    private func showHUD(message: HUDMessage, duration: TimeInterval = 2.5) {
        hudDismissTask?.cancel()
        self.hudMessage = message
        hudDismissTask = Task {
            try? await Task.sleep(nanoseconds: UInt64(duration * 1_000_000_000))
            guard !Task.isCancelled else { return }
            if self.hudMessage == message {
                self.hudMessage = nil
            }
        }
    }
}
