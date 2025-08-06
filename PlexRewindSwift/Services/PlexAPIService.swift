import Foundation

enum PlexError: Error, LocalizedError {
    case invalidURL
    case networkError(Error)
    case decodingError(Error)
    case noData
    case serverError(statusCode: Int)

    var errorDescription: String? {
        switch self {
        case .invalidURL: return "L'URL du serveur est invalide."
        case .networkError(let error):
            return "Erreur réseau: \(error.localizedDescription)"
        case .decodingError:
            return "Erreur lors de la lecture des données du serveur."
        case .noData: return "Aucune donnée reçue du serveur."
        case .serverError(let statusCode):
            return "Erreur du serveur (code: \(statusCode))."
        }
    }
}

class PlexAPIService {
    func fetchWatchHistory(
        serverURL: String,
        token: String,
        year: Int,
        userID: Int?,
        progressUpdate: @escaping (Int) async -> Void
    ) async throws -> [WatchSession] {

        let pageSize = 250
        var currentIndex = 0
        var allSessions: [WatchSession] = []
        var shouldContinueFetching = true

        var lastHistoryKey: String? = nil

        let calendar = Calendar.current
        let startDateComponents = DateComponents(year: year, month: 1, day: 1)
        guard let yearStartDate = calendar.date(from: startDateComponents) else {
            throw PlexError.invalidURL
        }

        while shouldContinueFetching {
            var urlString =
                "\(serverURL)/status/sessions/history/all?sort=viewedAt:desc&count=\(pageSize)&start=\(currentIndex)"

            if let userID = userID {
                urlString += "&accountID=\(userID)"
            }

            urlString += "&X-Plex-Token=\(token)"

            guard let url = URL(string: urlString) else {
                throw PlexError.invalidURL
            }

            var request = URLRequest(url: url)
            request.setValue("application/json", forHTTPHeaderField: "Accept")
            request.timeoutInterval = 20
            request.setValue(
                APIConstants.clientIdentifier,
                forHTTPHeaderField: "X-Plex-Client-Identifier"
            )

            let (data, response) = try await URLSession.shared.data(for: request)

            guard let httpResponse = response as? HTTPURLResponse,
                httpResponse.statusCode == 200
            else {
                throw PlexError.serverError(
                    statusCode: (response as? HTTPURLResponse)?.statusCode ?? 0
                )
            }

            let decodedResponse = try JSONDecoder().decode(
                PlexHistoryResponse.self,
                from: data
            )
            let newSessions = decodedResponse.mediaContainer.metadata

            guard !newSessions.isEmpty else {
                shouldContinueFetching = false
                continue
            }

            if let firstNewSessionKey = newSessions.first?.historyKey,
                firstNewSessionKey == lastHistoryKey
            {
                shouldContinueFetching = false
                continue
            }

            lastHistoryKey = newSessions.first?.historyKey

            allSessions.append(contentsOf: newSessions)
            await progressUpdate(allSessions.count)

            if let lastSession = newSessions.last,
                let viewedAt = lastSession.viewedAt
            {
                let lastSessionDate = Date(timeIntervalSince1970: viewedAt)
                if lastSessionDate < yearStartDate {
                    shouldContinueFetching = false
                }
            }

            currentIndex += pageSize
        }

        return allSessions
    }

    func fetchDuration(
        for ratingKey: String,
        serverURL: String,
        token: String
    ) async throws -> Int? {
        guard let url = URL(
            string: "\(serverURL)/library/metadata/\(ratingKey)?X-Plex-Token=\(token)"
        ) else {
            return nil
        }

        var request = URLRequest(url: url)
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue(
            APIConstants.clientIdentifier,
            forHTTPHeaderField: "X-Plex-Client-Identifier"
        )

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse,
            httpResponse.statusCode == 200
        else {
            return nil
        }

        let decodedResponse = try JSONDecoder().decode(
            PlexMetadataResponse.self,
            from: data
        )
        return decodedResponse.mediaContainer.metadata.first?.duration
    }

    func fetchServers(token: String) async throws -> [PlexResource] {
        guard let url = URL(string: "https://plex.tv/api/v2/resources") else {
            throw PlexError.invalidURL
        }

        var request = URLRequest(url: url)

        request.setValue(token, forHTTPHeaderField: "X-Plex-Token")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue(
            APIConstants.clientIdentifier,
            forHTTPHeaderField: "X-Plex-Client-Identifier"
        )

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse,
            httpResponse.statusCode == 200
        else {
            throw PlexError.serverError(
                statusCode: (response as? HTTPURLResponse)?.statusCode ?? 0
            )
        }

        do {
            let allResources = try JSONDecoder().decode(
                [PlexResource].self,
                from: data
            )

            return allResources.filter { $0.isServer }
        } catch {
            throw PlexError.decodingError(error)
        }
    }

    func fetchUsers(serverURL: String, token: String) async throws -> [PlexUser] {
        guard let url = URL(
            string: "\(serverURL)/accounts?X-Plex-Token=\(token)"
        ) else {
            throw PlexError.invalidURL
        }

        var request = URLRequest(url: url)
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue(
            APIConstants.clientIdentifier,
            forHTTPHeaderField: "X-Plex-Client-Identifier"
        )

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse,
            httpResponse.statusCode == 200
        else {
            throw PlexError.serverError(
                statusCode: (response as? HTTPURLResponse)?.statusCode ?? 0
            )
        }

        do {
            let userResponse = try JSONDecoder().decode(
                PlexUserResponse.self,
                from: data
            )
            return userResponse.mediaContainer.users
        } catch {
            throw PlexError.decodingError(error)
        }
    }

    func fetchMediaDetails(
            for ratingKey: String,
            serverURL: String,
            token: String
    ) async throws -> MetadataItem? {
        guard let url = URL(
            string: "\(serverURL)/library/metadata/\(ratingKey)?X-Plex-Token=\(token)"
        ) else {
            throw PlexError.invalidURL
        }

        var request = URLRequest(url: url)
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue(
            APIConstants.clientIdentifier,
            forHTTPHeaderField: "X-Plex-Client-Identifier"
        )

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200
        else {
            return nil
        }

        let decodedResponse = try JSONDecoder().decode(
            PlexMetadataResponse.self,
            from: data
        )
        return decodedResponse.mediaContainer.metadata.first
    }

    func fetchCurrentActivity(serverURL: String, token: String) async throws -> [PlexActivitySession] {
        guard let url = URL(string: "\(serverURL)/status/sessions?X-Plex-Token=\(token)") else {
            throw PlexError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue(APIConstants.clientIdentifier, forHTTPHeaderField: "X-Plex-Client-Identifier")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw PlexError.serverError(statusCode: (response as? HTTPURLResponse)?.statusCode ?? 0)
        }
        
        do {
            let decodedResponse = try JSONDecoder().decode(PlexActivityResponse.self, from: data)
            return decodedResponse.mediaContainer.metadata
        } catch {
            throw PlexError.decodingError(error)
        }
    }
}
