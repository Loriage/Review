import Foundation

@MainActor
class LibrarySettingsViewModel: ObservableObject {
    let library: DisplayLibrary

    @Published var visibility: LibraryVisibility = .includeInHomeAndSearch
    @Published var enableTrailers: Bool = false
    @Published var hudMessage: HUDMessage?

    private let plexService: PlexAPIService
    private let serverViewModel: ServerViewModel
    private let authManager: PlexAuthManager

    private var initialVisibility: LibraryVisibility = .includeInHomeAndSearch
    private var initialEnableTrailers: Bool = false
    private var hudDismissTask: Task<Void, Never>?

    var hasChanges: Bool {
        return visibility != initialVisibility || enableTrailers != initialEnableTrailers
    }

    init(library: DisplayLibrary, serverViewModel: ServerViewModel, authManager: PlexAuthManager, plexService: PlexAPIService = PlexAPIService()) {
        self.library = library
        self.serverViewModel = serverViewModel
        self.authManager = authManager
        self.plexService = plexService

        self.visibility = LibraryVisibility(rawValue: library.library.hidden) ?? .includeInHomeAndSearch
        if let trailersSetting = library.library.preferences?.settings.first(where: { $0.id == "enableCinemaTrailers" }) {
            self.enableTrailers = (trailersSetting.value == "true")
        } else {
            self.enableTrailers = false
        }
        
        self.initialVisibility = self.visibility
        self.initialEnableTrailers = self.enableTrailers
    }

    func saveChanges() async {
        guard let details = getServerDetails() else {
            showHUD(message: HUDMessage(iconName: "xmark.circle.fill", text: "Détails du serveur indisponibles."))
            return
        }

        var preferencesToUpdate: [String: String] = [:]

        if visibility != initialVisibility {
            preferencesToUpdate["prefs[hidden]"] = "\(visibility.rawValue)"
        }

        if enableTrailers != initialEnableTrailers {
            preferencesToUpdate["prefs[enableCinemaTrailers]"] = enableTrailers ? "1" : "0"
        }

        do {
            try await plexService.updateLibraryPreferences(for: library.library.key, preferences: preferencesToUpdate, serverURL: details.url, token: details.token)
            showHUD(message: HUDMessage(iconName: "checkmark", text: "Paramètres mis à jour !"))
            
            self.initialVisibility = visibility
            self.initialEnableTrailers = enableTrailers
        } catch {
            showHUD(message: HUDMessage(iconName: "xmark", text: "Erreur lors de la mise à jour."))
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
