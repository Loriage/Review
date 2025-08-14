import Foundation

class PlexStatisticsService {
    
    private func performRequest<T: Decodable>(urlString: String, token: String) async throws -> T {
        guard var components = URLComponents(string: urlString) else {
            throw PlexError.invalidURL
        }
        
        components.queryItems = [
            URLQueryItem(name: "timespan", value: "6"),
            URLQueryItem(name: "X-Plex-Token", value: token)
        ]
        
        guard let url = components.url else { throw PlexError.invalidURL }
        
        var request = URLRequest(url: url)
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw PlexError.serverError(statusCode: (response as? HTTPURLResponse)?.statusCode ?? 0)
        }
        
        do {
            return try JSONDecoder().decode(T.self, from: data)
        } catch {
            throw PlexError.decodingError(error)
        }
    }

    func fetchResources(serverURL: String, token: String) async throws -> [StatisticsResource] {
        let urlString = "\(serverURL)/statistics/resources"
        let response: PlexStatisticsResponse = try await performRequest(urlString: urlString, token: token)
        return response.mediaContainer.statisticsResources
    }

    func fetchBandwidth(serverURL: String, token: String) async throws -> [StatisticsBandwidth] {
        let urlString = "\(serverURL)/statistics/bandwidth"
        let response: PlexBandwidthResponse = try await performRequest(urlString: urlString, token: token)
        return response.mediaContainer.statisticsBandwidth
    }
}
