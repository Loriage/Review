import Foundation
import Combine

@MainActor
class ActivityViewModel: ObservableObject {
    @Published var state: ViewState = .noServerSelected
    
    private let serverViewModel: ServerViewModel
    private let plexService: PlexAPIService
    private let geolocationService = GeolocationService()
    private var cancellables = Set<AnyCancellable>()
    
    init(serverViewModel: ServerViewModel, plexService: PlexAPIService = PlexAPIService()) {
        self.serverViewModel = serverViewModel
        self.plexService = plexService
        setupBindings()
    }
    
    private func setupBindings() {
        serverViewModel.$selectedServerID
            .sink { [weak self] serverID in
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
            return
        }
        
        let serverURL = connection.uri
        let resourceToken = server.accessToken ?? token
        
        do {
            var sessions = try await plexService.fetchCurrentActivity(serverURL: serverURL, token: resourceToken)
            
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
            } else {
                self.state = .content(sessions)
            }
            
        } catch let error as PlexError {
            if case .serverError(let statusCode) = error, statusCode == 403 {
                self.state = .forbidden
            } else {
                self.state = .empty
            }
        } catch {
            self.state = .empty
        }
    }
}
