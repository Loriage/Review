import Foundation

@MainActor
class ActivityActionsViewModel: ObservableObject {
    @Published var hudMessage: HUDMessage?

    let session: PlexActivitySession
    private let actionsService: PlexActionsService
    private let serverViewModel: ServerViewModel
    private let authManager: PlexAuthManager
    private var hudDismissTask: Task<Void, Never>?

    init(session: PlexActivitySession, serverViewModel: ServerViewModel, authManager: PlexAuthManager, actionsService: PlexActionsService = PlexActionsService()) {
        self.session = session
        self.serverViewModel = serverViewModel
        self.authManager = authManager
        self.actionsService = actionsService
    }

    func refreshMetadata() async {
        guard let details = getServerDetails() else { return }

        showHUD(message: HUDMessage(iconName: "arrow.triangle.2.circlepath", text: "Actualisation..."))
        do {
            try await actionsService.refreshMetadata(for: session.ratingKey, serverURL: details.url, token: details.token)
            showHUD(message: HUDMessage(iconName: "checkmark", text: "Actualisation démarrée !"))
        } catch {
            showHUD(message: HUDMessage(iconName: "xmark", text: "Erreur."))
        }
    }

    func analyzeMedia() async {
        guard let details = getServerDetails() else { return }

        showHUD(message: HUDMessage(iconName: "wand.and.rays", text: "Analyse..."))
        do {
            try await actionsService.analyzeMedia(for: session.ratingKey, serverURL: details.url, token: details.token)
            showHUD(message: HUDMessage(iconName: "checkmark", text: "Analyse démarrée !"))
        } catch {
            showHUD(message: HUDMessage(iconName: "xmark", text: "Erreur."))
        }
    }
    
    func stopPlayback(reason: String) async {
        guard let details = getServerDetails() else { return }
        showHUD(message: HUDMessage(iconName: "stop.circle", text: "Arrêt en cours..."))
        do {
            try await actionsService.stopPlayback(sessionId: session.session.id, reason: reason.isEmpty ? "Arrêt depuis Plex Rewind" : reason, serverURL: details.url, token: details.token)
            showHUD(message: HUDMessage(iconName: "checkmark", text: "Lecture arrêtée !"))
        } catch {
            showHUD(message: HUDMessage(iconName: "xmark", text: "Erreur lors de l'arrêt."))
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
}
