import Foundation

class LanguageManager {
    static let shared = LanguageManager()
    
    let availableLanguages: [AppLanguage]
    
    private init() {
        var languages = Bundle.main.localizations
            .filter { $0 != "Base" }
            .map { langCode -> AppLanguage in
                let name = Locale(identifier: langCode)
                    .localizedString(forLanguageCode: langCode)?
                    .capitalized ?? langCode
                return AppLanguage(id: langCode, name: name)
            }
        
        languages.insert(AppLanguage(id: "system", name: "Système"), at: 0)
        
        self.availableLanguages = languages
    }
}
