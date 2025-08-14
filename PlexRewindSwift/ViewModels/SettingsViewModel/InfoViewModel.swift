import Foundation
import SwiftUI

@MainActor
class InfoViewModel: ObservableObject {
    @Published var localNetworkData: [(Date, Double)] = []
    @Published var remoteNetworkData: [(Date, Double)] = []
    @Published var plexCpuData: [(Date, Double)] = []
    @Published var systemCpuData: [(Date, Double)] = []
    @Published var plexRamData: [(Date, Double)] = []
    @Published var systemRamData: [(Date, Double)] = []
    @Published var networkUnit: String = "Kb/s"
    @Published var isLoading = true
    
    private let statisticsService = PlexStatisticsService()
    private var timer: Timer?

    func startFetchingData(serverViewModel: ServerViewModel, authManager: PlexAuthManager) {
        stopFetchingData()
        isLoading = true
        
        Task {
            await fetchData(serverViewModel: serverViewModel, authManager: authManager)
        }

        timer = Timer.scheduledTimer(withTimeInterval: 5.0, repeats: true) { [weak self] _ in
            Task {
                await self?.fetchData(serverViewModel: serverViewModel, authManager: authManager)
            }
        }
    }

    func stopFetchingData() {
        timer?.invalidate()
        timer = nil
    }

    private func getServerDetails(serverViewModel: ServerViewModel, authManager: PlexAuthManager) -> (url: String, token: String)? {
        guard let serverID = serverViewModel.selectedServerID,
              let server = serverViewModel.availableServers.first(where: { $0.id == serverID }),
              let connection = server.connections.first(where: { !$0.local }) ?? server.connections.first,
              let token = authManager.getPlexAuthToken()
        else { return nil }
        let resourceToken = server.accessToken ?? token
        return (url: connection.uri, token: resourceToken)
    }

    func fetchData(serverViewModel: ServerViewModel, authManager: PlexAuthManager) async {
        guard let serverDetails = getServerDetails(serverViewModel: serverViewModel, authManager: authManager) else {
            isLoading = false
            return
        }
        
        do {
            async let resourcesTask = statisticsService.fetchResources(serverURL: serverDetails.url, token: serverDetails.token)
            async let bandwidthTask = statisticsService.fetchBandwidth(serverURL: serverDetails.url, token: serverDetails.token)
            
            let (resources, bandwidth) = await (try resourcesTask, try bandwidthTask)
            
            plexCpuData = resources.map { (Date(timeIntervalSince1970: TimeInterval($0.at)), $0.processCpuUtilization) }
            systemCpuData = resources.map { (Date(timeIntervalSince1970: TimeInterval($0.at)), $0.hostCpuUtilization) }
            plexRamData = resources.map { (Date(timeIntervalSince1970: TimeInterval($0.at)), $0.processMemoryUtilization) }
            systemRamData = resources.map { (Date(timeIntervalSince1970: TimeInterval($0.at)), $0.hostMemoryUtilization) }

            let allTimestamps = Set(bandwidth.map { $0.at }).sorted()

            var localBytesByTime: [Int: Double] = [:]
            var remoteBytesByTime: [Int: Double] = [:]

            for item in bandwidth {
                if item.lan {
                    localBytesByTime[item.at, default: 0.0] += Double(item.bytes)
                } else {
                    remoteBytesByTime[item.at, default: 0.0] += Double(item.bytes)
                }
            }

            localNetworkData = allTimestamps.map { at in
                let date = Date(timeIntervalSince1970: TimeInterval(at))
                let bytes = localBytesByTime[at] ?? 0.0
                return (date, bytes)
            }

            remoteNetworkData = allTimestamps.map { at in
                let date = Date(timeIntervalSince1970: TimeInterval(at))
                let bytes = remoteBytesByTime[at] ?? 0.0
                return (date, bytes)
            }

            let allBandwidthBytes = (localNetworkData + remoteNetworkData).map { $0.1 }
            if let maxBytes = allBandwidthBytes.max(), (maxBytes * 8) / 1_000_000.0 >= 1 {
                networkUnit = "Mb/s"
            } else {
                networkUnit = "Kb/s"
            }

        } catch {
            print("Erreur de récupération des statistiques: \(error.localizedDescription)")
        }
        
        isLoading = false
    }
}
