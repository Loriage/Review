import Foundation

struct MetadataItem: Decodable {
    let duration: Int?
    var summary: String?
    let year: Int?
    let art: String?
    let tagline: String?
    var genre: [Genre]?
    var director: [Genre]?
    var writer: [Genre]?
    var role: [Genre]?
    var studio: String?

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
