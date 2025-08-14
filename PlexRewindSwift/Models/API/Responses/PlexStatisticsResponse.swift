import Foundation

struct PlexStatisticsResponse: Decodable {
    let mediaContainer: StatisticsMediaContainer
    enum CodingKeys: String, CodingKey { case mediaContainer = "MediaContainer" }
}

struct StatisticsMediaContainer: Decodable {
    let size: Int
    let statisticsResources: [StatisticsResource]
    enum CodingKeys: String, CodingKey { case size, statisticsResources = "StatisticsResources" }
}

struct StatisticsResource: Decodable {
    let timespan: Int
    let at: Int
    let hostCpuUtilization: Double
    let processCpuUtilization: Double
    let hostMemoryUtilization: Double
    let processMemoryUtilization: Double
}

struct PlexBandwidthResponse: Decodable {
    let mediaContainer: BandwidthMediaContainer
    enum CodingKeys: String, CodingKey { case mediaContainer = "MediaContainer" }
}

struct BandwidthMediaContainer: Decodable {
    let size: Int
    let statisticsBandwidth: [StatisticsBandwidth]
    enum CodingKeys: String, CodingKey { case size, statisticsBandwidth = "StatisticsBandwidth" }
}

struct StatisticsBandwidth: Decodable {
    let accountID: Int
    let deviceID: Int
    let timespan: Int
    let at: Int
    let lan: Bool
    let bytes: Int
}
