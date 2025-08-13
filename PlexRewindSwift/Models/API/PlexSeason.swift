import Foundation

struct PlexSeason: Decodable, Identifiable, Hashable {
    var id: String { ratingKey }
    let ratingKey: String
    let key: String
    let title: String
    let leafCount: Int
    let thumb: String?
    let index: Int?
}
