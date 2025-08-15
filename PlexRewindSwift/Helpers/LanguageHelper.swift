import Foundation

struct LanguageHelper {
    static func getCurrentLanguageCode() -> String {
        let selectedLanguage = UserDefaults.standard.string(forKey: "selectedLanguage") ?? "system"
        if selectedLanguage == "system" {
            return Locale.autoupdatingCurrent.language.languageCode?.identifier ?? "en"
        }
        return selectedLanguage
    }
}
