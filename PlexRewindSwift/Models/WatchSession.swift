import Foundation

struct PlexHistoryResponse: Decodable {
    let mediaContainer: MediaContainer
    
    enum CodingKeys: String, CodingKey {
        case mediaContainer = "MediaContainer"
    }
}

struct MediaContainer: Decodable {
    let size: Int
    let metadata: [WatchSession]

    enum CodingKeys: String, CodingKey {
        case size, metadata = "Metadata"
    }
}

struct WatchSession: Decodable, Identifiable {
    let id = UUID()
    
    let title: String?
    let type: String?
    let viewedAt: TimeInterval?
    var duration: Int?
    let ratingKey: String?
    let parentTitle: String?
    let grandparentTitle: String?
    let historyKey: String?
    
    let thumb: String?
    let grandparentThumb: String?

    var showTitle: String {
        return grandparentTitle ?? parentTitle ?? "N/A"
    }
    
    enum CodingKeys: String, CodingKey {
        case title, type, viewedAt, duration, ratingKey, parentTitle, grandparentTitle, historyKey, thumb, grandparentThumb
    }
}

