import Foundation

struct ActionAlert: Identifiable {
    let id = UUID()
    let message: String
}

@MainActor
class MediaActionsViewModel: ObservableObject {
    @Published var hudMessage: HUDMessage?
    @Published var isWorking = false
    @Published var alert: ActionAlert?

    private let plexService: PlexAPIService
    private let serverViewModel: ServerViewModel
    private let authManager: PlexAuthManager
    private let mediaRatingKey: String
    private let mediaTitle: String

    init(session: PlexActivitySession, plexService: PlexAPIService, serverViewModel: ServerViewModel, authManager: PlexAuthManager) {
        self.plexService = plexService
        self.serverViewModel = serverViewModel
        self.authManager = authManager

        if session.type == "episode", let seriesRatingKey = session.grandparentRatingKey, let seriesTitle = session.grandparentTitle {
            self.mediaRatingKey = seriesRatingKey
            self.mediaTitle = seriesTitle
        } else {
            self.mediaRatingKey = session.ratingKey
            self.mediaTitle = session.title
        }
    }

    private func getServerDetails() -> (url: String, token: String)? {
        guard let serverID = serverViewModel.selectedServerID,
              let server = serverViewModel.availableServers.first(where: { $0.id == serverID }),
              let connection = server.connections.first(where: { !$0.local }) ?? server.connections.first,
              let token = authManager.getPlexAuthToken()
        else {
            alert = ActionAlert(message: "Les détails du serveur sont indisponibles.")
            return nil
        }
        let resourceToken = server.accessToken ?? token
        return (connection.uri, resourceToken)
    }

    func refreshMetadata() async {
        guard let details = getServerDetails() else { return }
        isWorking = true
        do {
            try await plexService.refreshMetadata(for: mediaRatingKey, serverURL: details.url, token: details.token)
            hudMessage = HUDMessage(iconName: "checkmark", text: "Actualisation démarrée.", maxWidth: 180)
        } catch {
            hudMessage = HUDMessage(iconName: "xmark", text: "Erreur lors de l'actualisation.", maxWidth: 180)
        }
        isWorking = false
    }

    func analyzeMedia() async {
        guard let details = getServerDetails() else { return }
        isWorking = true
        do {
            try await plexService.analyzeMedia(for: mediaRatingKey, serverURL: details.url, token: details.token)
            hudMessage = HUDMessage(iconName: "checkmark", text: "L'analyse a démarré", maxWidth: 180)
        } catch {
            hudMessage = HUDMessage(iconName: "xmark", text: "Erreur lors de l'analyse.", maxWidth: 180)
        }
        isWorking = false
    }

    func fixMatch() async {
        hudMessage = HUDMessage(iconName: "xmark", text: "La correction d'association n'est pas encore implémentée.")
    }

    func changeImage() async {
        hudMessage = HUDMessage(iconName: "xmark", text: "Le changement d'image n'est pas encore implémenté.")
    }
}
