import Foundation

struct PlexMediaTypeHelper {

    static func formattedTypeNameSingular(for type: String) -> String {
        switch type {
        case "movie":
            return String(localized: "media.type.singular.movie")
        case "show":
            return String(localized: "media.type.singular.show")
        case "artist":
            return String(localized: "media.type.singular.artist")
        case "album":
            return String(localized: "media.type.singular.album")
        case "track":
            return String(localized: "media.type.singular.track")
        case "photo":
            return String(localized: "media.type.singular.photo")
        case "episode":
            return String(localized: "media.type.singular.episode")
        default:
            return String(localized: "media.type.singular.default")
        }
    }

    static func formattedTypeNamePlural(for type: String) -> String {
        switch type {
        case "movie":
            return String(localized: "media.type.plural.movie")
        case "show":
            return String(localized: "media.type.plural.show")
        case "artist":
            return String(localized: "media.type.plural.artist")
        case "album":
            return String(localized: "media.type.plural.album")
        case "track":
            return String(localized: "media.type.plural.track")
        case "photo":
            return String(localized: "media.type.plural.photo")
        case "episode":
            return String(localized: "media.type.plural.episode")
        default:
            return String(localized: "media.type.plural.default")
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
