import Foundation

struct PlexArtwork: Decodable, Identifiable, Equatable {
    var id: String { key }
    let key: String
    
    let provider: String?
    var selected: Bool?
    let ratingKey: String?
    let thumb: String?
}
