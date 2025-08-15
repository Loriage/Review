import Foundation

struct PlexEpisodeResponse: Decodable {
    let mediaContainer: EpisodeMediaContainer
    enum CodingKeys: String, CodingKey { case mediaContainer = "MediaContainer" }
}

struct EpisodeMediaContainer: Decodable {
    let metadata: [PlexEpisode]
    enum CodingKeys: String, CodingKey { case metadata = "Metadata" }
}
