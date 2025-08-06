import Foundation

@MainActor
class StatsViewModel: ObservableObject {
    
    @Published var userStats: UserStats?
    @Published var isHistorySynced = false
    @Published var isLoading = false
    @Published var loadingStatusMessage = ""
    @Published var errorMessage: String?
    @Published var lastSyncDate: Date?
    @Published var formattedLastSyncDate: String?
    
    @Published var selectedUserID: Int?
    @Published var selectedYear: Int? = nil
    @Published var availableYears: [Int] = []
    @Published var selectedSortOption: SortOption = .byPlays
    
    @Published var selectedMediaDetail: MediaDetail?
    
    private let serverViewModel: ServerViewModel
    private let plexService: PlexAPIService
    private var fullHistory: [WatchSession] = []
    private var lastGeneratedHistory: [WatchSession] = []

    init(serverViewModel: ServerViewModel, plexService: PlexAPIService = PlexAPIService()) {
        self.serverViewModel = serverViewModel
        self.plexService = plexService
    }
    
    func updateFormattedSyncDate() {
        if let date = lastSyncDate {
            self.formattedLastSyncDate = "Dernière synchro : \(date.formatted(.relative(presentation: .named)))"
        } else {
            self.formattedLastSyncDate = nil
        }
    }

    func syncFullHistory() async {
        guard let serverID = serverViewModel.selectedServerID,
              let server = serverViewModel.availableServers.first(where: { $0.id == serverID }),
              let connection = server.connections.first(where: { !$0.local }) ?? server.connections.first,
              let token = serverViewModel.authManager.getPlexAuthToken()
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
            
            self.fullHistory = try await plexService.fetchWatchHistory(serverURL: serverURL, token: resourceToken, year: 0, userID: nil) { count in
                await MainActor.run {
                    self.loadingStatusMessage = "Analyse de \(count) visionnages..."
                }
            }
            
            let calendar = Calendar.current
            let years = Set(fullHistory.compactMap { session -> Int? in
                guard let viewedAt = session.viewedAt else { return nil }
                return calendar.component(.year, from: Date(timeIntervalSince1970: viewedAt))
            })
            
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
            errorMessage = "Impossible de récupérer l'historique. \(error.localizedDescription)"
        }
        isLoading = false
        loadingStatusMessage = ""
    }

    func generateRewind() async {
        guard let serverID = serverViewModel.selectedServerID,
              let server = serverViewModel.availableServers.first(where: { $0.id == serverID }),
              let connection = server.connections.first(where: { !$0.local }) ?? server.connections.first,
              let token = serverViewModel.authManager.getPlexAuthToken()
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
               calendar.component(.year, from: Date(timeIntervalSince1970: viewedAt)) != year {
                return false
            }

            if let userID = selectedUserID, session.accountID != userID {
                return false
            }

            return true
        }

        if historyForYear.isEmpty {
            let yearString = selectedYear.map { String($0) } ?? "la période"
            errorMessage = "Aucun historique de visionnage trouvé pour \(yearString)."
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
                    self.loadingStatusMessage = "Récupération des durées (\(processedCount)/\(totalItems))..."
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

    func historyForMedia(session: PlexActivitySession) async -> (sessions: [WatchSession], summary: String?) {
        if !isHistorySynced {
            await syncFullHistory()
        }

        guard let serverID = serverViewModel.selectedServerID,
              let server = serverViewModel.availableServers.first(where: { $0.id == serverID }),
              let connection = server.connections.first(where: { !$0.local }) ?? server.connections.first,
              let token = serverViewModel.authManager.getPlexAuthToken()
        else {
            return ([], nil)
        }
        let serverURL = connection.uri
        let resourceToken = server.accessToken ?? token

        var filteredSessions: [WatchSession] = []
        var summary: String? = nil
        var ratingKeyForSummary: String?

        if session.type == "movie" {
            filteredSessions = fullHistory.filter { $0.ratingKey == session.ratingKey }
            ratingKeyForSummary = session.ratingKey
        } else {
            guard let showTitle = session.grandparentTitle, !showTitle.isEmpty else {
                filteredSessions = fullHistory.filter { $0.ratingKey == session.ratingKey }
                ratingKeyForSummary = session.ratingKey
                return (filteredSessions, nil)
            }
            filteredSessions = fullHistory.filter { $0.grandparentTitle == showTitle }
            ratingKeyForSummary = filteredSessions.first?.grandparentRatingKey
        }

        if let ratingKey = ratingKeyForSummary {
            let details = try? await plexService.fetchMediaDetails(
                for: ratingKey,
                serverURL: serverURL,
                token: resourceToken
            )
            summary = details?.summary
        }

        return (filteredSessions, summary)
    }

    func historyForUser(userID: Int) async -> [WatchSession] {
        if !isHistorySynced {
            await syncFullHistory()
        }
        
        guard userID != 0 else { return [] }
        return fullHistory.filter { $0.accountID == userID }
    }

    func selectMedia(for mediaID: String) async {
        guard let serverID = serverViewModel.selectedServerID,
              let server = serverViewModel.availableServers.first(where: { $0.id == serverID }),
              let connection = server.connections.first(where: { !$0.local }) ?? server.connections.first,
              let token = serverViewModel.authManager.getPlexAuthToken()
        else {
            return
        }
        
        let serverURL = connection.uri
        let serverIdentifier = server.clientIdentifier
        let resourceToken = server.accessToken ?? token
        
        var relevantSessions: [WatchSession] = []
        var title = ""
        var posterURL: URL?
        var mediaType = ""
        let ratingKey = mediaID
        
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
        
        let topUsers = userSessions.compactMap { (userID, sessions) -> TopUserStat? in
            guard let user = serverViewModel.availableUsers.first(where: { $0.id == userID }) else {
                return nil
            }
            let totalDuration = sessions.reduce(0) { $0 + (($1.duration ?? 0) / 1000) }
            
            return TopUserStat(
                id: userID,
                userName: user.title,
                userThumbURL: user.thumb.flatMap { URL(string: $0) },
                playCount: sessions.count,
                formattedDuration: formatDuration(seconds: totalDuration)
            )
        }
        
        let topSortedUsers = Array(topUsers.sorted { $0.playCount > $1.playCount }.prefix(3))
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
            topUsers: topSortedUsers
        )
    }

    private func calculateStats(from history: [WatchSession], serverURL: String, token: String) {
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
    
    private func formatDuration(seconds: Int) -> String {
        let hours = seconds / 3600
        let minutes = (seconds % 3600) / 60
        if hours > 0 {
            return "\(hours)h \(minutes)m"
        } else {
            return "\(minutes)m"
        }
    }
}
