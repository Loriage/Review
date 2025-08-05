import Foundation
import Combine

@MainActor
class PlexAuthManager: ObservableObject {
    @Published var pin: PlexPin?
    @Published var isAuthenticated: Bool = false
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?

    private let keychain = KeychainHelper.standard
    private let clientIdentifier = APIConstants.clientIdentifier
    private var pollTimer: Timer?
    private let tokenAccount = "plexAuthToken"

    init() {
        if let token = try? keychain.readString(for: tokenAccount), !token.isEmpty {
            self.isAuthenticated = true
        }
    }
    
    func getPlexAuthToken() -> String? {
        return try? keychain.readString(for: tokenAccount)
    }
    
    func startLoginProcess() async {
        isLoading = true
        errorMessage = nil
        
        do {
            let requestedPin = try await requestPin()
            self.pin = requestedPin

            await pollForToken(pinId: requestedPin.id)
        } catch {
            errorMessage = "Impossible d'obtenir un code PIN de Plex. \(error.localizedDescription)"
            isLoading = false
        }
    }

    private func pollForToken(pinId: Int) async {
        while !isAuthenticated {
            guard self.pin != nil else {
                print("Polling annulé car le PIN a été effacé.")
                return
            }
            
            do {
                if let token = try await checkPinForToken(id: pinId) {
                    handleSuccessfulLogin(with: token)
                } else {
                    try await Task.sleep(for: .seconds(2))
                }
            } catch {
                handlePollingError(error)
                break
            }
        }

        isLoading = false
    }
    
    func logout() {
        Task {
            try? keychain.delete(for: tokenAccount)
            self.isAuthenticated = false
            self.pin = nil
        }
    }
    
    private func requestPin() async throws -> PlexPin {
        guard let url = URL(string: "https://plex.tv/api/v2/pins") else {
            throw PlexError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")

        var components = URLComponents()
        components.queryItems = [
            URLQueryItem(name: "X-Plex-Client-Identifier", value: clientIdentifier),
            URLQueryItem(name: "X-Plex-Product", value: APIConstants.productName),
        ]

        request.httpBody = components.query?.data(using: .utf8)

        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 201 else {
            throw PlexError.serverError(statusCode: (response as? HTTPURLResponse)?.statusCode ?? 0)
        }
        
        do {
            return try JSONDecoder().decode(PlexPin.self, from: data)
        } catch {
            throw PlexError.decodingError(error)
        }
    }
    
    private func checkPinForToken(id: Int) async throws -> String? {
        guard let url = URL(string: "https://plex.tv/api/v2/pins/\(id)") else {
            throw PlexError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.setValue(clientIdentifier, forHTTPHeaderField: "X-Plex-Client-Identifier")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            return nil
        }
        
        let pinStatus = try JSONDecoder().decode(PlexPin.self, from: data)
        return pinStatus.authToken
    }

    private func handleSuccessfulLogin(with token: String) {
        do {
            try keychain.saveString(token, for: tokenAccount)
            isAuthenticated = true

            self.pin = nil
        } catch {
            errorMessage = "Erreur lors de la sauvegarde du token."
        }
    }
    
    private func handlePollingError(_ error: Error) {
        errorMessage = "Une erreur est survenue durant la vérification du PIN."
        self.pin = nil
    }
}
