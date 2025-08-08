import Foundation

struct PlexArtworkResponse: Decodable {
    let mediaContainer: ArtworkMediaContainer
    enum CodingKeys: String, CodingKey { case mediaContainer = "MediaContainer" }
}

struct ArtworkMediaContainer: Decodable {
    let metadata: [PlexArtwork]
    enum CodingKeys: String, CodingKey { case metadata = "Metadata" }
}

struct PlexArtwork: Decodable, Identifiable, Equatable {
    var id: String { key }
    let key: String
    
    let provider: String?
    var selected: Bool?
    let ratingKey: String?
    let thumb: String?
}
