import Foundation
import Combine

@MainActor
class RewindViewModel: ObservableObject {

    @Published var userStats: UserStats?
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    @Published var loadingStatusMessage: String = ""

    @Published var availableServers: [PlexResource] = []
    @Published var selectedServerID: String?

    @Published var availableUsers: [PlexUser] = []
    @Published var selectedUserID: Int?

    @Published var selectedYear: Int? = nil
    @Published var availableYears: [Int] = []

    @Published var selectedSortOption: SortOption = .byPlays

    @Published var isHistorySynced: Bool = false
    @Published var lastSyncDate: Date?
    @Published var formattedLastSyncDate: String?

    @Published var selectedMediaDetail: MediaDetail?

    private var fullHistory: [WatchSession] = []
    private let plexService: PlexAPIService
    private var lastGeneratedHistory: [WatchSession] = []

    init(plexService: PlexAPIService = PlexAPIService()) {
        self.plexService = plexService
    }

    func selectMedia(for mediaID: String, authManager: PlexAuthManager) async {
        guard let serverID = selectedServerID,
              let server = availableServers.first(where: { $0.id == serverID }),
              let connection =
                server.connections.first(where: { !$0.local })
                ?? server.connections.first,
              let token = authManager.getPlexAuthToken()
        else {
            return
        }
        
        let serverURL = connection.uri
        let serverIdentifier = server.clientIdentifier
        let resourceToken = server.accessToken ?? token
        
        var relevantSessions: [WatchSession] = []
        var title = ""
        var posterURL: URL?
        let ratingKey = mediaID
        
        var mediaType = ""
            
        if let movie = userStats?.rankedMovies.first(where: { $0.id == mediaID }) {
            title = movie.title
            posterURL = movie.posterURL
            mediaType = "movie"
            relevantSessions = lastGeneratedHistory.filter { $0.title == title && $0.type == "movie" }
        } else if let show = userStats?.rankedShows.first(where: { $0.id == mediaID }) {
            title = show.title
            posterURL = show.posterURL
            mediaType = "show"
            relevantSessions = lastGeneratedHistory.filter { $0.showTitle == title }
        } else {
            return
        }
        
        let details = try? await plexService.fetchMediaDetails(
            for: ratingKey,
            serverURL: serverURL,
            token: resourceToken
        )
        
        let userSessions = Dictionary(grouping: relevantSessions, by: { $0.accountID ?? 0 })
        
        let userStats = userSessions.compactMap { (userID, sessions) -> TopUserStat? in
            guard let user = availableUsers.first(where: { $0.id == userID }) else {
                return nil
            }
            let totalDuration = sessions.reduce(0) { $0 + (($1.duration ?? 0) / 1000) }
            let thumbURL = user.thumb.flatMap {
                URL(string: $0)
            }
            
            return TopUserStat(
                id: userID,
                userName: user.title,
                userThumbURL: thumbURL,
                playCount: sessions.count,
                formattedDuration: formatDuration(seconds: totalDuration)
            )
        }
        
        let topUsers = Array(userStats.sorted { $0.playCount > $1.playCount }.prefix(3))
        let genres = details?.genre?.map { $0.tag } ?? []
        let artURL = details?.art.flatMap {
            URL(string: "\(serverURL)\($0)?X-Plex-Token=\(token)")
        }
        
        self.selectedMediaDetail = MediaDetail(
            id: mediaID,
            serverIdentifier: serverIdentifier,
            mediaType: mediaType,
            title: title,
            tagline: details?.tagline,
            posterURL: posterURL,
            artURL: artURL,
            summary: details?.summary,
            year: details?.year,
            genres: genres,
            topUsers: topUsers
        )
    }

    func reset() {
        userStats = nil
        errorMessage = nil
    }

    func updateFormattedSyncDate() {
        if let date = lastSyncDate {
            self.formattedLastSyncDate =
                "Dernière synchro : \(date.formatted(.relative(presentation: .named)))"
        } else {
            self.formattedLastSyncDate = nil
        }
    }

    func loadServers(authManager: PlexAuthManager) async {
        guard let token = authManager.getPlexAuthToken() else {
            errorMessage = "Token d'authentification introuvable."
            return
        }

        isLoading = true
        errorMessage = nil
        loadingStatusMessage = "Recherche de vos serveurs..."

        do {
            let servers = try await plexService.fetchServers(token: token)
            self.availableServers = servers

            if let server = servers.first, servers.count == 1 {
                self.selectedServerID = server.id
                await loadUsers(for: server.id, authManager: authManager)
            }
        } catch {
            errorMessage =
                "Impossible de récupérer la liste des serveurs. \(error.localizedDescription)"
        }

        isLoading = false
        loadingStatusMessage = ""
    }

    func loadUsers(
        for serverID: String,
        authManager: PlexAuthManager
    ) async {
        self.availableUsers = []
        self.selectedUserID = nil

        guard
            let server = availableServers.first(where: { $0.id == serverID }),
            let connection =
                server.connections.first(where: { !$0.local })
                ?? server.connections.first,
            let token = authManager.getPlexAuthToken()
        else {
            return
        }

        isLoading = true
        loadingStatusMessage = "Recherche des utilisateurs..."

        do {
            let serverURL = connection.uri
            let resourceToken = server.accessToken ?? token
            let allUsers = try await plexService.fetchUsers(
                serverURL: serverURL,
                token: resourceToken
            )
            self.availableUsers = allUsers.filter { !$0.title.isEmpty }
        } catch {
            errorMessage =
                "Impossible de récupérer les utilisateurs. \(error.localizedDescription)"
        }

        isLoading = false
        loadingStatusMessage = ""
    }

    func syncFullHistory(authManager: PlexAuthManager) async {
        guard let serverID = self.selectedServerID,
            let server = availableServers.first(where: { $0.id == serverID }),
            let connection =
                server.connections.first(where: { !$0.local })
                ?? server.connections.first,
            let token = authManager.getPlexAuthToken()
        else {
            errorMessage = "Veuillez sélectionner un serveur valide."
            return
        }

        isLoading = true
        isHistorySynced = false
        loadingStatusMessage = "Analyse de votre historique complet..."

        do {
            let serverURL = connection.uri
            let resourceToken = server.accessToken ?? token

            self.fullHistory = try await plexService.fetchWatchHistory(
                serverURL: serverURL,
                token: resourceToken,
                year: 0,
                userID: nil,
                progressUpdate: { count in
                    await MainActor.run {
                        self.loadingStatusMessage =
                            "Analyse de \(count) visionnages..."
                    }
                }
            )

            let calendar = Calendar.current
            let years = Set(
                fullHistory.compactMap { session -> Int? in
                    guard let viewedAt = session.viewedAt else { return nil }
                    return calendar.component(
                        .year,
                        from: Date(timeIntervalSince1970: viewedAt)
                    )
                }
            )

            self.availableYears = Array(years).sorted(by: >)

            if selectedYear == nil, let mostRecentYear = self.availableYears.first {
                self.selectedYear = mostRecentYear
            }

            self.isHistorySynced = !self.fullHistory.isEmpty
            if self.isHistorySynced {
                self.lastSyncDate = Date()
                updateFormattedSyncDate()
            }

        } catch {
            errorMessage =
                "Impossible de récupérer l'historique. \(error.localizedDescription)"
        }
        isLoading = false
        loadingStatusMessage = ""
    }

    func generateRewind(authManager: PlexAuthManager) async {
        guard let serverID = selectedServerID,
            let server = availableServers.first(where: { $0.id == serverID }),
            let connection =
                server.connections.first(where: { !$0.local })
                ?? server.connections.first,
            let token = authManager.getPlexAuthToken()
        else {
            errorMessage = "Veuillez sélectionner un serveur."
            return
        }

        isLoading = true
        errorMessage = nil
        userStats = nil

        let serverURL = connection.uri
        let resourceToken = server.accessToken ?? token

        let calendar = Calendar.current
        let historyForYear = fullHistory.filter { session in
            guard let viewedAt = session.viewedAt else { return false }

            if let year = selectedYear,
                calendar.component(.year, from: Date(timeIntervalSince1970: viewedAt))
                    != year
            {
                return false
            }

            if let userID = selectedUserID, session.accountID != userID {
                return false
            }

            return true
        }

        if historyForYear.isEmpty {
            let yearString = selectedYear.map { String($0) } ?? "la période"
            errorMessage =
                "Aucun historique de visionnage trouvé pour \(yearString)."
            isLoading = false
            return
        }

        var historyWithDurations: [WatchSession] = []
        let totalItems = historyForYear.count
        var processedCount = 0

        await withTaskGroup(of: WatchSession?.self) { group in
            for session in historyForYear {
                group.addTask {
                    guard let ratingKey = session.ratingKey else { return nil }
                    let duration = try? await self.plexService.fetchDuration(
                        for: ratingKey,
                        serverURL: serverURL,
                        token: resourceToken
                    )
                    var sessionWithDuration = session
                    sessionWithDuration.duration = duration
                    return sessionWithDuration
                }
            }

            for await result in group {
                processedCount += 1
                if let validSession = result {
                    historyWithDurations.append(validSession)
                }
                await MainActor.run {
                    self.loadingStatusMessage =
                        "Récupération des durées (\(processedCount)/\(totalItems))..."
                }
            }
        }

        loadingStatusMessage = "Finalisation des calculs..."
        self.lastGeneratedHistory = historyWithDurations
        try? await Task.sleep(nanoseconds: 200_000_000)
        calculateStats(
            from: historyWithDurations,
            serverURL: serverURL,
            token: resourceToken
        )

        isLoading = false
        loadingStatusMessage = ""
    }

    private func formatDuration(seconds: Int) -> String {
        let hours = seconds / 3600
        let minutes = (seconds % 3600) / 60
        if hours > 0 {
            return "\(hours)h \(minutes)m"
        } else {
            return "\(minutes)m"
        }
    }

    private func calculateStats(
        from history: [WatchSession],
        serverURL: String,
        token: String
    ) {
        guard !history.isEmpty else {
            errorMessage =
                "Aucun historique de visionnage valide trouvé pour cette année."
            return
        }

        let movies = history.filter { $0.type == "movie" }
        let episodes = history.filter { $0.type == "episode" }

        let totalTimeInSeconds = history.reduce(0) {
            $0 + (($1.duration ?? 0) / 1000)
        }

        let moviesGrouped = Dictionary(grouping: movies, by: { $0.title ?? "Film inconnu" })
        let sortedMovies = moviesGrouped.sorted {
            switch selectedSortOption {
            case .byPlays:
                return $0.value.count > $1.value.count
            case .byDuration:
                let duration1 = $0.value.reduce(0) { $0 + (($1.duration ?? 0) / 1000) }
                let duration2 = $1.value.reduce(0) { $0 + (($1.duration ?? 0) / 1000) }
                return duration1 > duration2
            }
        }

        let rankedMovies = sortedMovies.map { (title, sessions) -> RankedMedia in
            let representativeMovie = sessions.first
            let posterPath = representativeMovie?.thumb
            let posterURL = posterPath.flatMap {
                URL(string: "\(serverURL)\($0)?X-Plex-Token=\(token)")
            }
            let subtitle = "Regardé \(sessions.count) fois"
            let movieTotalSeconds = sessions.reduce(0) { $0 + (($1.duration ?? 0) / 1000) }
            let secondarySubtitle = formatDuration(seconds: movieTotalSeconds)

            return RankedMedia(
                id: representativeMovie?.ratingKey ?? title,
                title: title,
                subtitle: subtitle,
                secondarySubtitle: secondarySubtitle,
                posterURL: posterURL
            )
        }

        let showsGrouped = Dictionary(grouping: episodes, by: { $0.showTitle })
        let sortedShows = showsGrouped.sorted {
            switch selectedSortOption {
            case .byPlays:
                return $0.value.count > $1.value.count
            case .byDuration:
                let duration1 = $0.value.reduce(0) { $0 + (($1.duration ?? 0) / 1000) }
                let duration2 = $1.value.reduce(0) { $0 + (($1.duration ?? 0) / 1000) }
                return duration1 > duration2
            }
        }

        let rankedShows = sortedShows.map { (title, sessions) -> RankedMedia in
            let representativeShow = sessions.first
            let posterPath = representativeShow?.grandparentThumb
            let posterURL = posterPath.flatMap {
                URL(string: "\(serverURL)\($0)?X-Plex-Token=\(token)")
            }
            let subtitle = "\(sessions.count) épisodes vus"
            
            let showTotalSeconds = sessions.reduce(0) {
                $0 + (($1.duration ?? 0) / 1000)
            }
            let secondarySubtitle = formatDuration(seconds: showTotalSeconds)
            
            return RankedMedia(
                id: representativeShow?.grandparentRatingKey ?? title,
                title: title,
                subtitle: subtitle,
                secondarySubtitle: secondarySubtitle,
                posterURL: posterURL
            )
        }

        self.userStats = UserStats(
            totalWatchTimeMinutes: totalTimeInSeconds / 60,
            totalMovies: movies.count,
            totalEpisodes: episodes.count,
            rankedMovies: rankedMovies,
            rankedShows: rankedShows
        )
    }
}
