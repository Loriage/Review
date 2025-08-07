import Foundation

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

    private func performPutRequest(for urlString: String) async throws {
        guard let url = URL(string: urlString) else {
            throw PlexError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = "PUT"
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue(APIConstants.clientIdentifier, forHTTPHeaderField: "X-Plex-Client-Identifier")

        let (_, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw PlexError.serverError(statusCode: (response as? HTTPURLResponse)?.statusCode ?? 0)
        }
    }

    func refreshMetadata(for ratingKey: String, serverURL: String, token: String) async throws {
        let urlString = "\(serverURL)/library/metadata/\(ratingKey)/refresh?X-Plex-Token=\(token)"
        try await performPutRequest(for: urlString)
    }

    func analyzeMedia(for ratingKey: String, serverURL: String, token: String) async throws {
        let urlString = "\(serverURL)/library/metadata/\(ratingKey)/analyze?X-Plex-Token=\(token)"
        try await performPutRequest(for: urlString)
    }

    func fetchArtworks(for ratingKey: String, serverURL: String, token: String) async throws -> [PlexArtwork] {
        guard let url = URL(string: "\(serverURL)/library/metadata/\(ratingKey)/posters?X-Plex-Token=\(token)") else {
            throw PlexError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw PlexError.serverError(statusCode: (response as? HTTPURLResponse)?.statusCode ?? 0)
        }
        
        do {
            let decodedResponse = try JSONDecoder().decode(PlexArtworkResponse.self, from: data)

            return decodedResponse.mediaContainer.metadata
        } catch {
            throw PlexError.decodingError(error)
        }
    }

    func setArtwork(for ratingKey: String, artworkKey: String, serverURL: String, token: String) async throws {
        guard let encodedArtworkURL = artworkKey.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) else {
            throw PlexError.invalidURL
        }

        let urlString = "\(serverURL)/library/metadata/\(ratingKey)/poster?url=\(encodedArtworkURL)&X-Plex-Token=\(token)"
        try await performPutRequest(for: urlString)
    }

    func fetchMatches(for ratingKey: String, serverURL: String, token: String) async throws -> [PlexMatch] {
        let urlString = "\(serverURL)/library/metadata/\(ratingKey)/matches?manual=1&X-Plex-Token=\(token)"
        guard let url = URL(string: urlString) else {
            throw PlexError.invalidURL
        }

        var request = URLRequest(url: url)
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        
        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw PlexError.serverError(statusCode: (response as? HTTPURLResponse)?.statusCode ?? 0)
        }

        let decodedResponse = try JSONDecoder().decode(PlexMatchResponse.self, from: data)
        return decodedResponse.mediaContainer.searchResults
    }

    func applyMatch(for ratingKey: String, guid: String, name: String, year: Int?, serverURL: String, token: String) async throws {
        guard let encodedGuid = guid.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
              let encodedName = name.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) else {
            throw PlexError.invalidURL
        }

        var urlString = "\(serverURL)/library/metadata/\(ratingKey)/match?guid=\(encodedGuid)&name=\(encodedName)"
        
        if let year = year {
            urlString += "&year=\(year)"
        }
        
        urlString += "&X-Plex-Token=\(token)"
        
        try await performPutRequest(for: urlString)
    }
}
