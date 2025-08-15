import Foundation

struct PlexMetadataResponse: Decodable {
    let mediaContainer: MetadataMediaContainer

    enum CodingKeys: String, CodingKey {
        case mediaContainer = "MediaContainer"
    }
}

struct MetadataMediaContainer: Decodable {
    let metadata: [MetadataItem]

    enum CodingKeys: String, CodingKey {
        case metadata = "Metadata"
    }
}
