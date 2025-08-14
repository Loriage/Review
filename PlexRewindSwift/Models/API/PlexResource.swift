import Foundation

struct PlexResource: Codable, Identifiable {
    let name: String
    let product: String
    let productVersion: String
    let platform: String
    let platformVersion: String
    let clientIdentifier: String
    let createdAt: String
    let lastSeenAt: String
    let provides: String
    let ownerId: Int?
    let sourceTitle: String?
    let accessToken: String?
    let publicAddress: String
    let connections: [PlexConnection]

    var id: String { clientIdentifier }

    var isServer: Bool {
        provides == "server" && !connections.isEmpty
    }
}

struct PlexConnection: Codable, Hashable {
    let uri: String
    let address: String
    let port: Int
    let `protocol`: String
    let local: Bool
}
