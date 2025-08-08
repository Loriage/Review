import Foundation

struct PlexMatchResponse: Decodable {
    let mediaContainer: MatchMediaContainer

    enum CodingKeys: String, CodingKey {
        case mediaContainer = "MediaContainer"
    }
}

struct MatchMediaContainer: Decodable {
    let searchResults: [PlexMatch]

    enum CodingKeys: String, CodingKey {
        case searchResults = "SearchResult"
    }
}

struct PlexMatch: Decodable, Identifiable {
    var id: String { guid }
    let guid: String
    let name: String
    let year: Int?
    let summary: String?
    let thumb: String?

    enum CodingKeys: String, CodingKey {
        case guid, name, year, summary, thumb
    }
}
