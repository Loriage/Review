import Foundation
import SwiftUI

enum TimeOfDay: String, CaseIterable, Identifiable {
    case morning, afternoon, evening, night
    var id: String { self.rawValue }

    var displayName: LocalizedStringKey {
        switch self {
        case .morning: "time.of.day.morning"
        case .afternoon: "time.of.day.afternoon"
        case .evening: "time.of.day.evening"
        case .night: "time.of.day.night"
        }
    }
}

enum TypeNamePlural: String, CaseIterable, Identifiable {
    case movie, show, artist, album, photo, track, episode
    var id: String { self.rawValue }

    var displayName: LocalizedStringKey {
        switch self {
        case .movie: "media.type.plural.movie"
        case .show: "media.type.plural.show"
        case .artist: "media.type.plural.artist"
        case .album: "media.type.plural.album"
        case .photo: "media.type.plural.photo"
        case .track: "media.type.plural.track"
        case .episode: "media.type.plural.episode"
        }
    }
}
