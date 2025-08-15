import Foundation

struct PlexLibrary: Decodable, Identifiable {
    var id: String { uuid }
    let key: String
    let type: String
    let title: String
    let agent: String
    let scanner: String
    let language: String
    let uuid: String
    let updatedAt: Int
    let createdAt: Int
    let scannedAt: Int
    let hidden: Int
    let enableCinemaTrailers: Bool?
    let locations: [PlexLibraryLocation]
    let preferences: PlexPreferences?
    
    enum CodingKeys: String, CodingKey {
        case key, type, title, agent, scanner, language, uuid, updatedAt, createdAt, scannedAt, hidden, enableCinemaTrailers
        case locations = "Location"
        case preferences = "Preferences"
    }
}

struct PlexLibraryLocation: Decodable, Identifiable {
    let id: Int
    let path: String
}
