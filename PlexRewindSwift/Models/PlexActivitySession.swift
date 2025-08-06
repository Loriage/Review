import Foundation

struct PlexActivityResponse: Decodable {
    let mediaContainer: ActivityMediaContainer

    enum CodingKeys: String, CodingKey {
        case mediaContainer = "MediaContainer"
    }
}

struct ActivityMediaContainer: Decodable {
    let size: Int
    let metadata: [PlexActivitySession]

    enum CodingKeys: String, CodingKey {
        case size, metadata = "Metadata"
    }
}

struct PlexActivitySession: Decodable, Identifiable {
    var id: String { sessionKey ?? ratingKey }

    let ratingKey: String
    let sessionKey: String?
    let title: String
    let type: String
    let duration: Int
    let viewOffset: Int

    let grandparentTitle: String?
    let parentThumb: String?
    let grandparentThumb: String?
    let thumb: String?
    
    let parentIndex: Int?
    let index: Int?
    let year: Int?

    let user: User
    let player: Player

    var posterURL: URL?
    var location: String?

    var showTitle: String {
        return grandparentTitle ?? title
    }
    
    var progress: Double {
        return Double(viewOffset) / Double(duration)
    }

    var remainingTimeInSeconds: Int {
        return (duration - viewOffset) / 1000
    }

    struct User: Decodable {
        let id: String
        let title: String
        let thumb: String?
    }
    
    struct Player: Decodable {
        let platform: String
        let product: String
        let state: String
        let local: Bool
        let address: String
    }
    
    enum CodingKeys: String, CodingKey {
        case ratingKey, sessionKey, title, type, duration, viewOffset, grandparentTitle, parentThumb, grandparentThumb, thumb, parentIndex, index, year, user = "User", player = "Player"
    }
}
