import SwiftUI
import Charts

struct InfoView: View {
    @StateObject private var viewModel = InfoViewModel()
    @EnvironmentObject var serverViewModel: ServerViewModel
    @EnvironmentObject var authManager: PlexAuthManager

    var body: some View {
        NavigationStack {
            if viewModel.isLoading {
                VStack {
                    ProgressView("Chargement des données...")
                }
                .navigationTitle("Informations Système")
                .navigationBarTitleDisplayMode(.inline)
            } else {
                ScrollView {
                    VStack(spacing: 20) {
                        NetworkChartView(
                            title: "Débit réseau",
                            localData: viewModel.localNetworkData,
                            remoteData: viewModel.remoteNetworkData,
                            unit: viewModel.networkUnit
                        )
                        
                        CpuChartView(
                            title: "Utilisation CPU",
                            plexData: viewModel.plexCpuData,
                            systemData: viewModel.systemCpuData,
                            unit: "%"
                        )

                        RamChartView(
                            title: "Utilisation RAM",
                            plexData: viewModel.plexRamData,
                            systemData: viewModel.systemRamData,
                            unit: "%"
                        )
                    }
                    .padding()
                }
                .navigationTitle("Informations Système")
                .navigationBarTitleDisplayMode(.inline)
            }
        }
        .onAppear {
            viewModel.startFetchingData(serverViewModel: serverViewModel, authManager: authManager)
        }
        .onDisappear {
            viewModel.stopFetchingData()
        }
    }
}

struct RamChartView: View {
    let title: String
    let plexData: [(Date, Double)]
    let systemData: [(Date, Double)]
    let unit: String

    private var latestDate: Date {
        let maxPlex = plexData.max(by: { $0.0 < $1.0 })?.0
        let maxSystem = systemData.max(by: { $0.0 < $1.0 })?.0
        
        if let maxPlex = maxPlex, let maxSystem = maxSystem {
            return max(maxPlex, maxSystem)
        }
        return maxPlex ?? maxSystem ?? Date()
    }

    var body: some View {
        VStack(alignment: .leading) {
            Text(title)
                .font(.headline.bold())
                .padding(.bottom, 5)

            Chart {
                ForEach(plexData, id: \.0) { date, value in
                    LineMark(x: .value("Date", date), y: .value("Plex", value))
                        .foregroundStyle(by: .value("Usage", "Plex Media Server"))
                        .interpolationMethod(.monotone)
                }
                
                ForEach(systemData, id: \.0) { date, value in
                    LineMark(x: .value("Date", date), y: .value("Système", value))
                        .foregroundStyle(by: .value("Usage", "Système"))
                        .interpolationMethod(.monotone)
                }
            }
            .chartForegroundStyleScale([
                "Plex Media Server": Color.cyan,
                "Système": Color.pink
            ])
            .chartYAxis {
                AxisMarks(position: .leading) { value in
                    AxisGridLine()
                    AxisValueLabel {
                        if let doubleValue = value.as(Double.self) {
                            Text("\(doubleValue, specifier: "%.0f")\(unit)")
                        }
                    }
                }
            }
            .chartXAxis {
                AxisMarks(values: .automatic(desiredCount: 4)) { value in
                    AxisGridLine()
                    if let date = value.as(Date.self) {
                        AxisValueLabel(formatted(date: date, relativeTo: latestDate))
                    }
                }
            }
            .chartLegend(position: .top, alignment: .trailing)
            .frame(height: 200)
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(16)
    }

    private func formatted(date: Date, relativeTo latestDate: Date) -> String {
        let difference = latestDate.timeIntervalSince(date)
        
        if difference <= 1 {
            return "Maintenant"
        }
        
        let formatter = DateComponentsFormatter()
        formatter.unitsStyle = .abbreviated
        formatter.allowedUnits = [.minute, .second]
        formatter.maximumUnitCount = 1
        
        return formatter.string(from: difference) ?? ""
    }
}

struct NetworkChartView: View {
    let title: String
    let localData: [(Date, Double)]
    let remoteData: [(Date, Double)]
    let unit: String

    private var latestDate: Date {
        let maxLocal = localData.max(by: { $0.0 < $1.0 })?.0
        let maxRemote = remoteData.max(by: { $0.0 < $1.0 })?.0
        
        if let maxLocal = maxLocal, let maxRemote = maxRemote {
            return max(maxLocal, maxRemote)
        }
        return maxLocal ?? maxRemote ?? Date()
    }

    private func scaleValue(_ bytes: Double) -> Double {
        let bits = bytes * 8
        if unit == "Mb/s" {
            return bits / 1_000_000.0
        }
        return bits / 1_000.0
    }

    var body: some View {
        VStack(alignment: .leading) {
            Text(title)
                .font(.headline.bold())
                .padding(.bottom, 5)

            Chart {
                ForEach(localData, id: \.0) { date, value in
                    LineMark(x: .value("Date", date), y: .value("Local", scaleValue(value)))
                        .foregroundStyle(by: .value("Type", "Local"))
                        .interpolationMethod(.monotone)
                }
                
                ForEach(remoteData, id: \.0) { date, value in
                    LineMark(x: .value("Date", date), y: .value("Distant", scaleValue(value)))
                        .foregroundStyle(by: .value("Type", "Distant"))
                        .interpolationMethod(.monotone)
                }
            }
            .chartForegroundStyleScale([
                "Local": Color.yellow,
                "Distant": Color.blue
            ])
            .chartYAxis {
                AxisMarks(position: .leading) { value in
                    AxisGridLine()
                    AxisValueLabel {
                        if let doubleValue = value.as(Double.self) {
                            Text("\(doubleValue, specifier: unit == "Mb/s" ? "%.1f" : "%.0f") \(unit)")
                        }
                    }
                }
            }
            .chartXAxis {
                AxisMarks(values: .automatic(desiredCount: 4)) { value in
                    AxisGridLine()
                    if let date = value.as(Date.self) {
                        AxisValueLabel(formatted(date: date, relativeTo: latestDate))
                    }
                }
            }
            .chartLegend(position: .top, alignment: .trailing)
            .frame(height: 200)
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(16)
    }

    private func formatted(date: Date, relativeTo latestDate: Date) -> String {
        let difference = latestDate.timeIntervalSince(date)
        
        if difference <= 1 {
            return "Maintenant"
        }
        
        let formatter = DateComponentsFormatter()
        formatter.unitsStyle = .abbreviated
        formatter.allowedUnits = [.minute, .second]
        formatter.maximumUnitCount = 1
        
        return formatter.string(from: difference) ?? ""
    }
}

struct CpuChartView: View {
    let title: String
    let plexData: [(Date, Double)]
    let systemData: [(Date, Double)]
    let unit: String

    private var latestDate: Date {
        let maxPlex = plexData.max(by: { $0.0 < $1.0 })?.0
        let maxSystem = systemData.max(by: { $0.0 < $1.0 })?.0
        
        if let maxPlex = maxPlex, let maxSystem = maxSystem {
            return max(maxPlex, maxSystem)
        }
        return maxPlex ?? maxSystem ?? Date()
    }

    var body: some View {
        VStack(alignment: .leading) {
            Text(title)
                .font(.headline.bold())
                .padding(.bottom, 5)

            Chart {
                ForEach(plexData, id: \.0) { date, value in
                    LineMark(x: .value("Date", date), y: .value("Plex", value))
                        .foregroundStyle(by: .value("Usage", "Plex Media Server"))
                        .interpolationMethod(.monotone)
                }
                
                ForEach(systemData, id: \.0) { date, value in
                    LineMark(x: .value("Date", date), y: .value("Système", value))
                        .foregroundStyle(by: .value("Usage", "Système"))
                        .interpolationMethod(.monotone)
                }
            }
            .chartForegroundStyleScale([
                "Plex Media Server": Color.green,
                "Système": Color.pink
            ])
            .chartYAxis {
                AxisMarks(position: .leading) { value in
                    AxisGridLine()
                    AxisValueLabel {
                        if let doubleValue = value.as(Double.self) {
                            Text("\(doubleValue, specifier: "%.0f")\(unit)")
                        }
                    }
                }
            }
            .chartXAxis {
                AxisMarks(values: .automatic(desiredCount: 4)) { value in
                    AxisGridLine()
                    if let date = value.as(Date.self) {
                        AxisValueLabel(formatted(date: date, relativeTo: latestDate))
                    }
                }
            }
            .chartLegend(position: .top, alignment: .trailing)
            .frame(height: 200)
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(16)
    }

    private func formatted(date: Date, relativeTo latestDate: Date) -> String {
        let difference = latestDate.timeIntervalSince(date)
        
        if difference <= 1 {
            return "Maintenant"
        }
        
        let formatter = DateComponentsFormatter()
        formatter.unitsStyle = .abbreviated
        formatter.allowedUnits = [.minute, .second]
        formatter.maximumUnitCount = 1
        
        return formatter.string(from: difference) ?? ""
    }
}
