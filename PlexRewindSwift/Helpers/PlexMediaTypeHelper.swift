import Foundation

struct PlexMediaTypeHelper {

    static func formattedTypeNameSingular(for type: String) -> String {
        switch type {
        case "movie":
            return "film"
        case "show":
            return "série"
        case "artist":
            return "artiste"
        case "album":
            return "album"
        case "track":
            return "musique"
        case "photo":
            return "photo"
        case "episode":
            return "épisode"
        default:
            return "élément"
        }
    }

    static func formattedTypeNamePlural(for type: String) -> String {
        switch type {
        case "movie":
            return "films"
        case "show":
            return "séries"
        case "artist":
            return "artistes"
        case "album":
            return "albums"
        case "track":
            return "musiques"
        case "photo":
            return "photos"
        case "episode":
            return "épisodes"
        default:
            return "éléments"
        }
    }

    static func iconName(for type: String) -> String {
        switch type {
        case "movie":
            return "film.stack.fill"
        case "show", "episode":
            return "tv.and.hifispeaker.fill"
        case "artist":
            return "music.mic"
        case "album":
            return "square.stack.fill"
        case "track":
            return "music.note"
        case "photo":
            return "photo.on.rectangle.angled"
        default:
            return "questionmark.diamond.fill"
        }
    }
}
