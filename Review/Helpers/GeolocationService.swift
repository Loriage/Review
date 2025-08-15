import Foundation

struct LocationInfo: Decodable {
    let city: String?
    let country: String?
}

class GeolocationService {
    func fetchLocation(for ipAddress: String) async -> String? {
        guard let url = URL(string: "http://ip-api.com/json/\(ipAddress)?fields=city,country") else {
            return nil
        }

        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            let locationInfo = try JSONDecoder().decode(LocationInfo.self, from: data)
            
            if let city = locationInfo.city, let country = locationInfo.country {
                return "\(city), \(country)"
            }
        } catch {
            print("Erreur de géolocalisation pour l'IP \(ipAddress): \(error)")
        }
        
        return nil
    }
}
