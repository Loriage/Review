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
                    ProgressView("info.view.loading")
                }
                .navigationTitle("info.view.title")
                .navigationBarTitleDisplayMode(.inline)
            } else {
                ScrollView {
                    VStack(spacing: 20) {
                        NetworkChartView(
                            title: "info.view.network.chart.title",
                            localData: viewModel.localNetworkData,
                            remoteData: viewModel.remoteNetworkData,
                            unit: viewModel.networkUnit
                        )
                        
                        CpuChartView(
                            title: "info.view.cpu.chart.title",
                            plexData: viewModel.plexCpuData,
                            systemData: viewModel.systemCpuData,
                            unit: "%"
                        )

                        RamChartView(
                            title: "info.view.ram.chart.title",
                            plexData: viewModel.plexRamData,
                            systemData: viewModel.systemRamData,
                            unit: "%"
                        )
                    }
                    .padding()
                }
                .navigationTitle("info.view.title")
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
    let title: LocalizedStringKey
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
        let plexLabel = String(localized: "charts.plex.label")
        let systemLabel = String(localized: "charts.system.label")
        let usageLabel = String(localized: "charts.common.usage")
        let dateLabel = String(localized: "charts.common.date")

        VStack(alignment: .leading) {
            Text(title)
                .font(.headline.bold())
                .padding(.bottom, 5)

            Chart {
                ForEach(plexData, id: \.0) { date, value in
                    LineMark(
                        x: .value(dateLabel, date),
                        y: .value(plexLabel, value)
                    )
                    .foregroundStyle(by: .value(usageLabel, plexLabel))
                    .interpolationMethod(.monotone)
                }
                
                ForEach(systemData, id: \.0) { date, value in
                    LineMark(
                        x: .value(dateLabel, date),
                        y: .value(systemLabel, value)
                    )
                    .foregroundStyle(by: .value(usageLabel, systemLabel))
                    .interpolationMethod(.monotone)
                }
            }
            .chartForegroundStyleScale([
                plexLabel: Color.cyan,
                systemLabel: Color.pink
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
            return String(localized: "charts.common.now")
        }
        
        let formatter = DateComponentsFormatter()
        formatter.unitsStyle = .abbreviated
        formatter.allowedUnits = [.minute, .second]
        formatter.maximumUnitCount = 1
        
        return formatter.string(from: difference) ?? ""
    }
}

struct NetworkChartView: View {
    let title: LocalizedStringKey
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
        let localLabel = String(localized: "location.local")
        let remoteLabel = String(localized: "location.remote")
        let typeLabel = String(localized: "charts.common.type")
        let dateLabel = String(localized: "charts.common.date")

        VStack(alignment: .leading) {
            Text(title)
                .font(.headline.bold())
                .padding(.bottom, 5)

            Chart {
                ForEach(localData, id: \.0) { date, value in
                    LineMark(
                        x: .value(dateLabel, date),
                        y: .value(localLabel, scaleValue(value))
                    )
                    .foregroundStyle(by: .value(typeLabel, localLabel))
                    .interpolationMethod(.monotone)
                }
                
                ForEach(remoteData, id: \.0) { date, value in
                    LineMark(
                        x: .value(dateLabel, date),
                        y: .value(remoteLabel, scaleValue(value))
                    )
                    .foregroundStyle(by: .value(typeLabel, remoteLabel))
                    .interpolationMethod(.monotone)
                }
            }
            .chartForegroundStyleScale([
                localLabel: Color.yellow,
                remoteLabel: Color.blue
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
            return String(localized: "charts.common.now")
        }
        
        let formatter = DateComponentsFormatter()
        formatter.unitsStyle = .abbreviated
        formatter.allowedUnits = [.minute, .second]
        formatter.maximumUnitCount = 1
        
        return formatter.string(from: difference) ?? ""
    }
}

struct CpuChartView: View {
    let title: LocalizedStringKey
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
        let plexLabel = String(localized: "charts.plex.label")
        let systemLabel = String(localized: "charts.system.label")
        let usageLabel = String(localized: "charts.common.usage")
        let dateLabel = String(localized: "charts.common.date")

        VStack(alignment: .leading) {
            Text(title)
                .font(.headline.bold())
                .padding(.bottom, 5)

            Chart {
                ForEach(plexData, id: \.0) { date, value in
                    LineMark(
                        x: .value(dateLabel, date),
                        y: .value(plexLabel, value)
                    )
                    .foregroundStyle(by: .value(usageLabel, plexLabel))
                    .interpolationMethod(.monotone)
                }
                
                ForEach(systemData, id: \.0) { date, value in
                    LineMark(
                        x: .value(dateLabel, date),
                        y: .value(systemLabel, value)
                    )
                    .foregroundStyle(by: .value(usageLabel, systemLabel))
                    .interpolationMethod(.monotone)
                }
            }
            .chartForegroundStyleScale([
                plexLabel: Color.green,
                systemLabel: Color.pink
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
            return String(localized: "charts.common.now")
        }
        
        let formatter = DateComponentsFormatter()
        formatter.unitsStyle = .abbreviated
        formatter.allowedUnits = [.minute, .second]
        formatter.maximumUnitCount = 1
        
        return formatter.string(from: difference) ?? ""
    }
}
