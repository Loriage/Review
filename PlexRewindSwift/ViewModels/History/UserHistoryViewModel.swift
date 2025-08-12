import Foundation
import Combine
import SwiftUI

@MainActor
class UserHistoryViewModel: ObservableObject {
    @Published var sessions: [WatchSession] = []
    @Published var isLoading = true
    @Published var userProfileImageURL: URL?

    let userID: Int
    let userName: String
    
    let statsViewModel: StatsViewModel
    let serverViewModel: ServerViewModel
    let authManager: PlexAuthManager
    private let userService: PlexUserService

    init(userID: Int, userName: String, statsViewModel: StatsViewModel, serverViewModel: ServerViewModel, authManager: PlexAuthManager) {
        self.userID = userID
        self.userName = userName
        self.statsViewModel = statsViewModel
        self.serverViewModel = serverViewModel
        self.authManager = authManager
        self.userService = PlexUserService()
    }

    func loadInitialData() async {
        isLoading = true
        
        await withTaskGroup(of: Void.self) { group in
            group.addTask { await self.fetchUserProfileImageURL() }
            group.addTask { await self.loadHistory() }
        }
        
        isLoading = false
    }

    private func loadHistory() async {
        self.sessions = await statsViewModel.historyForUser(userID: self.userID)
    }

    private func fetchUserProfileImageURL() async {
        guard let token = authManager.getPlexAuthToken() else {
            self.userProfileImageURL = nil
            return
        }
        
        do {
            let homeUsers = try await userService.fetchHomeUsers(token: token)
            var foundUser: PlexUser?

            foundUser = homeUsers.first { $0.id == self.userID }

            if foundUser == nil {
                foundUser = homeUsers.first { $0.title.lowercased() == self.userName.lowercased() }
            }
            
            if let user = foundUser,
               let thumbURLString = user.thumb, !thumbURLString.isEmpty {
                self.userProfileImageURL = URL(string: thumbURLString)
            } else {
                self.userProfileImageURL = nil
            }
        } catch {
            self.userProfileImageURL = nil
        }
    }

    func posterURL(for session: WatchSession) -> URL? {
        let thumbPath = session.type == "episode" ? session.grandparentThumb : session.thumb

        guard let path = thumbPath,
              let serverID = serverViewModel.selectedServerID,
              let server = serverViewModel.availableServers.first(where: { $0.id == serverID }),
              let connection = server.connections.first(where: { !$0.local }) ?? server.connections.first,
              let token = authManager.getPlexAuthToken()
        else {
            return nil
        }

        let resourceToken = server.accessToken ?? token
        let urlString = "\(connection.uri)\(path)?X-Plex-Token=\(resourceToken)"
        
        return URL(string: urlString)
    }

    func refreshData() async {
        await statsViewModel.syncFullHistory()
        await loadHistory()
    }
}
