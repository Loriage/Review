import Foundation

@MainActor
class LibraryViewModel: ObservableObject {
    @Published var libraries: [PlexLibrary] = []
    @Published var librarySizes: [String: Int64] = [:]
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let plexService: PlexAPIService
    private let serverViewModel: ServerViewModel
    private let authManager: PlexAuthManager
    
    init(serverViewModel: ServerViewModel, authManager: PlexAuthManager, plexService: PlexAPIService = PlexAPIService()) {
        self.serverViewModel = serverViewModel
        self.authManager = authManager
        self.plexService = plexService
    }
    
    func loadLibraries() async {
        guard let serverID = serverViewModel.selectedServerID,
              let server = serverViewModel.availableServers.first(where: { $0.id == serverID }),
              let connection = server.connections.first(where: { !$0.local }) ?? server.connections.first,
              let token = authManager.getPlexAuthToken()
        else {
            errorMessage = "Serveur non sélectionné ou informations manquantes."
            return
        }
        
        isLoading = true
        errorMessage = nil
        
        let serverURL = connection.uri
        let resourceToken = server.accessToken ?? token
        
        do {
            let fetchedLibraries = try await plexService.fetchLibraries(serverURL: serverURL, token: resourceToken)
            self.libraries = fetchedLibraries
            
            await fetchAllLibrarySizes(libraries: fetchedLibraries, serverURL: serverURL, token: resourceToken)
            
        } catch {
            self.errorMessage = "Impossible de charger les médiathèques : \(error.localizedDescription)"
        }
        
        isLoading = false
    }

    private func fetchAllLibrarySizes(libraries: [PlexLibrary], serverURL: String, token: String) async {
        await withTaskGroup(of: (String, Int64?).self) { group in
            for library in libraries {
                group.addTask {
                    do {
                        let mediaItems = try await self.plexService.fetchAllMediaInSection(serverURL: serverURL, token: token, libraryKey: library.key)

                        let totalSize = mediaItems.reduce(Int64(0)) { currentTotal, mediaItem in
                            guard let mediaContainers = mediaItem.media else {
                                return currentTotal
                            }
                            
                            let itemSize = mediaContainers.reduce(Int64(0)) { mediaTotal, mediaContainer in
                                mediaTotal + mediaContainer.parts.reduce(Int64(0)) { $0 + $1.size }
                            }
                            return currentTotal + itemSize
                        }
                        print(library.title)
                        print(totalSize)
                        return (library.key, totalSize)
                    } catch {
                        print("Erreur de calcul de la taille pour la médiathèque \(library.key): \(error)")
                        return (library.key, nil)
                    }
                }
            }
            
            for await (key, size) in group {
                if let size = size {
                    librarySizes[key] = size
                }
            }
        }
    }
}
