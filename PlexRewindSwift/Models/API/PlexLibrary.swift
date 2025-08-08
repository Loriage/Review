import Foundation

struct PlexLibraryResponse: Decodable {
    let mediaContainer: LibraryMediaContainer
    
    enum CodingKeys: String, CodingKey {
        case mediaContainer = "MediaContainer"
    }
}

struct LibraryMediaContainer: Decodable {
    let directories: [PlexLibrary]
    
    enum CodingKeys: String, CodingKey {
        case directories = "Directory"
    }
}

struct PlexLibrary: Decodable, Identifiable {
    var id: String { uuid }
    let key: String
    let type: String
    let title: String
    let agent: String
    let scanner: String
    let language: String
    let uuid: String
    let updatedAt: Int
    let createdAt: Int
    let scannedAt: Int
    let hidden: Int
    let locations: [PlexLibraryLocation]
    
    enum CodingKeys: String, CodingKey {
        case key, type, title, agent, scanner, language, uuid, updatedAt, createdAt, scannedAt, hidden
        case locations = "Location"
    }
}

struct PlexLibraryLocation: Decodable, Identifiable {
    let id: Int
    let path: String
}

struct PlexLibraryDetailResponse: Decodable {
    let mediaContainer: LibraryDetailMediaContainer
    
    enum CodingKeys: String, CodingKey {
        case mediaContainer = "MediaContainer"
    }
}

struct LibraryDetailMediaContainer: Decodable {
    let size: Int
    let art: String?
    let content: String?
    let identifier: String?
    let librarySectionID: Int
    let mediaTagPrefix: String?
    let mediaTagVersion: Int?
    let thumb: String?
    let title1: String
    let viewGroup: String
    let directories: [DirectoryItem]
    
    enum CodingKeys: String, CodingKey {
        case size, art, content, identifier, librarySectionID, mediaTagPrefix, mediaTagVersion, thumb, title1, viewGroup
        case directories = "Directory"
    }
}

struct DirectoryItem: Decodable, Identifiable {
    var id: String { key }
    let key: String
    let title: String
    let secondary: Bool?
    let prompt: String?
    let search: Bool?
}

struct PlexMediaItemResponse: Decodable {
    let mediaContainer: MediaItemContainer
    
    enum CodingKeys: String, CodingKey {
        case mediaContainer = "MediaContainer"
    }
}

struct MediaItemContainer: Decodable {
    let metadata: [PlexMediaItem]
    
    enum CodingKeys: String, CodingKey {
        case metadata = "Metadata"
    }
}

struct PlexMediaItem: Decodable {
    let media: [MediaPartContainer]
    
    enum CodingKeys: String, CodingKey {
        case media = "Media"
    }
}

struct MediaPartContainer: Decodable {
    let parts: [MediaPart]
    
    enum CodingKeys: String, CodingKey {
        case parts = "Part"
    }
}

struct MediaPart: Decodable {
    let size: Int64
}
