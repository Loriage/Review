import Foundation

struct PlexEpisode: Decodable, Identifiable, Hashable {
    var id: String { ratingKey }
    let ratingKey: String
    let title: String
    let thumb: String?
    let index: Int?
    let summary: String?
    let duration: Int?
    let viewOffset: Int?
}
