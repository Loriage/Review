import Foundation
import Combine

@MainActor
class ServerViewModel: ObservableObject {
    @Published var availableServers: [PlexResource] = []
    @Published var selectedServerID: String?
    @Published var availableUsers: [PlexUser] = []
    
    @Published var isLoading = false
    @Published var errorMessage: String?

    private let plexService: PlexAPIService
    let authManager: PlexAuthManager
    private var cancellables = Set<AnyCancellable>()

    init(authManager: PlexAuthManager, plexService: PlexAPIService = PlexAPIService()) {
        self.authManager = authManager
        self.plexService = plexService
        
        $selectedServerID
            .sink { [weak self] serverID in
                guard let self = self, let serverID = serverID else { return }
                Task {
                    await self.loadUsers(for: serverID)
                }
            }
            .store(in: &cancellables)
    }

    func loadServers() async {
        guard let token = authManager.getPlexAuthToken() else {
            errorMessage = "Token d'authentification introuvable."
            return
        }

        isLoading = true
        errorMessage = nil

        do {
            let servers = try await plexService.fetchServers(token: token)
            self.availableServers = servers
            if let server = servers.first, servers.count == 1 {
                self.selectedServerID = server.id
            }
        } catch {
            errorMessage = "Impossible de récupérer la liste des serveurs. \(error.localizedDescription)"
        }

        isLoading = false
    }

    func loadUsers(for serverID: String) async {
        self.availableUsers = []
        
        guard
            let server = availableServers.first(where: { $0.id == serverID }),
            let connection = server.connections.first(where: { !$0.local }) ?? server.connections.first,
            let token = authManager.getPlexAuthToken()
        else {
            return
        }

        isLoading = true

        do {
            let serverURL = connection.uri
            let resourceToken = server.accessToken ?? token
            let allUsers = try await plexService.fetchUsers(serverURL: serverURL, token: resourceToken)
            self.availableUsers = allUsers.filter { !$0.title.isEmpty }
        } catch {
            errorMessage = "Impossible de récupérer les utilisateurs. \(error.localizedDescription)"
        }

        isLoading = false
    }
}
