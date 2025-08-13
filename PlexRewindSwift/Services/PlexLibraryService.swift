import Foundation

struct PlexAllMediaResponse: Decodable {
    let mediaContainer: AllMediaContainer
    enum CodingKeys: String, CodingKey { case mediaContainer = "MediaContainer" }
}

struct AllMediaContainer: Decodable {
    let metadata: [MediaMetadata]
    let totalSize: Int?
    let offset: Int?
    
    enum CodingKeys: String, CodingKey {
        case metadata = "Metadata"
        case totalSize, offset
    }
}

struct MediaMetadata: Decodable, Identifiable {
    var id: String { ratingKey }
    let ratingKey: String
    let type: String
    let title: String?
    let thumb: String?
    let addedAt: Int?
    let updatedAt: Int?
    let lastViewedAt: TimeInterval?
    let viewCount: Int?
    let media: [PlexMediaPartContainer]?
    let grandparentRatingKey: String?

    enum CodingKeys: String, CodingKey {
        case ratingKey, type, title, thumb, addedAt, updatedAt, lastViewedAt, viewCount, grandparentRatingKey
        case media = "Media"
    }
}

class PlexLibraryService {
    
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
    
    func fetchLibraries(serverURL: String, token: String) async throws -> [PlexLibrary] {
        var urlComponents = URLComponents(string: "\(serverURL)/library/sections")!
        urlComponents.queryItems = [
            URLQueryItem(name: "includePreferences", value: "1"),
            URLQueryItem(name: "X-Plex-Token", value: token)
        ]
        
        guard let url = urlComponents.url else {
            throw PlexError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        let (data, _) = try await URLSession.shared.data(for: request)
        let decodedResponse = try JSONDecoder().decode(PlexLibraryResponse.self, from: data)
        return decodedResponse.mediaContainer.directories
    }

    func fetchAllMediaInSection(serverURL: String, token: String, libraryKey: String, mediaType: Int) async throws -> [MediaMetadata] {
        let baseURL = "\(serverURL)/library/sections/\(libraryKey)/all?type=\(mediaType)&X-Plex-Token=\(token)"

        return try await fetchPaginatedContent(baseURL: baseURL)
    }

    private func fetchPaginatedContent(baseURL: String) async throws -> [MediaMetadata] {
        let pageSize = 500
        var currentIndex = 0
        var allItems: [MediaMetadata] = []
        var shouldContinueFetching = true
        
        while shouldContinueFetching {
            let urlString = "\(baseURL)&X-Plex-Container-Start=\(currentIndex)&X-Plex-Container-Size=\(pageSize)"
            
            guard let url = URL(string: urlString) else { throw PlexError.invalidURL }
            
            var request = URLRequest(url: url)
            request.setValue("application/json", forHTTPHeaderField: "Accept")
            
            let (data, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
                throw PlexError.serverError(statusCode: (response as? HTTPURLResponse)?.statusCode ?? 0)
            }
            
            let decodedResponse = try JSONDecoder().decode(PlexAllMediaResponse.self, from: data)
            let newItems = decodedResponse.mediaContainer.metadata
            allItems.append(contentsOf: newItems)
            
            shouldContinueFetching = (newItems.count == pageSize)
            currentIndex += pageSize
        }
        return allItems
    }

    func fetchRecentlyAdded(serverURL: String, token: String, libraryKey: String, mediaType: Int) async throws -> [PlexRecentItem] {
        let urlString = "\(serverURL)/library/sections/\(libraryKey)/all?type=\(mediaType)&X-Plex-Container-Start=0&X-Plex-Container-Size=5&X-Plex-Token=\(token)"

        guard let url = URL(string: urlString) else { throw PlexError.invalidURL }

        var request = URLRequest(url: url)
        request.setValue("application/json", forHTTPHeaderField: "Accept")

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else { throw PlexError.serverError(statusCode: (response as? HTTPURLResponse)?.statusCode ?? 0) }

        let decodedResponse = try JSONDecoder().decode(PlexRecentlyAddedResponse.self, from: data)
        return decodedResponse.mediaContainer.metadata
    }

    func fetchMediaFromSection(serverURL: String, token: String, libraryKey: String, mediaType: Int, page: Int, pageSize: Int = 30) async throws -> (media: [MediaMetadata], totalCount: Int) {
        let startIndex = page * pageSize
        let urlString = "\(serverURL)/library/sections/\(libraryKey)/all?type=\(mediaType)&X-Plex-Container-Start=\(startIndex)&X-Plex-Container-Size=\(pageSize)&X-Plex-Token=\(token)"
        
        guard let url = URL(string: urlString) else { throw PlexError.invalidURL }
        
        var request = URLRequest(url: url)
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw PlexError.serverError(statusCode: (response as? HTTPURLResponse)?.statusCode ?? 0)
        }
        
        let decodedResponse = try JSONDecoder().decode(PlexAllMediaResponse.self, from: data)
        let media = decodedResponse.mediaContainer.metadata

        let totalCount = decodedResponse.mediaContainer.totalSize ?? media.count
        
        return (media, totalCount)
    }

    func scanLibrary(serverURL: String, token: String, libraryKey: String, force: Bool = false) async throws {
        var urlString = "\(serverURL)/library/sections/\(libraryKey)/refresh?X-Plex-Token=\(token)"
        if force {
            urlString += "&force=1"
        }
        
        guard let url = URL(string: urlString) else {
            throw PlexError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Accept")

        let (_, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw PlexError.serverError(statusCode: (response as? HTTPURLResponse)?.statusCode ?? 0)
        }
    }

    func fetchTopMedia(serverURL: String, token: String, type: Int) async throws -> [MediaMetadata] {
        let urlString = "\(serverURL)/library/all/top?type=\(type)&X-Plex-Token=\(token)"
        guard let url = URL(string: urlString) else {
            throw PlexError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue(APIConstants.clientIdentifier, forHTTPHeaderField: "X-Plex-Client-Identifier")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw PlexError.serverError(statusCode: (response as? HTTPURLResponse)?.statusCode ?? 0)
        }
        
        let decodedResponse = try JSONDecoder().decode(PlexAllMediaResponse.self, from: data)
        return decodedResponse.mediaContainer.metadata
    }

    func searchContent(serverURL: String, token: String, query: String) async throws -> [SearchResult] {
        guard var components = URLComponents(string: "\(serverURL)/search") else {
            throw PlexError.invalidURL
        }

        let searchTypes = "movie,show"

        components.queryItems = [
            URLQueryItem(name: "query", value: query),
            URLQueryItem(name: "limit", value: "30"),
            URLQueryItem(name: "searchTypes", value: searchTypes),
            URLQueryItem(name: "includeCollections", value: "1"),
            URLQueryItem(name: "X-Plex-Token", value: token)
        ]

        guard let url = components.url else {
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
            let decodedResponse = try JSONDecoder().decode(PlexSearchResponse.self, from: data)
            return decodedResponse.mediaContainer.metadata
        } catch {
            throw PlexError.decodingError(error)
        }
    }

    func fetchAllTitles(serverURL: String, token: String) async throws -> [String] {
        let allLibraries = try await fetchLibraries(serverURL: serverURL, token: token)
        var allTitles: [String] = []

        for library in allLibraries where library.type == "movie" || library.type == "show" {
            let mediaType = library.type == "movie" ? 1 : 2
            let media = try await fetchAllMediaInSection(serverURL: serverURL, token: token, libraryKey: library.key, mediaType: mediaType)
            allTitles.append(contentsOf: media.compactMap { $0.title })
        }

        return Array(Set(allTitles))
    }
}
