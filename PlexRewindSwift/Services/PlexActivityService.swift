import Foundation

class PlexActivityService {
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
}
