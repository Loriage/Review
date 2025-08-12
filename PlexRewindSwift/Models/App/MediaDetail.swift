import Foundation

struct TopUserStat: Identifiable {
    let id: Int
    let userName: String
    let userThumbURL: URL?
    let playCount: Int
    let formattedDuration: String
}

struct MediaDetail: Identifiable {
    let id: String
    let serverIdentifier: String
    let mediaType: String
    let title: String
    let tagline: String?
    let posterURL: URL?
    let artURL: URL?
    let summary: String?
    let year: Int?
    let genres: [String]
    let topUsers: [TopUserStat]
}
