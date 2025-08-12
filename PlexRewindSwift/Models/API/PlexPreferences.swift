import Foundation

struct PlexPreferences: Decodable {
    let settings: [PlexSetting]
    
    enum CodingKeys: String, CodingKey {
        case settings = "Setting"
    }
}

struct PlexSetting: Decodable {
    let id: String
    let label: String
    let summary: String
    let type: String
    let value: String
    let enumValues: String?
}

struct EnumValue: Identifiable, Hashable {
    let id: String
    let name: String
}
