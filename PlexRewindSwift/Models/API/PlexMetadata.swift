import Foundation

struct MetadataItem: Decodable {
    let duration: Int
    let summary: String?
    let year: Int?
    let art: String?
    let tagline: String?
    let genre: [Genre]?

    let title: String?
    let thumb: String?
    let grandparentThumb: String?
    let grandparentRatingKey: String?

    struct Genre: Decodable, Identifiable {
        let id: Int
        let tag: String
    }
}
