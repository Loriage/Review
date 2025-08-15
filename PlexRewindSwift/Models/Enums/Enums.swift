import Foundation
import SwiftUI

enum SortOption: String, CaseIterable, Identifiable {
    case byPlays
    case byDuration

    var id: String { self.rawValue }

    var localizedName: LocalizedStringKey {
        switch self {
        case .byPlays:
            return "sort.option.by.plays"
        case .byDuration:
            return "sort.option.by.duration"
        }
    }
}

enum ViewState {
    case loading
    case content([PlexActivitySession])
    case forbidden
    case noServerSelected
    case empty
}

enum PlexError: Error, LocalizedError {
    case invalidURL
    case networkError(Error)
    case decodingError(Error)
    case noData
    case serverError(statusCode: Int)

    var errorDescription: String? {
        switch self {
        case .invalidURL: return "\(String(localized: "error.invalidURL"))"
        case .networkError(let error):
            return "\(String(localized: "error.network ")) \(error.localizedDescription)"
        case .decodingError(let error):
            if let decodingError = error as? DecodingError {
                switch decodingError {
                case .typeMismatch, .valueNotFound, .keyNotFound, .dataCorrupted:
                    return "\(String(localized: "error.decoding")) \(error.localizedDescription)"
                @unknown default:
                    return "\(String(localized: "error.decoding")) \(error.localizedDescription)"
                }
            }
            return "\(String(localized: "error.decoding")) \(error.localizedDescription)"
        case .noData: return String(localized: "error.noData")
        case .serverError(let statusCode):
            return "\(String(localized: "error.server")) \(statusCode)"
        }
    }
}

struct MediaHistoryItem: Identifiable {
    let id: String
    let session: WatchSession
    let userName: String?
    let userThumbURL: URL?
}

enum LoadingState: Equatable {
    case idle
    case loading
    case loaded
    case error
}

class DisplayLibrary: Identifiable, ObservableObject {
    let id: String
    @Published var library: PlexLibrary
    
    @Published var size: Int64?
    @Published var fileCount: Int?
    @Published var episodesCount: Int?
    @Published var recentItemURLs: [URL] = []
    @Published var loadingState: LoadingState = .idle

    init(id: String, library: PlexLibrary) {
        self.id = id
        self.library = library
    }
}

extension Notification.Name {
    static let didUpdateLibraryPreferences = Notification.Name("didUpdateLibraryPreferences")
}
