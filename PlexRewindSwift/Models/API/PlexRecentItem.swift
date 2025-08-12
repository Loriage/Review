import Foundation

struct PlexRecentItem: Decodable, Identifiable {
    var id: String { ratingKey }
    let ratingKey: String
    let type: String
    let thumb: String?
    let grandparentThumb: String?
}
