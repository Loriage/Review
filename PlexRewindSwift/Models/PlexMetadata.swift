//
//  PlexMetadataResponse.swift
//  PlexRewindSwift
//
//  Created by Bruno DURAND on 04/08/2025.
//


import Foundation

// Représente la réponse pour les métadonnées d'un seul item
struct PlexMetadataResponse: Decodable {
    let mediaContainer: MetadataMediaContainer
    
    enum CodingKeys: String, CodingKey {
        case mediaContainer = "MediaContainer"
    }
}

struct MetadataMediaContainer: Decodable {
    let metadata: [MetadataItem]
    
    enum CodingKeys: String, CodingKey {
        case metadata = "Metadata"
    }
}

struct MetadataItem: Decodable {
    // La durée en millisecondes
    let duration: Int
}