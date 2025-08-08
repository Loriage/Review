import Foundation
struct PlexAllMediaResponse: Decodable {
    let mediaContainer: AllMediaContainer
    enum CodingKeys: String, CodingKey { case mediaContainer = "MediaContainer" }
}

struct AllMediaContainer: Decodable {
    let metadata: [MediaMetadata]
    enum CodingKeys: String, CodingKey { case metadata = "Metadata" }
}

struct MediaMetadata: Decodable {
    let media: [PlexMediaPartContainer]?
    enum CodingKeys: String, CodingKey { case media = "Media" }
}

extension PlexAPIService {
    func fetchServers(token: String) async throws -> [PlexResource] {
        guard let url = URL(string: "https://plex.tv/api/v2/resources") else {
            throw PlexError.invalidURL
        }

        var request = URLRequest(url: url)
        request.setValue(token, forHTTPHeaderField: "X-Plex-Token")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue(APIConstants.clientIdentifier, forHTTPHeaderField: "X-Plex-Client-Identifier")

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse,
            httpResponse.statusCode == 200
        else {
            throw PlexError.serverError(statusCode: (response as? HTTPURLResponse)?.statusCode ?? 0)
        }

        do {
            let allResources = try JSONDecoder().decode([PlexResource].self, from: data)
            return allResources.filter { $0.isServer }
        } catch {
            throw PlexError.decodingError(error)
        }
    }

    func fetchUsers(serverURL: String, token: String) async throws -> [PlexUser] {
        guard let url = URL(string: "\(serverURL)/accounts?X-Plex-Token=\(token)") else {
            throw PlexError.invalidURL
        }

        var request = URLRequest(url: url)
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue(APIConstants.clientIdentifier, forHTTPHeaderField: "X-Plex-Client-Identifier")

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse,
            httpResponse.statusCode == 200
        else {
            throw PlexError.serverError(statusCode: (response as? HTTPURLResponse)?.statusCode ?? 0)
        }

        do {
            let userResponse = try JSONDecoder().decode(PlexUserResponse.self, from: data)
            return userResponse.mediaContainer.users
        } catch {
            throw PlexError.decodingError(error)
        }
    }

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
        guard let yearStartDate = calendar.date(from: DateComponents(year: year, month: 1, day: 1)) else {
            throw PlexError.invalidURL
        }

        while shouldContinueFetching {
            var urlString = "\(serverURL)/status/sessions/history/all?sort=viewedAt:desc&count=\(pageSize)&start=\(currentIndex)"
            if let userID = userID {
                urlString += "&accountID=\(userID)"
            }
            urlString += "&X-Plex-Token=\(token)"

            guard let url = URL(string: urlString) else { throw PlexError.invalidURL }

            var request = URLRequest(url: url)
            request.setValue("application/json", forHTTPHeaderField: "Accept")
            request.setValue(APIConstants.clientIdentifier, forHTTPHeaderField: "X-Plex-Client-Identifier")
            request.timeoutInterval = 20

            let (data, response) = try await URLSession.shared.data(for: request)

            guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
                throw PlexError.serverError(statusCode: (response as? HTTPURLResponse)?.statusCode ?? 0)
            }

            let decodedResponse = try JSONDecoder().decode(PlexHistoryResponse.self, from: data)
            let newSessions = decodedResponse.mediaContainer.metadata

            guard !newSessions.isEmpty else {
                shouldContinueFetching = false
                continue
            }

            if let firstNewSessionKey = newSessions.first?.historyKey, firstNewSessionKey == lastHistoryKey {
                shouldContinueFetching = false
                continue
            }

            lastHistoryKey = newSessions.first?.historyKey
            allSessions.append(contentsOf: newSessions)
            await progressUpdate(allSessions.count)

            if let lastSession = newSessions.last, let viewedAt = lastSession.viewedAt {
                let lastSessionDate = Date(timeIntervalSince1970: viewedAt)
                if lastSessionDate < yearStartDate {
                    shouldContinueFetching = false
                }
            }
            currentIndex += pageSize
        }
        return allSessions
    }

    func fetchLibraries(serverURL: String, token: String) async throws -> [PlexLibrary] {
        guard let url = URL(string: "\(serverURL)/library/sections?X-Plex-Token=\(token)") else {
            throw PlexError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw PlexError.serverError(statusCode: (response as? HTTPURLResponse)?.statusCode ?? 0)
        }
        
        do {
            let decodedResponse = try JSONDecoder().decode(PlexLibraryResponse.self, from: data)
            return decodedResponse.mediaContainer.directories
        } catch {
            throw PlexError.decodingError(error)
        }
    }

    func fetchAllMediaInSection(serverURL: String, token: String, libraryKey: String) async throws -> [MediaMetadata] {
        guard let url = URL(string: "\(serverURL)/library/sections/\(libraryKey)/all?type=1&X-Plex-Token=\(token)") else {
            throw PlexError.invalidURL
        }

        var request = URLRequest(url: url)
        request.setValue("application/json", forHTTPHeaderField: "Accept")

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw PlexError.serverError(statusCode: (response as? HTTPURLResponse)?.statusCode ?? 0)
        }

        do {
            let decodedResponse = try JSONDecoder().decode(PlexAllMediaResponse.self, from: data)
            return decodedResponse.mediaContainer.metadata
        } catch {
            print("⚠️ Erreur de décodage pour la section \(libraryKey): \(error)")
            throw PlexError.decodingError(error)
        }
    }
}
