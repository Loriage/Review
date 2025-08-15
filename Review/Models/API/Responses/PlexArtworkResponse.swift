import Foundation

struct PlexArtworkResponse: Decodable {
    let mediaContainer: ArtworkMediaContainer
    enum CodingKeys: String, CodingKey { case mediaContainer = "MediaContainer" }
}

struct ArtworkMediaContainer: Decodable {
    let metadata: [PlexArtwork]
    enum CodingKeys: String, CodingKey { case metadata = "Metadata" }
}
