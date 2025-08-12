import Foundation

struct PlexUser: Decodable, Identifiable, Hashable {
    let id: Int
    let title: String
    var thumb: String?

    enum CodingKeys: String, CodingKey {
        case id
        case title = "name"
        case thumb
    }
}
