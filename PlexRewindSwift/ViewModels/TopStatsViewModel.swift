import Foundation

enum TopStatsSortOption: String, CaseIterable, Identifiable {
    case byPlays
    case byDuration

    var id: String { self.rawValue }

    var displayName: String {
        switch self {
        case .byPlays:
            return "Lectures"
        case .byDuration:
            return "Durée"
        }
    }
}

@MainActor
class TopStatsViewModel: ObservableObject {
    @Published var topMovies: [TopMedia] = []
    @Published var topShows: [TopMedia] = []
    @Published var isLoading = false
    @Published var loadingMessage = "Chargement..."
    @Published var errorMessage: String?
    @Published var hasFetchedOnce = false

    @Published var selectedUserID: Int?
    @Published var selectedTimeFilter: TimeFilter = .allTime
    @Published var sortOption: TopStatsSortOption = .byPlays

    private var serverWideHistory: [WatchSession] = []
    private var unsortedMovies: [TopMedia] = []
    private var unsortedShows: [TopMedia] = []
    
    private let serverViewModel: ServerViewModel
    private let authManager: PlexAuthManager
    private let plexService: PlexAPIService

    init(serverViewModel: ServerViewModel, authManager: PlexAuthManager, plexService: PlexAPIService = PlexAPIService()) {
        self.serverViewModel = serverViewModel
        self.authManager = authManager
        self.plexService = plexService
    }

    func fetchTopMedia(forceRefresh: Bool = false) async {
        if serverWideHistory.isEmpty || forceRefresh {
            await loadServerWideHistory()
        }
        await applyFiltersAndSort()
    }

    private func loadServerWideHistory() async {
        guard let serverID = serverViewModel.selectedServerID,
              let server = serverViewModel.availableServers.first(where: { $0.id == serverID }),
              let connection = server.connections.first(where: { !$0.local }) ?? server.connections.first,
              let token = authManager.getPlexAuthToken()
        else {
            errorMessage = "Serveur non sélectionné."
            return
        }

        isLoading = true
        errorMessage = nil
        
        let serverURL = connection.uri
        let resourceToken = server.accessToken ?? token

        self.loadingMessage = "Analyse de l'historique du serveur..."
        do {
            let fullHistory = try await plexService.fetchWatchHistory(serverURL: serverURL, token: token, year: 0, userID: nil) { count in
                await MainActor.run { self.loadingMessage = "Analyse de \(count) visionnages..." }
            }
            let historyWithDurations = await fetchDurationsIfNeeded(for: fullHistory, serverURL: serverURL, token: resourceToken)
            self.serverWideHistory = historyWithDurations
            self.hasFetchedOnce = true
        } catch {
            handleError(error, context: "Chargement de l'historique global")
        }
        
        isLoading = false
        loadingMessage = "Chargement..."
    }
    
    func applyFiltersAndSort() async {
        guard hasFetchedOnce else { return }
        
        if serverWideHistory.isEmpty {
            self.topMovies = []
            self.topShows = []
            self.unsortedMovies = []
            self.unsortedShows = []
            return
        }
        
        isLoading = true
        self.loadingMessage = "Application des filtres..."
        await Task.yield()

        var filteredHistory = filterHistory(serverWideHistory, by: selectedTimeFilter)

        if let userID = selectedUserID {
            filteredHistory = filteredHistory.filter { $0.accountID == userID }
        }

        await MainActor.run { self.loadingMessage = "Calcul des classements..." }
        
        let historyMovieGroups = Dictionary(grouping: filteredHistory.filter { $0.type == "movie" }, by: { $0.ratingKey ?? "" })
        let historyShowGroups = Dictionary(grouping: filteredHistory.filter { $0.type == "episode" }, by: { $0.computedGrandparentRatingKey ?? "" })
        
        guard let serverID = serverViewModel.selectedServerID,
              let server = serverViewModel.availableServers.first(where: { $0.id == serverID }),
              let connection = server.connections.first(where: { !$0.local }) ?? server.connections.first,
              let token = authManager.getPlexAuthToken()
        else {
            errorMessage = "Serveur non sélectionné."
            isLoading = false
            return
        }
        
        let serverURL = connection.uri
        let resourceToken = server.accessToken ?? token

        self.unsortedMovies = historyMovieGroups.compactMap { (ratingKey, sessions) in
            guard !ratingKey.isEmpty, let firstSession = sessions.first else { return nil }
            let totalDuration = sessions.reduce(0) { $0 + (($1.duration ?? 0) / 1000) }
            return TopMedia(
                id: ratingKey,
                title: firstSession.title ?? "Titre inconnu",
                mediaType: "movie",
                viewCount: sessions.count,
                totalWatchTimeSeconds: totalDuration,
                lastViewedAt: sessions.max(by: { ($0.viewedAt ?? 0) < ($1.viewedAt ?? 0) })?.viewedAt.map { Date(timeIntervalSince1970: $0) },
                posterURL: firstSession.thumb.flatMap { URL(string: "\(serverURL)\($0)?X-Plex-Token=\(resourceToken)") },
                sessions: sessions
            )
        }
        
        self.unsortedShows = historyShowGroups.compactMap { (ratingKey, sessions) in
            guard !ratingKey.isEmpty, let firstSession = sessions.first else { return nil }
            let totalDuration = sessions.reduce(0) { $0 + (($1.duration ?? 0) / 1000) }
            return TopMedia(
                id: ratingKey,
                title: firstSession.grandparentTitle ?? "Série inconnue",
                mediaType: "show",
                viewCount: sessions.count,
                totalWatchTimeSeconds: totalDuration,
                lastViewedAt: sessions.max(by: { ($0.viewedAt ?? 0) < ($1.viewedAt ?? 0) })?.viewedAt.map { Date(timeIntervalSince1970: $0) },
                posterURL: firstSession.grandparentThumb.flatMap { URL(string: "\(serverURL)\($0)?X-Plex-Token=\(resourceToken)") },
                sessions: sessions
            )
        }

        sortMedia()
        isLoading = false
    }
    
    func sortMedia() {
        if sortOption == .byPlays {
            topMovies = unsortedMovies.sorted {
                if $0.viewCount != $1.viewCount {
                    return $0.viewCount > $1.viewCount
                }
                return ($0.lastViewedAt ?? .distantPast) > ($1.lastViewedAt ?? .distantPast)
            }
            topShows = unsortedShows.sorted {
                if $0.viewCount != $1.viewCount {
                    return $0.viewCount > $1.viewCount
                }
                return ($0.lastViewedAt ?? .distantPast) > ($1.lastViewedAt ?? .distantPast)
            }
        } else {
            topMovies = unsortedMovies.sorted {
                if $0.totalWatchTimeSeconds != $1.totalWatchTimeSeconds {
                    return $0.totalWatchTimeSeconds > $1.totalWatchTimeSeconds
                }
                return ($0.lastViewedAt ?? .distantPast) > ($1.lastViewedAt ?? .distantPast)
            }
            topShows = unsortedShows.sorted {
                if $0.totalWatchTimeSeconds != $1.totalWatchTimeSeconds {
                    return $0.totalWatchTimeSeconds > $1.totalWatchTimeSeconds
                }
                return ($0.lastViewedAt ?? .distantPast) > ($1.lastViewedAt ?? .distantPast)
            }
        }
    }
    
    private func getStartDate(for filter: TimeFilter) -> Date? {
        let calendar = Calendar.current
        let now = Date()
        switch filter {
        case .week:
            return calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: now))
        case .month:
            return calendar.date(from: calendar.dateComponents([.year, .month], from: now))
        case .year:
            return calendar.date(from: calendar.dateComponents([.year], from: now))
        case .allTime:
            return nil
        }
    }

    private func filterHistory(_ history: [WatchSession], by filter: TimeFilter) -> [WatchSession] {
        guard let startDate = getStartDate(for: filter) else {
            return history
        }
        return history.filter { session in
            guard let viewedAt = session.viewedAt else { return false }
            return Date(timeIntervalSince1970: viewedAt) >= startDate
        }
    }
    
    private func fetchDurationsIfNeeded(for sessions: [WatchSession], serverURL: String, token: String) async -> [WatchSession] {
        var sessionsWithDurations: [WatchSession] = []
        let sessionsNeedingDuration = sessions.filter { $0.duration == nil || $0.duration == 0 }
        let sessionsWithDurationAlready = sessions.filter { $0.duration != nil && $0.duration != 0 }
        sessionsWithDurations.append(contentsOf: sessionsWithDurationAlready)
        
        if !sessionsNeedingDuration.isEmpty {
            await MainActor.run { self.loadingMessage = "Préparation des métadonnées..." }
            try? await Task.sleep(nanoseconds: 500_000_000)
        }

        await withTaskGroup(of: WatchSession.self) { group in
            for session in sessionsNeedingDuration {
                group.addTask {
                    guard let ratingKey = session.ratingKey else { return session }
                    let duration = try? await self.plexService.fetchDuration(for: ratingKey, serverURL: serverURL, token: token)
                    var sessionWithDuration = session
                    sessionWithDuration.duration = duration
                    return sessionWithDuration
                }
            }
            
            var processedCount = 0
            let total = sessionsNeedingDuration.count
            for await result in group {
                sessionsWithDurations.append(result)
                processedCount += 1
                
                if processedCount == total / 2 {
                    await MainActor.run { self.loadingMessage = "Analyse en cours, encore un instant..." }
                }
            }
        }
        
        if !sessionsNeedingDuration.isEmpty {
            await MainActor.run { self.loadingMessage = "Finalisation de la mise à jour..." }
            try? await Task.sleep(nanoseconds: 500_000_000)
        }
        
        return sessionsWithDurations
    }
    
    private func handleError(_ error: Error, context: String) {
        let nsError = error as NSError
        if nsError.domain == NSURLErrorDomain && nsError.code == NSURLErrorCancelled {
            print("Request cancelled: \(context)")
        } else {
            self.errorMessage = "Erreur (\(context)): \(error.localizedDescription)"
        }
    }

    private func fetchServerWideTopMedia(serverURL: String, token: String) async {
        self.loadingMessage = "Analyse de l'historique du serveur..."
        do {
            let fullHistory = try await plexService.fetchWatchHistory(serverURL: serverURL, token: token, year: 0, userID: nil) { count in
                await MainActor.run { self.loadingMessage = "Analyse de \(count) visionnages..." }
            }
            
            let filteredHistory = filterHistory(fullHistory, by: selectedTimeFilter)
            
            let historyWithDurations = await fetchDurationsIfNeeded(for: filteredHistory, serverURL: serverURL, token: token)
            
            await MainActor.run { self.loadingMessage = "Calcul des classements..." }
            
            let historyMovieGroups = Dictionary(grouping: historyWithDurations.filter { $0.type == "movie" }, by: { $0.ratingKey ?? "" })
            let historyShowGroups = Dictionary(grouping: historyWithDurations.filter { $0.type == "episode" }, by: { $0.computedGrandparentRatingKey ?? "" })
            
            self.unsortedMovies = historyMovieGroups.compactMap { (ratingKey, sessions) in
                guard !ratingKey.isEmpty, let firstSession = sessions.first else { return nil }
                let totalDuration = sessions.reduce(0) { $0 + (($1.duration ?? 0) / 1000) }
                return TopMedia(
                    id: ratingKey,
                    title: firstSession.title ?? "Titre inconnu",
                    mediaType: "movie",
                    viewCount: sessions.count,
                    totalWatchTimeSeconds: totalDuration,
                    lastViewedAt: sessions.max(by: { ($0.viewedAt ?? 0) < ($1.viewedAt ?? 0) })?.viewedAt.map { Date(timeIntervalSince1970: $0) },
                    posterURL: firstSession.thumb.flatMap { URL(string: "\(serverURL)\($0)?X-Plex-Token=\(token)") },
                    sessions: sessions
                )
            }
            
            self.unsortedShows = historyShowGroups.compactMap { (ratingKey, sessions) in
                guard !ratingKey.isEmpty, let firstSession = sessions.first else { return nil }
                let totalDuration = sessions.reduce(0) { $0 + (($1.duration ?? 0) / 1000) }
                return TopMedia(
                    id: ratingKey,
                    title: firstSession.grandparentTitle ?? "Série inconnue",
                    mediaType: "show",
                    viewCount: sessions.count,
                    totalWatchTimeSeconds: totalDuration,
                    lastViewedAt: sessions.max(by: { ($0.viewedAt ?? 0) < ($1.viewedAt ?? 0) })?.viewedAt.map { Date(timeIntervalSince1970: $0) },
                    posterURL: firstSession.grandparentThumb.flatMap { URL(string: "\(serverURL)\($0)?X-Plex-Token=\(token)") },
                    sessions: sessions
                )
            }

        } catch {
            handleError(error, context: "Top Média Serveur")
        }
    }

    private func fetchTopMediaForUser(userID: Int, serverURL: String, token: String) async {
        self.loadingMessage = "Analyse de l'historique utilisateur..."
        do {
            let history = try await plexService.fetchWatchHistory(serverURL: serverURL, token: token, year: 0, userID: userID) { count in
                await MainActor.run { self.loadingMessage = "Analyse de \(count) visionnages..." }
            }

            let filteredHistory = filterHistory(history, by: selectedTimeFilter)
            
            let historyWithDurations = await fetchDurationsIfNeeded(for: filteredHistory, serverURL: serverURL, token: token)

            await MainActor.run { self.loadingMessage = "Calcul des classements..." }

            let movies = historyWithDurations.filter { $0.type == "movie" }
            let episodes = historyWithDurations.filter { $0.type == "episode" }

            let movieGroups = Dictionary(grouping: movies, by: { $0.ratingKey ?? "" })
            let showGroups = Dictionary(grouping: episodes, by: { $0.computedGrandparentRatingKey ?? "" })

            self.unsortedMovies = movieGroups.compactMap { (ratingKey, sessions) in
                guard !ratingKey.isEmpty, let firstSession = sessions.first else { return nil }
                let totalDuration = sessions.reduce(0) { $0 + (($1.duration ?? 0) / 1000) }
                return TopMedia(
                    id: ratingKey,
                    title: firstSession.title ?? "Titre inconnu",
                    mediaType: "movie",
                    viewCount: sessions.count,
                    totalWatchTimeSeconds: totalDuration,
                    lastViewedAt: sessions.max(by: { ($0.viewedAt ?? 0) < ($1.viewedAt ?? 0) })?.viewedAt.map { Date(timeIntervalSince1970: $0) },
                    posterURL: firstSession.thumb.flatMap { URL(string: "\(serverURL)\($0)?X-Plex-Token=\(token)") },
                    sessions: sessions
                )
            }

            self.unsortedShows = showGroups.compactMap { (ratingKey, sessions) in
                guard !ratingKey.isEmpty, let firstSession = sessions.first else { return nil }
                let totalDuration = sessions.reduce(0) { $0 + (($1.duration ?? 0) / 1000) }
                return TopMedia(
                    id: ratingKey,
                    title: firstSession.grandparentTitle ?? "Série inconnue",
                    mediaType: "show",
                    viewCount: sessions.count,
                    totalWatchTimeSeconds: totalDuration,
                    lastViewedAt: sessions.max(by: { ($0.viewedAt ?? 0) < ($1.viewedAt ?? 0) })?.viewedAt.map { Date(timeIntervalSince1970: $0) },
                    posterURL: firstSession.grandparentThumb.flatMap { URL(string: "\(serverURL)\($0)?X-Plex-Token=\(token)") },
                    sessions: sessions
                )
            }

        } catch {
            handleError(error, context: "Historique Utilisateur")
        }
    }
}
