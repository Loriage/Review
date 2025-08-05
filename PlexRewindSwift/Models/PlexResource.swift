//
//  PlexResource.swift
//  PlexRewindSwift
//
//  Created by Bruno DURAND on 04/08/2025.
//


import Foundation

// Représente une ressource Plex (un serveur, un lecteur, etc.)
struct PlexResource: Codable, Identifiable {
    let name: String
    let product: String
    let productVersion: String
    let clientIdentifier: String
    let createdAt: String
    let lastSeenAt: String
    let provides: String // "server" pour les serveurs
    let ownerId: Int?
    let sourceTitle: String?
    let accessToken: String? // Un token spécifique à cette ressource
    let publicAddress: String
    let connections: [PlexConnection]
    
    // On se conforme à Identifiable en utilisant le clientIdentifier qui est unique
    var id: String { clientIdentifier }
    
    // On ne garde que les serveurs et on s'assure qu'ils sont joignables
    var isServer: Bool {
        provides == "server" && !connections.isEmpty
    }
}

// Représente une connexion possible à une ressource
struct PlexConnection: Codable, Hashable {
    let uri: String // L'URL complète pour se connecter
    let address: String
    let port: Int
    let `protocol`: String
    let local: Bool
}