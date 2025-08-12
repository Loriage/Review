import Foundation
import SwiftUI
import Combine

@MainActor
class PreferenceItemViewModel: ObservableObject, Identifiable {
    let id: String
    let label: String
    let summary: String
    let type: String
    let enumValues: [EnumValue]

    @Published var value: String
    private var initialValue: String

    var hasChanged: Bool {
        return value != initialValue
    }

    func reset() {
        self.initialValue = self.value
    }

    var boolValue: Binding<Bool> {
        Binding<Bool>(
            get: { self.value == "1" || self.value == "true" },
            set: { self.value = $0 ? "1" : "0" }
        )
    }

    init(setting: PlexSetting) {
        self.id = setting.id
        self.label = setting.label
        self.summary = setting.summary
        self.type = setting.type
        self.value = setting.value
        self.initialValue = setting.value
        
        if let enums = setting.enumValues {
            self.enumValues = enums.split(separator: "|").compactMap {
                let components = $0.split(separator: ":", maxSplits: 1)
                guard components.count == 2 else { return nil }
                return EnumValue(id: String(components[0]), name: String(components[1]))
            }
        } else {
            self.enumValues = []
        }
    }
}

@MainActor
class LibrarySettingsViewModel: ObservableObject {
    let library: DisplayLibrary
    
    @Published var preferenceItems: [PreferenceItemViewModel] = []
    @Published var hudMessage: HUDMessage?
    
    private let actionsService: PlexActionsService
    private let serverViewModel: ServerViewModel
    private let authManager: PlexAuthManager
    private var hudDismissTask: Task<Void, Never>?
    private var cancellables = Set<AnyCancellable>()

    var hasChanges: Bool {
        return preferenceItems.contains { $0.hasChanged }
    }

    init(library: DisplayLibrary, serverViewModel: ServerViewModel, authManager: PlexAuthManager, actionsService: PlexActionsService = PlexActionsService()) {
        self.library = library
        self.serverViewModel = serverViewModel
        self.authManager = authManager
        self.actionsService = actionsService
        
        self.preferenceItems = (library.library.preferences?.settings ?? [])
            .map { PreferenceItemViewModel(setting: $0) }

        self.preferenceItems.forEach { item in
            item.objectWillChange.sink { [weak self] _ in
                self?.objectWillChange.send()
            }
            .store(in: &cancellables)
        }
    }

    func saveChanges() async {
        guard let details = getServerDetails() else {
            showHUD(message: HUDMessage(iconName: "xmark.circle.fill", text: "Détails du serveur indisponibles."))
            return
        }

        let preferencesToUpdate = Dictionary(
            uniqueKeysWithValues: preferenceItems
                .filter { $0.hasChanged }
                .map { ("prefs[\($0.id)]", $0.value) }
        )

        guard !preferencesToUpdate.isEmpty else { return }

        do {
            try await actionsService.updateLibraryPreferences(for: library.library.key, preferences: preferencesToUpdate, serverURL: details.url, token: details.token)
            showHUD(message: HUDMessage(iconName: "checkmark", text: "Paramètres mis à jour !"))

            self.preferenceItems.forEach { $0.reset() }
            self.objectWillChange.send()

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
        else { return nil }
        let resourceToken = server.accessToken ?? token
        return (url: connection.uri, token: resourceToken)
    }
    
    private func showHUD(message: HUDMessage, duration: TimeInterval = 2) {
        hudDismissTask?.cancel()
        self.hudMessage = message
        hudDismissTask = Task {
            try? await Task.sleep(nanoseconds: UInt64(duration * 1_000_000_000))
            if self.hudMessage == message { self.hudMessage = nil }
        }
    }
}
