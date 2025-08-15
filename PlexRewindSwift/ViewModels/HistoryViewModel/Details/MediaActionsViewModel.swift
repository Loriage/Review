import Foundation

@MainActor
class MediaActionsViewModel: ObservableObject {
    @Published var hudMessage: HUDMessage?
    @Published var isWorking = false

    private let actionsService: PlexActionsService
    let serverViewModel: ServerViewModel
    let authManager: PlexAuthManager
    private var mediaRatingKey: String

    private var hudDismissTask: Task<Void, Never>?

    init(ratingKey: String, actionsService: PlexActionsService, serverViewModel: ServerViewModel, authManager: PlexAuthManager) {
        self.actionsService = actionsService
        self.serverViewModel = serverViewModel
        self.authManager = authManager
        self.mediaRatingKey = ratingKey
    }

    func update(ratingKey: String) {
        self.mediaRatingKey = ratingKey
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
            showHUD(message: HUDMessage(iconName: "xmark.circle.fill", text: "hud.server.details.unavailable"))
            return nil
        }
        let resourceToken = server.accessToken ?? token
        return (connection.uri, resourceToken)
    }

    func refreshMetadata() async {
        guard let details = getServerDetails() else { return }
        isWorking = true
        do {
            try await actionsService.refreshMetadata(for: mediaRatingKey, serverURL: details.url, token: details.token)
            showHUD(message: HUDMessage(iconName: "checkmark", text: "hud.refresh.started", maxWidth: 180))
        } catch {
            showHUD(message: HUDMessage(iconName: "xmark", text: "hud.error.updating", maxWidth: 180))
        }
        isWorking = false
    }

    func analyzeMedia() async {
        guard let details = getServerDetails() else { return }
        isWorking = true
        do {
            try await actionsService.analyzeMedia(for: mediaRatingKey, serverURL: details.url, token: details.token)
            showHUD(message: HUDMessage(iconName: "checkmark", text: "hud.running.analyze.started", maxWidth: 180))
        } catch {
            showHUD(message: HUDMessage(iconName: "xmark", text: "hud.analyze.error", maxWidth: 180))
        }
        isWorking = false
    }
}
