import Foundation

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

    @Published var funFactTotalPlays: Int?
    @Published var funFactMostActiveDay: String?
    @Published var funFactFormattedWatchTime: String?
    @Published var funFactTopUser: String?
    @Published var funFactBusiestTimeOfDay: TimeOfDay?
    @Published var funFactActiveUsers: Int?

    private var serverWideHistory: [WatchSession] = []
    private var unsortedMovies: [TopMedia] = []
    private var unsortedShows: [TopMedia] = []
    
    private let serverViewModel: ServerViewModel
    private let authManager: PlexAuthManager
    private let activityService: PlexActivityService
    private let metadataService: PlexMetadataService

    init(serverViewModel: ServerViewModel, authManager: PlexAuthManager, activityService: PlexActivityService = PlexActivityService(), metadataService: PlexMetadataService = PlexMetadataService()) {
        self.serverViewModel = serverViewModel
        self.authManager = authManager
        self.activityService = activityService
        self.metadataService = metadataService
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
            let fullHistory = try await activityService.fetchWatchHistory(serverURL: serverURL, token: token, year: 0, userID: nil) { count in
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

        calculateFunFacts(from: filteredHistory)

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

    private func calculateFunFacts(from history: [WatchSession]) {
        self.funFactTotalPlays = history.count

        let totalSeconds = history.reduce(0) { $0 + (($1.duration ?? 0) / 1000) }
        let days = totalSeconds / 86400
        let hours = (totalSeconds % 86400) / 3600
        if days > 0 {
            self.funFactFormattedWatchTime = "\(days)j \(hours)h"
        } else {
            self.funFactFormattedWatchTime = "\(hours)h"
        }

        let calendar = Calendar.current
        let dayCounts = Dictionary(grouping: history, by: {
            calendar.component(.weekday, from: Date(timeIntervalSince1970: $0.viewedAt ?? 0))
        }).mapValues { $0.count }

        if let (weekday, _) = dayCounts.max(by: { $0.value < $1.value }) {
            self.funFactMostActiveDay = calendar.weekdaySymbols[weekday - 1].capitalized
        } else {
            self.funFactMostActiveDay = nil
        }

        if self.selectedUserID == nil {
            let userCounts = Dictionary(grouping: history, by: { $0.accountID ?? -1 })
                .mapValues { $0.count }
            
            if let (topUserID, _) = userCounts.max(by: { $0.value < $1.value }),
               let topUser = serverViewModel.availableUsers.first(where: { $0.id == topUserID }) {
                self.funFactTopUser = topUser.title
            } else {
                self.funFactTopUser = nil
            }
            self.funFactActiveUsers = Set(history.compactMap { $0.accountID }).count
        } else {
            if let selectedUser = serverViewModel.availableUsers.first(where: { $0.id == self.selectedUserID }) {
                self.funFactTopUser = selectedUser.title
            } else {
                self.funFactTopUser = nil
            }
            self.funFactActiveUsers = nil
        }
        
        let hourCounts = Dictionary(grouping: history, by: {
            calendar.component(.hour, from: Date(timeIntervalSince1970: $0.viewedAt ?? 0))
        }).mapValues { $0.count }

        let timeOfDayCounts = hourCounts.reduce(into: [TimeOfDay: Int]()) { (result, hourCount) in
            let (hour, count) = hourCount
            let timeOfDay: TimeOfDay
            switch hour {
            case 6..<12: timeOfDay = .morning
            case 12..<18: timeOfDay = .afternoon
            case 18..<24: timeOfDay = .evening
            default: timeOfDay = .night
            }
            result[timeOfDay, default: 0] += count
        }

        if let (busiestTime, _) = timeOfDayCounts.max(by: { $0.value < $1.value }) {
            self.funFactBusiestTimeOfDay = busiestTime
        } else {
            self.funFactBusiestTimeOfDay = nil
        }
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
                    let duration = try? await self.metadataService.fetchDuration(for: ratingKey, serverURL: serverURL, token: token)
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
            return
        }
        self.errorMessage = "Erreur (\(context)): \(error.localizedDescription)"
    }
}
