import Foundation

struct PlexLibraryResponse: Decodable {
    let mediaContainer: LibraryMediaContainer
    enum CodingKeys: String, CodingKey { case mediaContainer = "MediaContainer" }
}

struct LibraryMediaContainer: Decodable {
    let directories: [PlexLibrary]
    enum CodingKeys: String, CodingKey { case directories = "Directory" }
}

struct PlexLibraryContentResponse: Decodable {
    let mediaContainer: LibraryContentMediaContainer
    enum CodingKeys: String, CodingKey { case mediaContainer = "MediaContainer" }
}

struct LibraryContentMediaContainer: Decodable {
    let metadata: [PlexLibraryContentItem]
    enum CodingKeys: String, CodingKey {
        case metadata = "Metadata"
        case directories = "Directory"
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let metadata = try container.decodeIfPresent([PlexLibraryContentItem].self, forKey: .metadata) ?? []
        let directories = try container.decodeIfPresent([PlexLibraryContentItem].self, forKey: .directories) ?? []
        self.metadata = metadata + directories
    }
}
