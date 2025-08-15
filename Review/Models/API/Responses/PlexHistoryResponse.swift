import Foundation

struct PlexHistoryResponse: Decodable {
    let mediaContainer: HistoryMediaContainer
    enum CodingKeys: String, CodingKey { case mediaContainer = "MediaContainer" }
}

struct HistoryMediaContainer: Decodable {
    let size: Int
    let metadata: [WatchSession]
    enum CodingKeys: String, CodingKey { case size, metadata = "Metadata" }
}
