import Foundation

struct SearchHub: Decodable {
    let title: String
    let type: String
    let metadata: [SearchResult]

    enum CodingKeys: String, CodingKey {
        case title, type
        case metadata = "Metadata"
    }
}
