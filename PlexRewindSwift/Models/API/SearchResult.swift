import Foundation

struct SearchResult: Decodable, Identifiable {
    var id: String { ratingKey }

    let ratingKey: String
    let key: String
    let type: String
    let title: String
    let summary: String?
    let thumb: String?
    let year: Int?
    let leafCount: Int?
    let index: Int?
    let parentIndex: Int?
    let grandparentKey: String?
    let grandparentRatingKey: String?
    let grandparentTitle: String?
    let grandparentThumb: String?

    var posterPath: String? {
        return thumb ?? grandparentThumb
    }

    var effectiveGrandparentRatingKey: String? {
        return grandparentRatingKey ?? grandparentKey
    }
}
