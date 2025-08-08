import Foundation

struct PlexPin: Codable {
    let id: Int
    let code: String
    let product: String
    let trusted: Bool
    let qr: String
    let clientIdentifier: String
    let expiresIn: Int
    let createdAt: String
    let expiresAt: String
    let authToken: String?
}
