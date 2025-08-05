import Foundation

struct PlexUserResponse: Decodable {
    let mediaContainer: UserMediaContainer

    enum CodingKeys: String, CodingKey {
        case mediaContainer = "MediaContainer"
    }
}

struct UserMediaContainer: Decodable {
    let users: [PlexUser]

    enum CodingKeys: String, CodingKey {
        case users = "Account"
    }
}

struct PlexUser: Decodable, Identifiable, Hashable {
    let id: Int
    let title: String
    let thumb: String?
}
