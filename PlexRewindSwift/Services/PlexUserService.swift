import Foundation

class PlexUserParser: NSObject, XMLParserDelegate {
    private var users: [PlexUser] = []
    private var currentUserID: Int?
    private var currentUserTitle: String?
    private var currentUserThumb: String?

    func parse(data: Data) -> [PlexUser] {
        let parser = XMLParser(data: data)
        parser.delegate = self
        parser.parse()
        return users
    }
    
    func parser(_ parser: XMLParser, didStartElement elementName: String, namespaceURI: String?, qualifiedName qName: String?, attributes attributeDict: [String : String] = [:]) {
        if elementName == "User" {
            currentUserID = nil
            currentUserTitle = nil
            currentUserThumb = nil
            
            if let idString = attributeDict["id"], let id = Int(idString) {
                self.currentUserID = id
            }
            self.currentUserTitle = attributeDict["title"]
            self.currentUserThumb = attributeDict["thumb"]

            if let id = currentUserID, let title = currentUserTitle {
                let user = PlexUser(
                    id: id,
                    title: title,
                    thumb: currentUserThumb,
                )
                self.users.append(user)
            }
        }
    }
}


class PlexUserService {

    func fetchAccount(token: String) async throws -> PlexAccount {
        guard let url = URL(string: "https://plex.tv/api/v2/user") else {
            throw PlexError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue(APIConstants.clientIdentifier, forHTTPHeaderField: "X-Plex-Client-Identifier")
        request.setValue(token, forHTTPHeaderField: "X-Plex-Token")
        
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw PlexError.serverError(statusCode: (response as? HTTPURLResponse)?.statusCode ?? 0)
        }
        
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        return try decoder.decode(PlexAccount.self, from: data)
    }

    func fetchUsers(serverURL: String, token: String) async throws -> [PlexUser] {
        guard let url = URL(string: "\(serverURL)/accounts?X-Plex-Token=\(token)") else {
            throw PlexError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue(APIConstants.clientIdentifier, forHTTPHeaderField: "X-Plex-Client-Identifier")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200
        else {
            throw PlexError.serverError(statusCode: (response as? HTTPURLResponse)?.statusCode ?? 0)
        }
        
        do {
            let userResponse = try JSONDecoder().decode(PlexUserResponse.self, from: data)
            return userResponse.mediaContainer.users
        } catch {
            throw PlexError.decodingError(error)
        }
    }

    func fetchHomeUsers(token: String) async throws -> [PlexUser] {
        guard let url = URL(string: "https://clients.plex.tv/api/home/users?X-Plex-Token=\(token)") else {
            throw PlexError.invalidURL
        }

        var request = URLRequest(url: url)
        request.setValue("application/xml", forHTTPHeaderField: "Accept")
        request.setValue(APIConstants.clientIdentifier, forHTTPHeaderField: "X-Plex-Client-Identifier")

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw PlexError.serverError(statusCode: (response as? HTTPURLResponse)?.statusCode ?? 0)
        }

        let parser = PlexUserParser()
        let parsedUsers = parser.parse(data: data)

        return parsedUsers
    }
}
