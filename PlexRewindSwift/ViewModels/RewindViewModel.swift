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

    @Published var selectedYear: Int =
        Calendar.current.component(.year, from: Date()) - 1
    @Published var availableYears: [Int] = []

    @Published var isHistorySynced: Bool = false
    @Published var lastSyncDate: Date?
    @Published var formattedLastSyncDate: String?

    private var fullHistory: [WatchSession] = []
    private let plexService: PlexAPIService

    init(plexService: PlexAPIService = PlexAPIService()) {
        self.plexService = plexService
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
            self.availableUsers = try await plexService.fetchUsers(
                serverURL: serverURL,
                token: resourceToken
            )
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
                userID: selectedUserID,
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

            if let mostRecentYear = self.availableYears.first {
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
            let sessionDate = Date(timeIntervalSince1970: viewedAt)
            return calendar.component(.year, from: sessionDate) == selectedYear
        }

        if historyForYear.isEmpty {
            errorMessage =
                "Aucun historique de visionnage trouvé pour l'année \(selectedYear)."
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
        try? await Task.sleep(nanoseconds: 200_000_000)
        calculateStats(
            from: historyWithDurations,
            serverURL: serverURL,
            token: resourceToken
        )

        isLoading = false
        loadingStatusMessage = ""
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

        let movieCounts = Dictionary(
            movies.compactMap { $0.title }.map { ($0, 1) },
            uniquingKeysWith: +
        )
        let sortedMovies = movieCounts.sorted { $0.value > $1.value }

        let rankedMovies = sortedMovies.map { (title, count) -> RankedMedia in
            let representativeMovie = movies.first { $0.title == title }
            let posterPath = representativeMovie?.thumb
            let posterURL = posterPath.flatMap {
                URL(string: "\(serverURL)\($0)?X-Plex-Token=\(token)")
            }
            let subtitle = "Regardé \(count) fois"
            return RankedMedia(
                id: representativeMovie?.ratingKey ?? title,
                title: title,
                subtitle: subtitle,
                posterURL: posterURL
            )
        }

        let showCounts = Dictionary(
            episodes.map { ($0.showTitle, 1) },
            uniquingKeysWith: +
        )
        let sortedShows = showCounts.sorted { $0.value > $1.value }

        let rankedShows = sortedShows.map { (title, count) -> RankedMedia in
            let representativeShow = episodes.first { $0.showTitle == title }
            let posterPath = representativeShow?.grandparentThumb
            let posterURL = posterPath.flatMap {
                URL(string: "\(serverURL)\($0)?X-Plex-Token=\(token)")
            }
            let subtitle = "\(count) épisodes vus"
            return RankedMedia(
                id: representativeShow?.grandparentTitle ?? title,
                title: title,
                subtitle: subtitle,
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
