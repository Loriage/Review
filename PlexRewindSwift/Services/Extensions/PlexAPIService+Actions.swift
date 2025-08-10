import Foundation

extension PlexAPIService {
    func refreshMetadata(for ratingKey: String, serverURL: String, token: String) async throws {
        let urlString = "\(serverURL)/library/metadata/\(ratingKey)/refresh?X-Plex-Token=\(token)"
        try await performPutRequest(for: urlString)
    }

    func analyzeMedia(for ratingKey: String, serverURL: String, token: String) async throws {
        let urlString = "\(serverURL)/library/metadata/\(ratingKey)/analyze?X-Plex-Token=\(token)"
        try await performPutRequest(for: urlString)
    }

    func setArtwork(for ratingKey: String, artworkKey: String, serverURL: String, token: String) async throws {
        guard let encodedArtworkURL = artworkKey.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) else {
            throw PlexError.invalidURL
        }
        let urlString = "\(serverURL)/library/metadata/\(ratingKey)/poster?url=\(encodedArtworkURL)&X-Plex-Token=\(token)"
        try await performPutRequest(for: urlString)
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

    func analyzeLibrarySection(libraryKey: String, serverURL: String, token: String) async throws {
        let urlString = "\(serverURL)/library/sections/\(libraryKey)/analyze?X-Plex-Token=\(token)"
        try await performPutRequest(for: urlString)
    }

    func emptyLibraryTrash(libraryKey: String, serverURL: String, token: String) async throws {
        let urlString = "\(serverURL)/library/sections/\(libraryKey)/emptyTrash?X-Plex-Token=\(token)"
        try await performPutRequest(for: urlString)
    }

    func updateLibraryPreferences(for libraryKey: String, preferences: [String: String], serverURL: String, token: String) async throws {
        var urlComponents = URLComponents(string: "\(serverURL)/library/sections/\(libraryKey)")!
        
        var queryItems: [URLQueryItem] = []

        queryItems.append(URLQueryItem(name: "agent", value: "tv.plex.agents.movie"))

        if let hidden = preferences["prefs[hidden]"] {
            queryItems.append(URLQueryItem(name: "prefs[hidden]", value: hidden))
        }

        if let enableTrailers = preferences["prefs[enableCinemaTrailers]"] {
            queryItems.append(URLQueryItem(name: "prefs[enableCinemaTrailers]", value: enableTrailers))
        }

        queryItems.append(URLQueryItem(name: "X-Plex-Token", value: token))
        
        urlComponents.queryItems = queryItems
        
        guard let url = urlComponents.url else {
            throw PlexError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "PUT"

        try await performPutRequest(for: request)
    }
}

extension PlexAPIService {
    internal func performPutRequest(for request: URLRequest) async throws {
        let (_, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw PlexError.serverError(statusCode: (response as? HTTPURLResponse)?.statusCode ?? 0)
        }
    }
}
