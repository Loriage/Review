import Foundation

struct PlexSearchResponse: Decodable {
    let mediaContainer: SearchMediaContainer

    enum CodingKeys: String, CodingKey {
        case mediaContainer = "MediaContainer"
    }
}

struct SearchMediaContainer: Decodable {
    let size: Int
    let metadata: [SearchResult]

    enum CodingKeys: String, CodingKey {
        case size
        case metadata = "Metadata"
        case hubs = "Hub"
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        size = try container.decode(Int.self, forKey: .size)

        if let directMetadata = try? container.decode([SearchResult].self, forKey: .metadata) {
            self.metadata = directMetadata
        } else if let hubs = try? container.decode([SearchHub].self, forKey: .hubs) {
            self.metadata = hubs.flatMap { $0.metadata }
        } else {
            self.metadata = []
        }
    }
}
