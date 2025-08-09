import Foundation

@MainActor
class ImageSelectorViewModel: ObservableObject {
    @Published var posters: [PlexArtwork] = []
    @Published var isLoading = true
    @Published var hudMessage: HUDMessage?

    private let plexService: PlexAPIService
    private let serverViewModel: ServerViewModel
    private let authManager: PlexAuthManager
    private let mediaRatingKey: String
    private var hudDismissTask: Task<Void, Never>?

    init(ratingKey: String, plexService: PlexAPIService, serverViewModel: ServerViewModel, authManager: PlexAuthManager) {
        self.mediaRatingKey = ratingKey
        self.plexService = plexService
        self.serverViewModel = serverViewModel
        self.authManager = authManager
    }

    private func showHUD(message: HUDMessage, duration: TimeInterval = 2) {
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

    func artworkURL(for artwork: PlexArtwork) -> URL? {
        let imagePath = artwork.thumb ?? artwork.key

        if imagePath.starts(with: "http") {
            return URL(string: imagePath)
        }

        guard let details = getServerDetails(),
              var components = URLComponents(string: "\(details.url)/photo/:/transcode")
        else { return nil }
        
        components.queryItems = [
            URLQueryItem(name: "url", value: imagePath),
            URLQueryItem(name: "width", value: "600"),
            URLQueryItem(name: "height", value: "900"),
            URLQueryItem(name: "minSize", value: "1"),
            URLQueryItem(name: "X-Plex-Token", value: details.token)
        ]
        
        return components.url
    }

    func loadImages() async {
        guard let details = getServerDetails() else {
            isLoading = false
            return
        }
        
        isLoading = true
        
        do {
            let fetchedPosters = try await plexService.fetchArtworks(for: mediaRatingKey, serverURL: details.url, token: details.token)

            self.posters = fetchedPosters
            if self.posters.isEmpty {
                showHUD(message: HUDMessage(iconName: "xmark.circle.fill", text: "Aucune image trouvée.", maxWidth: 320))
            }
        } catch {
            print("Erreur lors du chargement des affiches: \(error.localizedDescription)")
            showHUD(message: HUDMessage(iconName: "xmark.circle.fill", text: "Erreur de chargement.", maxWidth: 320))
        }
        
        isLoading = false
    }

    func selectImage(_ artwork: PlexArtwork) async {
        guard let details = getServerDetails() else { return }

        let artworkIdentifier: String
        if artwork.key.starts(with: "http") {
                artworkIdentifier = artwork.key
        } else {
            artworkIdentifier = artwork.ratingKey ?? artwork.key
        }

        hudDismissTask?.cancel()
        hudMessage = HUDMessage(iconName: "photo", text: "Modification...")
        
        do {
            try await plexService.setArtwork(for: mediaRatingKey, artworkKey: artworkIdentifier, serverURL: details.url, token: details.token)

            var updatedPosters = self.posters

            if let oldIndex = updatedPosters.firstIndex(where: { $0.selected == true }) {
                updatedPosters[oldIndex].selected = false
            }

            if let newIndex = updatedPosters.firstIndex(where: { $0.id == artwork.id }) {
                updatedPosters[newIndex].selected = true
            }

            self.posters = updatedPosters
            showHUD(message: HUDMessage(iconName: "checkmark", text: "Image modifiée !"))
            
        } catch {
            showHUD(message: HUDMessage(iconName: "xmark", text: "Erreur lors de la modification."))
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
        return (connection.uri, resourceToken)
    }
}
