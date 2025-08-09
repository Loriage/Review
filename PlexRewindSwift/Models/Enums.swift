import Foundation

enum SortOption: String, CaseIterable, Identifiable {
    case byPlays = "Lectures"
    case byDuration = "Durée"

    var id: String { self.rawValue }
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
        case .invalidURL: return "L'URL du serveur est invalide."
        case .networkError(let error):
            return "Erreur réseau: \(error.localizedDescription)"
        case .decodingError(let error):
            if let decodingError = error as? DecodingError {
                switch decodingError {
                case .typeMismatch(let type, let context):
                    return "Erreur de décodage: Le type ne correspond pas pour \(type) à \(context.codingPath.map { $0.stringValue }.joined(separator: ".")). Raison: \(context.debugDescription)"
                case .valueNotFound(let type, let context):
                    return "Erreur de décodage: Valeur manquante pour \(type) à \(context.codingPath.map { $0.stringValue }.joined(separator: ".")). Raison: \(context.debugDescription)"
                case .keyNotFound(let key, let context):
                    return "Erreur de décodage: Clé '\(key.stringValue)' non trouvée à \(context.codingPath.map { $0.stringValue }.joined(separator: ".")). Raison: \(context.debugDescription)"
                case .dataCorrupted(let context):
                    return "Erreur de décodage: Données corrompues. Raison: \(context.debugDescription)"
                @unknown default:
                    return "Erreur de décodage inconnue: \(error.localizedDescription)"
                }
            }
            return "Erreur de décodage: \(error.localizedDescription)"
        case .noData: return "Aucune donnée reçue du serveur."
        case .serverError(let statusCode):
            return "Erreur du serveur (code: \(statusCode))."
        }
    }
}

struct MediaHistoryItem: Identifiable {
    let id: String
    let session: WatchSession
    let userName: String?
}

struct DisplayLibrary: Identifiable {
    let id: String
    let library: PlexLibrary
    var size: Int64?
    var fileCount: Int?
    var recentItemURLs: [URL] = []
}
