import Foundation
import Security

class KeychainHelper {
    
    static let standard = KeychainHelper()
    private let service = "com.nohitdev.PlexRewindSwift.authtoken"

    private init() {}

    func save(_ data: Data, for account: String) throws {
        let query = [
            kSecClass: kSecClassGenericPassword,
            kSecAttrService: service,
            kSecAttrAccount: account,
            kSecValueData: data
        ] as [String: Any]

        SecItemDelete(query as CFDictionary)

        let status = SecItemAdd(query as CFDictionary, nil)
        guard status == errSecSuccess else {
            throw KeychainError.saveError(status)
        }
    }

    func read(for account: String) throws -> Data? {
        let query = [
            kSecClass: kSecClassGenericPassword,
            kSecAttrService: service,
            kSecAttrAccount: account,
            kSecMatchLimit: kSecMatchLimitOne,
            kSecReturnData: true
        ] as [String: Any]

        var dataTypeRef: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &dataTypeRef)

        if status == errSecSuccess {
            return dataTypeRef as? Data
        } else if status == errSecItemNotFound {
            return nil
        } else {
            throw KeychainError.readError(status)
        }
    }

    func delete(for account: String) throws {
        let query = [
            kSecClass: kSecClassGenericPassword,
            kSecAttrService: service,
            kSecAttrAccount: account
        ] as [String: Any]

        let status = SecItemDelete(query as CFDictionary)
        guard status == errSecSuccess || status == errSecItemNotFound else {
            throw KeychainError.deleteError(status)
        }
    }

    func saveString(_ string: String, for account: String) throws {
        guard let data = string.data(using: .utf8) else { return }
        try save(data, for: account)
    }

    func readString(for account: String) throws -> String? {
        guard let data = try read(for: account) else { return nil }
        return String(data: data, encoding: .utf8)
    }
}

enum KeychainError: Error, LocalizedError {
    case saveError(OSStatus)
    case readError(OSStatus)
    case deleteError(OSStatus)
    
    var errorDescription: String? {
        switch self {
        case .saveError(let status): return "Erreur de sauvegarde dans le trousseau: \(status)"
        case .readError(let status): return "Erreur de lecture dans le trousseau: \(status)"
        case .deleteError(let status): return "Erreur de suppression dans le trousseau: \(status)"
        }
    }
}
