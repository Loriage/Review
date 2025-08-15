
import Foundation

struct PlexLibraryContentItem: Decodable, Identifiable {
    var id: String { key }
    let key: String
    let title: String
    let type: String?
    let media: [PlexMediaPartContainer]?
    
    enum CodingKeys: String, CodingKey {
        case key, title, type
        case media = "Media"
    }
}

struct MediaPart: Decodable {
    let size: Int64
}

struct DirectoryItem: Decodable, Identifiable {
    var id: String { key }
    let key: String
    let title: String
    let secondary: Bool?
    let prompt: String?
    let search: Bool?
}
