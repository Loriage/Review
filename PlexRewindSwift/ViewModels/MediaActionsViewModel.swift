import Foundation

struct ActionAlert: Identifiable {
    let id = UUID()
    let message: String
}

@MainActor
class MediaActionsViewModel: ObservableObject {
    @Published var hudMessage: HUDMessage?
    @Published var isWorking = false

    private let plexService: PlexAPIService
    let serverViewModel: ServerViewModel
    let authManager: PlexAuthManager
    private let mediaRatingKey: String
    private let mediaTitle: String

    private var hudDismissTask: Task<Void, Never>?

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

    private func getServerDetails() -> (url: String, token: String)? {
        guard let serverID = serverViewModel.selectedServerID,
              let server = serverViewModel.availableServers.first(where: { $0.id == serverID }),
              let connection = server.connections.first(where: { !$0.local }) ?? server.connections.first,
              let token = authManager.getPlexAuthToken()
        else {
            showHUD(message: HUDMessage(iconName: "xmark.circle.fill", text: "Détails du serveur indisponibles."))
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
            showHUD(message: HUDMessage(iconName: "checkmark", text: "Actualisation démarrée.", maxWidth: 180))
        } catch {
            showHUD(message: HUDMessage(iconName: "xmark", text: "Erreur lors de l'actualisation.", maxWidth: 180))
        }
        isWorking = false
    }
}
