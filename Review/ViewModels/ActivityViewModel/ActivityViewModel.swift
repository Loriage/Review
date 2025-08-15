import Foundation
import Combine
import SwiftUI

@MainActor
class ActivityViewModel: ObservableObject {
    @Published var state: ViewState = .noServerSelected
    @Published var activityCount: Int = 0
    @Published var hudMessage: HUDMessage?
    
    private let serverViewModel: ServerViewModel
    private let authManager: PlexAuthManager
    private let activityService: PlexActivityService
    private let actionsService: PlexActionsService
    private let geolocationService = GeolocationService()
    private var cancellables = Set<AnyCancellable>()
    private var hudDismissTask: Task<Void, Never>?
    
    init(serverViewModel: ServerViewModel, authManager: PlexAuthManager, activityService: PlexActivityService = PlexActivityService(), actionsService: PlexActionsService = PlexActionsService()) {
        self.serverViewModel = serverViewModel
        self.authManager = authManager
        self.activityService = activityService
        self.actionsService = actionsService
        setupBindings()
    }
    
    private func setupBindings() {
        serverViewModel.$selectedServerID
            .sink { [weak self] _ in
                Task {
                    await self?.refreshActivity()
                }
            }
            .store(in: &cancellables)
    }

    func refreshActivity() async {
        guard let serverID = serverViewModel.selectedServerID,
              let server = serverViewModel.availableServers.first(where: { $0.id == serverID }),
              let connection = server.connections.first(where: { !$0.local }) ?? server.connections.first,
              let token = serverViewModel.authManager.getPlexAuthToken()
        else {
            self.state = .noServerSelected
            self.activityCount = 0
            return
        }
        
        let serverURL = connection.uri
        let resourceToken = server.accessToken ?? token
        
        do {
            var sessions = try await activityService.fetchCurrentActivity(serverURL: serverURL, token: resourceToken)
            
            for i in sessions.indices {
                let session = sessions[i]

                let posterRatingKey = session.type == "episode" ? session.grandparentRatingKey ?? session.ratingKey : session.ratingKey

                let urlString = "\(serverURL)/library/metadata/\(posterRatingKey)/thumb?X-Plex-Token=\(resourceToken)"
                sessions[i].posterURL = URL(string: urlString)
                
                if !session.player.local {
                    sessions[i].location = await geolocationService.fetchLocation(for: session.player.address)
                }
            }
            
            if sessions.isEmpty {
                self.state = .empty
                self.activityCount = 0
            } else {
                self.state = .content(sessions)
                self.activityCount = sessions.count
            }
            
        } catch let error as PlexError {
            if case .serverError(let statusCode) = error, statusCode == 403 {
                self.state = .forbidden
            } else {
                self.state = .empty
            }
            self.activityCount = 0
        } catch {
            self.state = .empty
            self.activityCount = 0
        }
    }

    func refreshMetadata(for session: PlexActivitySession) async {
        guard let details = getServerDetails() else { return }
        showHUD(message: HUDMessage(iconName: "arrow.triangle.2.circlepath", text: "hud.refreshing"))
        do {
            try await actionsService.refreshMetadata(for: session.ratingKey, serverURL: details.url, token: details.token)
            showHUD(message: HUDMessage(iconName: "checkmark", text: "hud.refresh.started"))
        } catch {
            showHUD(message: HUDMessage(iconName: "xmark", text: "common.error"))
        }
    }

    func analyzeMedia(for session: PlexActivitySession) async {
        guard let details = getServerDetails() else { return }
        showHUD(message: HUDMessage(iconName: "wand.and.rays", text: "hud.analyzing"))
        do {
            try await actionsService.analyzeMedia(for: session.ratingKey, serverURL: details.url, token: details.token)
            showHUD(message: HUDMessage(iconName: "checkmark", text: "hud.analyze.started"))
        } catch {
            showHUD(message: HUDMessage(iconName: "xmark", text: "common.error"))
        }
    }
    
    func stopPlayback(for session: PlexActivitySession, reason: String) async {
        guard let details = getServerDetails() else { return }
        showHUD(message: HUDMessage(iconName: "stop.circle", text: "hud.stopping.playback"))
        do {
            try await actionsService.stopPlayback(sessionId: session.session.id, reason: reason.isEmpty ? "Arrêt depuis Review" : reason, serverURL: details.url, token: details.token)
            showHUD(message: HUDMessage(iconName: "checkmark", text: "hud.stopping.playback"))
        } catch {
            showHUD(message: HUDMessage(iconName: "xmark", text: "hud.error.playback"))
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
