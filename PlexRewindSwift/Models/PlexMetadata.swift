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

struct MetadataItem: Decodable {
    let duration: Int
    let summary: String?
    let year: Int?
    let art: String?
    let tagline: String?
    let genre: [Genre]?

    struct Genre: Decodable, Identifiable {
        let id: Int
        let tag: String
    }
}
