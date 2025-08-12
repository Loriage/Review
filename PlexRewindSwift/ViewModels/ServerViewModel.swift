import Foundation
import Combine

@MainActor
class ServerViewModel: ObservableObject {
    @Published var availableServers: [PlexResource] = []
    @Published var selectedServerID: String?
    @Published var availableUsers: [PlexUser] = []
    
    @Published var isLoading = false
    @Published var errorMessage: String?

    private let libraryService: PlexLibraryService
    private let userService: PlexUserService
    let authManager: PlexAuthManager
    private var cancellables = Set<AnyCancellable>()

    init(authManager: PlexAuthManager, libraryService: PlexLibraryService = PlexLibraryService(), userService: PlexUserService = PlexUserService()) {
        self.authManager = authManager
        self.libraryService = libraryService
        self.userService = userService
        
        $selectedServerID
            .sink { [weak self] serverID in
                guard let self = self, let serverID = serverID else { return }
                Task {
                    await self.loadUsers(for: serverID)
                    await self.matchAndSetProfilePictures()
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
            let servers = try await libraryService.fetchServers(token: token)
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
        guard let server = availableServers.first(where: { $0.id == serverID }),
              let connection = server.connections.first(where: { !$0.local }) ?? server.connections.first,
              let token = authManager.getPlexAuthToken()
        else {
            return
        }
        
        do {
            let serverURL = connection.uri
            let resourceToken = server.accessToken ?? token

            let usersFromServer = try await userService.fetchUsers(serverURL: serverURL, token: resourceToken)
            self.availableUsers = usersFromServer.filter { !$0.title.isEmpty }
        } catch {
            errorMessage = "Impossible de récupérer les utilisateurs du serveur. \(error.localizedDescription)"
        }
    }

    private func matchAndSetProfilePictures() async {
        guard let token = authManager.getPlexAuthToken(), !self.availableUsers.isEmpty else { return }
        
        do {
            let homeUsers = try await userService.fetchHomeUsers(token: token)
            let avatarDict = Dictionary(uniqueKeysWithValues: homeUsers.map { ($0.id, $0.thumb) })
            
            var updatedUsers: [PlexUser] = []
            
            for var user in self.availableUsers {
                if let newThumb = avatarDict[user.id], let validThumb = newThumb, !validThumb.isEmpty {
                    user.thumb = validThumb
                }
                updatedUsers.append(user)
            }
            
            self.availableUsers = updatedUsers
        } catch {
        }
    }
}
