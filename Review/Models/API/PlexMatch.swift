import Foundation

struct PlexMatch: Decodable, Identifiable {
    var id: String { guid }
    let guid: String
    let name: String
    let year: Int?
    let summary: String?
    let thumb: String?

    enum CodingKeys: String, CodingKey {
        case guid, name, year, summary, thumb
    }
}
