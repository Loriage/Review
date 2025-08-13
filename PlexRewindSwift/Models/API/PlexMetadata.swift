import Foundation

struct MetadataItem: Decodable {
    let duration: Int
    let summary: String?
    let year: Int?
    let art: String?
    let tagline: String?
    let genre: [Genre]?
    let director: [Genre]?
    let writer: [Genre]?
    let role: [Genre]?
    let studio: String?

    let title: String?
    let thumb: String?
    let grandparentThumb: String?
    let grandparentRatingKey: String?

    struct Genre: Decodable, Identifiable {
        let id: Int
        let tag: String
    }

    enum CodingKeys: String, CodingKey {
        case duration, summary, year, art, tagline, title, thumb, grandparentThumb, grandparentRatingKey, studio
        case genre = "Genre"
        case director = "Director"
        case writer = "Writer"
        case role = "Role"
    }
}
