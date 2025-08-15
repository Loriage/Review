import Foundation

struct PlexPreferences: Decodable {
    let settings: [PlexSetting]
    
    enum CodingKeys: String, CodingKey {
        case settings = "Setting"
    }
}

struct PlexSetting: Decodable {
    let id: String
    let label: String
    let summary: String
    let type: String
    let value: String
    let enumValues: String?
}

struct PlexServerSetting: Decodable, Identifiable {
    let id: String
    let label: String
    let summary: String?
    let type: String
    let `default`: String?
    let value: String?
    let hidden: Bool?
    let advanced: Bool?
    let group: String?
    let enumValues: String?

    enum CodingKeys: String, CodingKey {
        case id, label, summary, type, `default`, value, hidden, advanced, group, enumValues
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        label = try container.decode(String.self, forKey: .label)
        summary = try container.decodeIfPresent(String.self, forKey: .summary)
        type = try container.decode(String.self, forKey: .type)

        if let stringValue = try? container.decodeIfPresent(String.self, forKey: .default) {
            self.default = stringValue
        } else if let boolValue = try? container.decodeIfPresent(Bool.self, forKey: .default) {
            self.default = String(boolValue)
        } else {
            self.default = nil
        }
        
        if let stringValue = try? container.decodeIfPresent(String.self, forKey: .value) {
            self.value = stringValue
        } else if let boolValue = try? container.decodeIfPresent(Bool.self, forKey: .value) {
            self.value = String(boolValue)
        } else if let intValue = try? container.decodeIfPresent(Int.self, forKey: .value) {
            self.value = String(intValue)
        }
        else {
            self.value = nil
        }

        hidden = try container.decodeIfPresent(Bool.self, forKey: .hidden)
        advanced = try container.decodeIfPresent(Bool.self, forKey: .advanced)
        group = try container.decodeIfPresent(String.self, forKey: .group)
        enumValues = try container.decodeIfPresent(String.self, forKey: .enumValues)
    }
}

struct EnumValue: Identifiable, Hashable {
    let id: String
    let name: String
}
