import Foundation

struct PlexPrefsResponse: Decodable {
    let mediaContainer: PrefsMediaContainer
    enum CodingKeys: String, CodingKey { case mediaContainer = "MediaContainer" }
}

struct PrefsMediaContainer: Decodable {
    let size: Int
    let setting: [PlexServerSetting]
    
    enum CodingKeys: String, CodingKey {
        case size
        case setting = "Setting"
    }
}
