import Foundation

struct PlexMediaDetailsResponse: Decodable {
    let mediaContainer: MediaDetailsContainer
    enum CodingKeys: String, CodingKey { case mediaContainer = "MediaContainer" }
}

struct MediaDetailsContainer: Decodable {
    let metadata: [MediaDetails]
    enum CodingKeys: String, CodingKey { case metadata = "Metadata" }
}

struct MediaDetails: Decodable {
    let media: [MediaPartContainer]
    let addedAt: Int
    let updatedAt: Int?
    enum CodingKeys: String, CodingKey {
        case media = "Media"
        case addedAt, updatedAt
    }
}

struct MediaPartContainer: Decodable {
    let duration: Int
    let bitrate: Int?
    let width: Int?
    let height: Int?
    let aspectRatio: Double?
    let videoProfile: String?
    let audioProfile: String?
    let audioCodec: String?
    let container: String?
    let videoFrameRate: String?
    let videoResolution: String?
    
    let parts: [MediaPart]
    enum CodingKeys: String, CodingKey {
        case duration, bitrate, width, height, aspectRatio, videoProfile, audioProfile, audioCodec, container, videoFrameRate, videoResolution
        case parts = "Part"
    }
}

struct MediaPart: Decodable {
    let file: String
    let streams: [StreamDetails]
    enum CodingKeys: String, CodingKey {
        case file
        case streams = "Stream"
    }
}

struct StreamDetails: Decodable {
    let streamType: Int // 1=Video, 2=Audio, 3=Subtitle
    let codec: String?
    let channels: Int?
}
