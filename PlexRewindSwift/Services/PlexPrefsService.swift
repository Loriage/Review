import Foundation

class PlexPrefsService {
    func fetchPrefs(serverURL: String, token: String) async throws -> [PlexServerSetting] {
        guard let url = URL(string: "\(serverURL)/:/prefs?X-Plex-Token=\(token)") else {
            throw PlexError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw PlexError.serverError(statusCode: (response as? HTTPURLResponse)?.statusCode ?? 0)
        }
        
        do {
            let decodedResponse = try JSONDecoder().decode(PlexPrefsResponse.self, from: data)
            return decodedResponse.mediaContainer.setting
        } catch {
            throw PlexError.decodingError(error)
        }
    }
    
    func updatePref(serverURL: String, token: String, key: String, value: String) async throws {
        guard var components = URLComponents(string: "\(serverURL)/:/prefs") else {
            throw PlexError.invalidURL
        }
        
        components.queryItems = [
            URLQueryItem(name: key, value: value),
            URLQueryItem(name: "X-Plex-Token", value: token)
        ]
        
        guard let url = components.url else { throw PlexError.invalidURL }
        
        var request = URLRequest(url: url)
        request.httpMethod = "PUT"
        
        let (_, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw PlexError.serverError(statusCode: (response as? HTTPURLResponse)?.statusCode ?? 0)
        }
    }
}
