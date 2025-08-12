import Foundation

class PlexMetadataService {
    func fetchDuration(for ratingKey: String, serverURL: String, token: String) async throws -> Int? {
        guard let url = URL(string: "\(serverURL)/library/metadata/\(ratingKey)?X-Plex-Token=\(token)") else {
            return nil
        }

        var request = URLRequest(url: url)
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue(APIConstants.clientIdentifier, forHTTPHeaderField: "X-Plex-Client-Identifier")

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            return nil
        }

        let decodedResponse = try JSONDecoder().decode(PlexMetadataResponse.self, from: data)
        return decodedResponse.mediaContainer.metadata.first?.duration
    }

    func fetchMediaDetails(for ratingKey: String, serverURL: String, token: String) async throws -> MetadataItem? {
        guard let url = URL(string: "\(serverURL)/library/metadata/\(ratingKey)?X-Plex-Token=\(token)") else {
            throw PlexError.invalidURL
        }

        var request = URLRequest(url: url)
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue(APIConstants.clientIdentifier, forHTTPHeaderField: "X-Plex-Client-Identifier")

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            return nil
        }

        let decodedResponse = try JSONDecoder().decode(PlexMetadataResponse.self, from: data)
        return decodedResponse.mediaContainer.metadata.first
    }

    func fetchFullMediaDetails(for ratingKey: String, serverURL: String, token: String) async throws -> MediaDetails? {
        guard let url = URL(string: "\(serverURL)/library/metadata/\(ratingKey)?X-Plex-Token=\(token)") else {
            throw PlexError.invalidURL
        }

        var request = URLRequest(url: url)
        request.setValue("application/json", forHTTPHeaderField: "Accept")

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw PlexError.serverError(statusCode: (response as? HTTPURLResponse)?.statusCode ?? 0)
        }

        let decodedResponse = try JSONDecoder().decode(PlexMediaDetailsResponse.self, from: data)
        return decodedResponse.mediaContainer.metadata.first
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
}
