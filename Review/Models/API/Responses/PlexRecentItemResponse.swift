import Foundation

struct PlexRecentlyAddedResponse: Decodable {
    let mediaContainer: RecentlyAddedMediaContainer
    enum CodingKeys: String, CodingKey { case mediaContainer = "MediaContainer" }
}

struct RecentlyAddedMediaContainer: Decodable {
    let metadata: [PlexRecentItem]
    enum CodingKeys: String, CodingKey { case metadata = "Metadata" }
}
