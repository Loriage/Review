import Foundation
import SwiftUI
import Combine

@MainActor
class LibraryDetailViewModel: ObservableObject {
    let library: DisplayLibrary
    @Published var mediaItems: [MediaMetadata] = []

    @Published var chartData: [(Date, Int)] = []
    @Published var state: ViewState = .loading

    @Published var canLoadMoreMedia = true
    private var currentPage = 0
    private var totalMediaCount: Int? = nil
    private let pageSize = 30

    private let plexService: PlexAPIService
    private let serverViewModel: ServerViewModel
    private let authManager: PlexAuthManager
    private var cancellables = Set<AnyCancellable>()

    enum ViewState {
        case loading
        case content
        case error(String)
    }

    init(library: DisplayLibrary, serverViewModel: ServerViewModel, authManager: PlexAuthManager, plexService: PlexAPIService = PlexAPIService()) {
        self.library = library
        self.serverViewModel = serverViewModel
        self.authManager = authManager
        self.plexService = plexService
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

            let allMedia = try await plexService.fetchAllMediaInSection(
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
            print("Erreur lors de la génération des données du graphique: \(error.localizedDescription)")
        }
    }

    private func fetchMediaPage() async {
        guard let serverDetails = getServerDetails() else {
            state = .error("Serveur non sélectionné ou informations manquantes.")
            return
        }
        
        do {
            let mediaType = library.library.type == "movie" ? 1 : 2
            let (newMedia, totalCount) = try await plexService.fetchMediaFromSection(
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
}
