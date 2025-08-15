import SwiftUI

@main
struct Review: App {
    @AppStorage("selectedLanguage") private var selectedLanguage: String = "system"

    var body: some Scene {
        WindowGroup {
            MainView()
                .environment(\.locale, locale)
                .id(selectedLanguage)
        }
    }

    private var locale: Locale {
            guard selectedLanguage != "system" else {
                return Locale.autoupdatingCurrent
            }

            return Locale(identifier: selectedLanguage)
        }
}
