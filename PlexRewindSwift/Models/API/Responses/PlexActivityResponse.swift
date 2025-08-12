import Foundation

struct PlexActivityResponse: Decodable {
    let mediaContainer: ActivityMediaContainer

    enum CodingKeys: String, CodingKey {
        case mediaContainer = "MediaContainer"
    }
}
