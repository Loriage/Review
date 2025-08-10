import Foundation

@MainActor
class LibrarySettingsViewModel: ObservableObject {
    let libraryID: String

    init(libraryID: String) {
        self.libraryID = libraryID
    }
}
