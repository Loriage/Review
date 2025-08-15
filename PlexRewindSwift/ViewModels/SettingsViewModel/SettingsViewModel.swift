import Foundation
import Combine

@MainActor
class SettingsViewModel: ObservableObject {
    @Published var account: PlexAccount?
    @Published var isLoading = false
    
    private let userService = PlexUserService()
    private let authManager: PlexAuthManager
    
    init(authManager: PlexAuthManager) {
        self.authManager = authManager
    }
    
    func loadAccountDetails() async {
        guard let token = authManager.getPlexAuthToken() else { return }
        
        self.isLoading = true
        do {
            self.account = try await userService.fetchAccount(token: token)
        } catch {
            print(String(localized: "common.error"), "\(error.localizedDescription)")
        }
        self.isLoading = false
    }
}
