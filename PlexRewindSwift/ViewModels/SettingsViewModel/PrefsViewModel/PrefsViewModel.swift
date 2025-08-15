import Foundation
import Combine
import SwiftUI

@MainActor
class PrefsViewModel: ObservableObject {
    @Published var settingViewModels: [PlexServerSettingViewModel] = []
    @Published var isLoading = true
    @Published var showAdvanced = false
    
    private let prefsService = PlexPrefsService()
    private var cancellables = Set<AnyCancellable>()

    var hasChanges: Bool {
        settingViewModels.contains { $0.hasChanged }
    }

    func groupSettings(for group: String) -> [PlexServerSettingViewModel] {
        return settingViewModels.filter { vm in
            guard let settingGroup = vm.setting.group, !vm.setting.label.isEmpty else {
                return false
            }
            return settingGroup == group && (vm.setting.hidden == false || showAdvanced)
        }
    }

    func loadPrefs(serverViewModel: ServerViewModel, authManager: PlexAuthManager) async {
        guard let serverDetails = getServerDetails(serverViewModel: serverViewModel, authManager: authManager) else {
            isLoading = false
            return
        }
        
        self.isLoading = true
        do {
            let settings = try await prefsService.fetchPrefs(serverURL: serverDetails.url, token: serverDetails.token)
            self.settingViewModels = settings.map { PlexServerSettingViewModel(setting: $0) }

            self.settingViewModels.forEach { vm in
                vm.objectWillChange.sink { [weak self] _ in
                    self?.objectWillChange.send()
                }.store(in: &cancellables)
            }
            
        } catch {
            print(LocalizedStringKey("common.error"), "\(error.localizedDescription)")
        }
        self.isLoading = false
    }

    func saveChanges(serverViewModel: ServerViewModel, authManager: PlexAuthManager) async {
        guard let serverDetails = getServerDetails(serverViewModel: serverViewModel, authManager: authManager) else {
            return
        }

        let changedSettings = settingViewModels.filter { $0.hasChanged }
        
        await withTaskGroup(of: Void.self) { group in
            for vm in changedSettings {
                group.addTask {
                    do {
                        try await self.prefsService.updatePref(
                            serverURL: serverDetails.url,
                            token: serverDetails.token,
                            key: vm.setting.id,
                            value: vm.value
                        )
                        await MainActor.run {
                            vm.updateInitialValue()
                        }
                    } catch {
                        print(LocalizedStringKey("common.error"), "\(vm.setting.id): \(error)")
                    }
                }
            }
        }
        objectWillChange.send()
    }
    
    private func getServerDetails(serverViewModel: ServerViewModel, authManager: PlexAuthManager) -> (url: String, token: String)? {
        guard let serverID = serverViewModel.selectedServerID,
              let server = serverViewModel.availableServers.first(where: { $0.id == serverID }),
              let connection = server.connections.first(where: { !$0.local }) ?? server.connections.first,
              let token = authManager.getPlexAuthToken()
        else { return nil }
        let resourceToken = server.accessToken ?? token
        return (url: connection.uri, token: resourceToken)
    }
}

class PlexServerSettingViewModel: ObservableObject, Identifiable {
    @Published var setting: PlexServerSetting
    @Published var value: String
    private var initialValue: String
    
    var id: String { setting.id }
    
    var hasChanged: Bool {
        value != initialValue
    }
    
    init(setting: PlexServerSetting) {
        self.setting = setting
        self.value = setting.value ?? ""
        self.initialValue = setting.value ?? ""
    }

    func updateInitialValue() {
        self.initialValue = self.value
    }
    
    var boolValue: Binding<Bool> {
        Binding<Bool>(
            get: { self.value == "1" || self.value == "true" },
            set: { self.value = $0 ? "1" : "0" }
        )
    }

    var enumValues: [EnumValue] {
        guard let enums = setting.enumValues else { return [] }
        return enums.split(separator: "|").compactMap {
            let components = $0.split(separator: ":", maxSplits: 1, omittingEmptySubsequences: false)
            guard components.count == 2 else { return nil }
            return EnumValue(id: String(components[0]), name: String(components[1]))
        }
    }
}
