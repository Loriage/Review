import Foundation

extension PlexAPIService {
    func fetchCurrentActivity(serverURL: String, token: String) async throws -> [PlexActivitySession] {
        guard let url = URL(string: "\(serverURL)/status/sessions?X-Plex-Token=\(token)") else {
            throw PlexError.invalidURL
        }

        var request = URLRequest(url: url)
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue(APIConstants.clientIdentifier, forHTTPHeaderField: "X-Plex-Client-Identifier")

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw PlexError.serverError(statusCode: (response as? HTTPURLResponse)?.statusCode ?? 0)
        }

        do {
            let decodedResponse = try JSONDecoder().decode(PlexActivityResponse.self, from: data)
            return decodedResponse.mediaContainer.metadata
        } catch {
            throw PlexError.decodingError(error)
        }
    }
}
