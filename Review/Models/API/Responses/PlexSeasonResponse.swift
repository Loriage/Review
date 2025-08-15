import Foundation

struct PlexSeasonResponse: Decodable {
    let mediaContainer: SeasonMediaContainer
    enum CodingKeys: String, CodingKey { case mediaContainer = "MediaContainer" }
}

struct SeasonMediaContainer: Decodable {
    let metadata: [PlexSeason]
    enum CodingKeys: String, CodingKey { case metadata = "Metadata" }
}
