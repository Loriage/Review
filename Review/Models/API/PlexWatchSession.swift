import Foundation

struct WatchSession: Decodable, Identifiable {
    var id: String { historyKey ?? UUID().uuidString }

    let title: String?
    let type: String?
    let viewedAt: TimeInterval?
    var duration: Int?
    let ratingKey: String?
    let parentTitle: String?
    let grandparentTitle: String?
    let grandparentRatingKey: String?
    let grandparentKey: String?
    let historyKey: String?
    let accountID: Int?

    let thumb: String?
    let grandparentThumb: String?

    let index: Int?
    let parentIndex: Int?

    var computedGrandparentRatingKey: String? {
        if let gprk = self.grandparentRatingKey, !gprk.isEmpty { return gprk }
        if let gpk = self.grandparentKey { return gpk.components(separatedBy: "/").last }
        return nil
    }

    var showTitle: String {
        return grandparentTitle ?? parentTitle ?? "N/A"
    }

    enum CodingKeys: String, CodingKey {
        case title, type, viewedAt, duration, ratingKey, parentTitle,
            grandparentTitle, grandparentRatingKey, historyKey, grandparentKey, thumb,
            grandparentThumb, index, parentIndex
        case accountID = "accountID"
    }
}
