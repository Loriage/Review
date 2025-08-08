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
        
        isLoading = true
        errorMessage = nil
        
        let serverURL = connection.uri
        let resourceToken = server.accessToken ?? token
        self.currentServerDetails = (url: serverURL, token: resourceToken)
        
        do {
            let fetchedLibraries = try await plexService.fetchLibraries(serverURL: serverURL, token: resourceToken)
            self.libraries = fetchedLibraries
            
            await fetchAllLibrarySizesAndCounts(libraries: fetchedLibraries)
            
        } catch {
            self.errorMessage = "Impossible de charger les médiathèques : \(error.localizedDescription)"
        }
        
        isLoading = false
    }
    
    private func fetchAllLibrarySizesAndCounts(libraries: [PlexLibrary]) async {
        await withTaskGroup(of: (String, (size: Int64, count: Int)?).self) { group in
            for library in libraries {
                group.addTask {
                    let initialPath = "/library/sections/\(library.key)/all"
                    let result = await self.calculateSizeAndCount(for: initialPath)

                    return (library.key, result)
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

    private func calculateSizeAndCount(for path: String) async -> (size: Int64, count: Int)? {
        guard let details = currentServerDetails else { return nil }
        var totalSize: Int64 = 0
        var totalCount: Int = 0
        
        do {
            let items = try await plexService.fetchLibraryContent(serverURL: details.url, token: details.token, at: path)
            
            await withTaskGroup(of: (Int64, Int)?.self) { group in
                for item in items {
                    if item.type == "show" || item.type == "season" || item.type == "folder" {
                        group.addTask {
                            return await self.calculateSizeAndCount(for: item.key)
                        }
                    } else if let mediaContainers = item.media {
                        for container in mediaContainers {
                            for part in container.parts {
                                totalSize += part.size
                                totalCount += 1
                            }
                        }
                    }
                }

                for await result in group {
                    if let result = result {
                        totalSize += result.0
                        totalCount += result.1
                    }
                }
            }
            return (totalSize, totalCount)
        } catch {
            print("Erreur de calcul récursif pour le chemin \(path): \(error)")
            return nil
        }
    }

    private func calculateSizeRecursively(for path: String) async -> Int64? {
        guard let details = currentServerDetails else { return nil }
        var currentLevelSize: Int64 = 0
        
        do {
            let items = try await plexService.fetchLibraryContent(serverURL: details.url, token: details.token, at: path)
            
            await withTaskGroup(of: Int64?.self) { group in
                for item in items {
                    if item.type == "season" {
                        group.addTask {
                            return await self.calculateSizeRecursively(for: item.key)
                        }
                    } else if let mediaContainers = item.media {
                        let itemSize = mediaContainers.reduce(Int64(0)) { $0 + $1.parts.reduce(Int64(0)) { $0 + $1.size } }
                        currentLevelSize += itemSize
                    }
                }

                for await size in group {
                    if let size = size {
                        currentLevelSize += size
                    }
                }
            }
            return currentLevelSize
        } catch {
            print("Erreur de calcul récursif pour le chemin \(path): \(error)")
            return nil
        }
    }

    private func calculateSizeForMovieLibrary(libraryKey: String) async -> Int64? {
        guard let details = currentServerDetails else { return nil }
        do {
            let mediaItems = try await self.plexService.fetchAllMediaInSection(serverURL: details.url, token: details.token, libraryKey: libraryKey)
            let totalSize = mediaItems.reduce(Int64(0)) { currentTotal, metadata in
                guard let mediaContainers = metadata.media else { return currentTotal }
                let itemSize = mediaContainers.reduce(Int64(0)) { $0 + $1.parts.reduce(Int64(0)) { $0 + $1.size } }
                return currentTotal + itemSize
            }
            return totalSize
        } catch {
            print("Erreur de calcul (films) pour la médiathèque \(libraryKey): \(error)")
            return nil
        }
    }
}
