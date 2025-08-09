import Foundation

struct PlexRecentlyAddedResponse: Decodable {
    let mediaContainer: RecentlyAddedMediaContainer
    enum CodingKeys: String, CodingKey { case mediaContainer = "MediaContainer" }
}

struct RecentlyAddedMediaContainer: Decodable {
    let metadata: [PlexRecentItem]
    enum CodingKeys: String, CodingKey { case metadata = "Metadata" }
}

struct PlexRecentItem: Decodable, Identifiable {
    var id: String { ratingKey }
    let ratingKey: String
    let type: String
    let thumb: String?
    let grandparentThumb: String?
}
