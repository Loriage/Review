import Foundation

@MainActor
class LibraryViewModel: ObservableObject {
    @Published var libraries: [PlexLibrary] = []
    @Published var librarySizes: [String: Int64] = [:]
    @Published var libraryFileCounts: [String: Int] = [:]
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let plexService: PlexAPIService
    private let serverViewModel: ServerViewModel
    private let authManager: PlexAuthManager
    
    private var currentServerDetails: (url: String, token: String)?

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
        
        if self.libraries.isEmpty {
            isLoading = true
        }
        errorMessage = nil
        
        let serverURL = connection.uri
        let resourceToken = server.accessToken ?? token
        self.currentServerDetails = (url: serverURL, token: resourceToken)
        
        do {
            let fetchedLibraries = try await plexService.fetchLibraries(serverURL: serverURL, token: resourceToken)
            self.libraries = fetchedLibraries
            
            self.isLoading = false
            
            await fetchAllLibrarySizesAndCounts(libraries: fetchedLibraries)
            
        } catch {
            self.errorMessage = "Impossible de charger les médiathèques : \(error.localizedDescription)"
        }
        
        isLoading = false
    }
    
    // CORRECTION : La logique est maintenant beaucoup plus simple et directe.
    private func fetchAllLibrarySizesAndCounts(libraries: [PlexLibrary]) async {
        self.librarySizes = [:]
        self.libraryFileCounts = [:]
        
        await withTaskGroup(of: (String, (size: Int64, count: Int)?).self) { group in
            for library in libraries {
                group.addTask {
                    // On choisit le type de média à chercher en fonction du type de la bibliothèque
                    let mediaType: Int
                    if library.type == "show" {
                        mediaType = 4 // Episodes
                    } else if library.type == "movie" {
                        mediaType = 1 // Films
                    } else {
                        // On ignore les autres types pour l'instant (musique, etc.)
                        return (library.key, (0, 0))
                    }
                    
                    guard let details = await self.currentServerDetails else { return (library.key, nil) }

                    do {
                        let mediaItems = try await self.plexService.fetchAllMediaInSection(
                            serverURL: details.url,
                            token: details.token,
                            libraryKey: library.key,
                            mediaType: mediaType
                        )
                        
                        let totalSize = mediaItems.reduce(Int64(0)) { $0 + ($1.media?.first?.parts.first?.size ?? 0) }
                        let totalCount = mediaItems.count
                        
                        return (library.key, (totalSize, totalCount))
                    } catch {
                        print("Erreur de calcul de la taille pour la médiathèque \(library.key): \(error)")
                        return (library.key, nil)
                    }
                }
            }
            
            for await (key, result) in group {
                if let result = result {
                    librarySizes[key] = result.size
                    libraryFileCounts[key] = result.count
                }
            }
        }
    }
    
    // La fonction récursive est maintenant inutile et a été supprimée.
}
