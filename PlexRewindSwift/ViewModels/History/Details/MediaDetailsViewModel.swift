import Foundation

@MainActor
class MediaDetailsViewModel: ObservableObject {
    @Published var mediaDetails: MediaDetails?
    @Published var mediaInfo: PlexMediaPartContainer?
    @Published var videoStream: StreamDetails?
    @Published var audioStream: StreamDetails?
    @Published var isLoading = true
    
    private let ratingKey: String
    private let plexService: PlexAPIService
    private let serverViewModel: ServerViewModel
    private let authManager: PlexAuthManager

    init(ratingKey: String, plexService: PlexAPIService, serverViewModel: ServerViewModel, authManager: PlexAuthManager) {
        self.ratingKey = ratingKey
        self.plexService = plexService
        self.serverViewModel = serverViewModel
        self.authManager = authManager
    }

    func loadDetails() async {
        guard let serverDetails = getServerDetails() else {
            isLoading = false
            return
        }
        
        isLoading = true
        do {
            let details = try await plexService.fetchFullMediaDetails(for: ratingKey, serverURL: serverDetails.url, token: serverDetails.token)

            if let media = details?.media.first {
                self.mediaDetails = details
                self.mediaInfo = media

                self.videoStream = media.parts.first?.streams?.first(where: { $0.streamType == 1 })
                self.audioStream = media.parts.first?.streams?.first(where: { $0.streamType == 2 })
            }
        } catch {
            print("Erreur lors du chargement des détails du média: \(error)")
        }
        isLoading = false
    }
    
    private func getServerDetails() -> (url: String, token: String)? {
        guard let serverID = serverViewModel.selectedServerID,
              let server = serverViewModel.availableServers.first(where: { $0.id == serverID }),
              let connection = server.connections.first(where: { !$0.local }) ?? server.connections.first,
              let token = authManager.getPlexAuthToken()
        else { return nil }
        
        let resourceToken = server.accessToken ?? token
        return (connection.uri, resourceToken)
    }
}
