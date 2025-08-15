import Foundation

struct PlexAccount: Decodable {
    let id: Int
    let uuid: String?
    let username: String
    let title: String?
    let email: String?
    let thumb: String?
    let subscription: PlexSubscription?
}

struct PlexSubscription: Decodable {
    let active: Bool
    let status: String?
}
