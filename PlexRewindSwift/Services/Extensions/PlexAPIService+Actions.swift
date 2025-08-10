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
}
