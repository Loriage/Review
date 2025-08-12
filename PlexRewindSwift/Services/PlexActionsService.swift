import Foundation

class PlexActionsService {
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

        let orderedKeys = [
            "prefs[hidden]", "prefs[country]", "prefs[enableCinemaTrailers]",
            "prefs[originalTitles]", "prefs[localizedArtwork]", "prefs[useLocalAssets]",
            "prefs[respectTags]", "prefs[useExternalExtras]", "prefs[collectionMode]",
            "prefs[skipNonTrailerExtras]", "prefs[useRedbandTrailers]",
            "prefs[includeExtrasWithLocalizedSubtitles]", "prefs[includeAdultContent]",
            "prefs[autoCollectionThreshold]", "prefs[ratingsSource]", "prefs[enableBIFGeneration]",
            "prefs[enableCreditsMarkerGeneration]", "prefs[enableVoiceActivityGeneration]",
            "prefs[enableAdMarkerGeneration]"
        ]

        for key in orderedKeys {
            if let value = preferences[key] {
                queryItems.append(URLQueryItem(name: key, value: value))
            }
        }

        queryItems.append(URLQueryItem(name: "agent", value: "tv.plex.agents.movie"))
        queryItems.append(URLQueryItem(name: "X-Plex-Token", value: token))
        
        urlComponents.queryItems = queryItems
        
        guard let url = urlComponents.url else {
            throw PlexError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "PUT"
        try await performPutRequest(for: request)
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
    
    private func performPutRequest(for request: URLRequest) async throws {
        let (_, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw PlexError.serverError(statusCode: (response as? HTTPURLResponse)?.statusCode ?? 0)
        }
    }
}
