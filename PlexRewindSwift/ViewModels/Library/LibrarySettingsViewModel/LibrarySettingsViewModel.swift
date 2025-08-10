import Foundation

struct LibraryPreferences: Equatable {
    var visibility: LibraryVisibility
    var enableTrailers: Bool
}

@MainActor
class LibrarySettingsViewModel: ObservableObject {
    let library: DisplayLibrary

    @Published var preferences: LibraryPreferences
    @Published var hudMessage: HUDMessage?
    
    private var initialPreferences: LibraryPreferences
    
    private let plexService: PlexAPIService
    private let serverViewModel: ServerViewModel
    private let authManager: PlexAuthManager

    private var hudDismissTask: Task<Void, Never>?

    var hasChanges: Bool {
        return preferences != initialPreferences
    }
    
    init(library: DisplayLibrary, serverViewModel: ServerViewModel, authManager: PlexAuthManager, plexService: PlexAPIService = PlexAPIService()) {
        self.library = library
        self.serverViewModel = serverViewModel
        self.authManager = authManager
        self.plexService = plexService

        let visibility = LibraryVisibility(rawValue: library.library.hidden) ?? .includeInHomeAndSearch
        let enableTrailers: Bool
        if let trailersSetting = library.library.preferences?.settings.first(where: { $0.id == "enableCinemaTrailers" }) {
            enableTrailers = (trailersSetting.value == "true")
        } else {
            enableTrailers = false
        }
        
        let prefs = LibraryPreferences(visibility: visibility, enableTrailers: enableTrailers)
        self.preferences = prefs
        self.initialPreferences = prefs
    }

    func refreshState() {
        let visibility = LibraryVisibility(rawValue: library.library.hidden) ?? .includeInHomeAndSearch
        let enableTrailers: Bool
        if let trailersSetting = library.library.preferences?.settings.first(where: { $0.id == "enableCinemaTrailers" }) {
            enableTrailers = (trailersSetting.value == "true")
        } else {
            enableTrailers = false
        }
        
        let prefs = LibraryPreferences(visibility: visibility, enableTrailers: enableTrailers)
        self.preferences = prefs
        self.initialPreferences = prefs
    }

    func saveChanges() async {
        guard let details = getServerDetails() else {
            showHUD(message: HUDMessage(iconName: "xmark.circle.fill", text: "Détails du serveur indisponibles."))
            return
        }
        
        var preferencesToUpdate: [String: String] = [:]
        
        if preferences.visibility != initialPreferences.visibility {
            preferencesToUpdate["prefs[hidden]"] = "\(preferences.visibility.rawValue)"
        }
        
        if preferences.enableTrailers != initialPreferences.enableTrailers {
            preferencesToUpdate["prefs[enableCinemaTrailers]"] = preferences.enableTrailers ? "1" : "0"
        }
        
        guard !preferencesToUpdate.isEmpty else { return }
        
        do {
            try await plexService.updateLibraryPreferences(for: library.library.key, preferences: preferencesToUpdate, serverURL: details.url, token: details.token)
            showHUD(message: HUDMessage(iconName: "checkmark", text: "Paramètres mis à jour !"))

            self.initialPreferences = preferences

            NotificationCenter.default.post(name: .didUpdateLibraryPreferences, object: nil)
            
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
