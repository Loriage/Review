import Foundation

struct PlexMediaDetailsResponse: Decodable {
    let mediaContainer: MediaDetailsContainer
    enum CodingKeys: String, CodingKey { case mediaContainer = "MediaContainer" }
}

struct MediaDetailsContainer: Decodable {
    let metadata: [MediaDetails]
    enum CodingKeys: String, CodingKey { case metadata = "Metadata" }
}
