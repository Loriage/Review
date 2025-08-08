import Foundation

// --- MODÈLES DE DONNÉES MUTUALISÉS ---
// Ce fichier est maintenant la seule source de vérité pour la structure des médias.

struct PlexMediaDetailsResponse: Decodable {
    let mediaContainer: MediaDetailsContainer
    enum CodingKeys: String, CodingKey { case mediaContainer = "MediaContainer" }
}

struct MediaDetailsContainer: Decodable {
    let metadata: [MediaDetails]
    enum CodingKeys: String, CodingKey { case metadata = "Metadata" }
}

struct MediaDetails: Decodable {
    // Utilise le modèle mutualisé PlexMediaPartContainer
    let media: [PlexMediaPartContainer]
    let addedAt: Int? // Rendu optionnel pour plus de flexibilité
    let updatedAt: Int?
    enum CodingKeys: String, CodingKey {
        case media = "Media"
        case addedAt, updatedAt
    }
}

// Ce modèle est maintenant assez flexible pour gérer les réponses de /details ET de /all.
struct PlexMediaPartContainer: Decodable {
    let duration: Int?
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
    
    // Utilise le modèle PlexMediaPart, qui est aussi rendu plus flexible.
    let parts: [PlexMediaPart]
    enum CodingKeys: String, CodingKey {
        case duration, bitrate, width, height, aspectRatio, videoProfile, audioProfile, audioCodec, container, videoFrameRate, videoResolution
        case parts = "Part"
    }
}

// C'est le modèle le plus important. Il peut maintenant décoder une "part" avec ou sans les détails des flux.
struct PlexMediaPart: Decodable {
    let file: String?         // Optionnel, car pas toujours présent.
    let size: Int64           // Obligatoire, c'est ce dont nous avons besoin pour le calcul.
    let streams: [StreamDetails]? // Optionnel, car absent de la réponse /all.
    
    enum CodingKeys: String, CodingKey {
        case file, size
        case streams = "Stream"
    }
}

// Cette structure ne change pas.
struct StreamDetails: Decodable {
    let streamType: Int
    let codec: String?
    let channels: Int?
}
