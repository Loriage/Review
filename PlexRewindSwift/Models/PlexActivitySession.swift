import Foundation

struct PlexActivityResponse: Decodable {
    let mediaContainer: ActivityMediaContainer

    enum CodingKeys: String, CodingKey {
        case mediaContainer = "MediaContainer"
    }
}

struct ActivityMediaContainer: Decodable {
    let size: Int
    let metadata: [PlexActivitySession]

    enum CodingKeys: String, CodingKey {
        case size, metadata = "Metadata"
    }
}

struct PlexActivitySession: Decodable, Identifiable {
    var id: String { sessionKey ?? ratingKey }

    let ratingKey: String
    let sessionKey: String?
    let title: String
    let type: String
    let duration: Int
    let viewOffset: Int
    
    let art: String?
    let contentRating: String?
    let grandparentTitle: String?
    let parentThumb: String?
    let grandparentThumb: String?
    let thumb: String?
    
    let parentIndex: Int?
    let index: Int?
    let year: Int?

    var posterURL: URL?
    var location: String?

    let media: [MediaStream]?
    let user: User
    let player: Player
    let session: Session
    let transcodeSession: TranscodeSession?

    var showTitle: String {
        return grandparentTitle ?? title
    }
    
    var progress: Double {
        return Double(viewOffset) / Double(duration)
    }

    var remainingTimeInSeconds: Int {
        return (duration - viewOffset) / 1000
    }

    struct MediaStream: Decodable {
        let bitrate: Int?
        let audioChannels: Int?
        let audioCodec: String?
        let container: String?
        let height: Int?
        let width: Int?
        let videoCodec: String?
        let videoFrameRate: String?
        let videoResolution: String?
        let videoProfile: String?
    }
    
    struct User: Decodable {
        let id: String
        let title: String
        let thumb: String?
    }
    
    struct Player: Decodable {
        let address: String
        let device: String?
        let machineIdentifier: String
        let model: String?
        let platform: String
        let platformVersion: String?
        let product: String
        let profile: String?
        let remotePublicAddress: String?
        let state: String
        let title: String?
        let version: String?
        let local: Bool
        let relayed: Bool
        let secure: Bool
        let userID: Int
    }
    
    struct Session: Decodable {
        let id: String
        let bandwidth: Int?
        let location: String
    }
    
    struct TranscodeSession: Decodable {
        let key: String
        let throttled: Bool
        let complete: Bool
        let progress: Double?
        let speed: Double?
        let error: Bool?
        let duration: Int
        let sourceVideoCodec: String?
        let sourceAudioCodec: String?
        let videoDecision: String
        let audioDecision: String
        let `protocol`: String?
        let container: String?
        let videoCodec: String?
        let audioCodec: String?
        let audioChannels: Int?
        let transcodeHwRequested: Bool
        let transcodeHwDecoding: String?
        let transcodeHwEncoding: String?
        let transcodeHwDecodingTitle: String?
        let transcodeHwEncodingTitle: String?
    }
    
    enum CodingKeys: String, CodingKey {
        case ratingKey, sessionKey, title, type, duration, viewOffset, art, contentRating, grandparentTitle, parentThumb, grandparentThumb, thumb, parentIndex, index, year, media = "Media", user = "User", player = "Player", session = "Session", transcodeSession = "TranscodeSession"
    }
}
