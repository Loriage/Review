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
