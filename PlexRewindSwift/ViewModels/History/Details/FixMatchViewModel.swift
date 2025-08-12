import Foundation

@MainActor
class FixMatchViewModel: ObservableObject {
    @Published var matches: [PlexMatch] = []
    @Published var isLoading = true
    @Published var hudMessage: HUDMessage?

    private let metadataService: PlexMetadataService
    private let actionsService: PlexActionsService
    private let serverViewModel: ServerViewModel
    private let authManager: PlexAuthManager
    private let mediaRatingKey: String

    init(ratingKey: String, metadataService: PlexMetadataService, actionsService: PlexActionsService, serverViewModel: ServerViewModel, authManager: PlexAuthManager) {
        self.mediaRatingKey = ratingKey
        self.metadataService = metadataService
        self.actionsService = actionsService
        self.serverViewModel = serverViewModel
        self.authManager = authManager
    }

    func loadMatches() async {
        guard let details = getServerDetails() else {
            isLoading = false
            return
        }
        
        isLoading = true
        do {
            let fetchedMatches = try await metadataService.fetchMatches(for: mediaRatingKey, serverURL: details.url, token: details.token)
            self.matches = fetchedMatches
        } catch {
            hudMessage = HUDMessage(iconName: "xmark", text: "Erreur de chargement des correspondances.")
        }
        isLoading = false
    }

    func selectMatch(_ match: PlexMatch) async {
        guard let details = getServerDetails() else { return }
        
        hudMessage = HUDMessage(iconName: "pencil", text: "Correction en cours...")
        
        do {
            try await actionsService.applyMatch(
                for: mediaRatingKey,
                guid: match.guid,
                name: match.name,
                year: match.year,
                serverURL: details.url,
                token: details.token
            )
            hudMessage = HUDMessage(iconName: "checkmark", text: "Association corrigée !")
        } catch {
            hudMessage = HUDMessage(iconName: "xmark", text: "Erreur lors de la correction.")
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
