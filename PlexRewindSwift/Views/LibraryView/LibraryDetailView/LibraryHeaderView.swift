import SwiftUI
import Charts

struct LibraryHeaderView: View {
    @ObservedObject var viewModel: LibraryDetailViewModel
    @ObservedObject var library: DisplayLibrary

    var body: some View {
        VStack(spacing: 12) {
            statsSection
            if !viewModel.chartData.isEmpty {
                MediaGrowthChartView(data: viewModel.chartData)
            }
        }
    }

    private var statsSection: some View {
        HStack(spacing: 10) {
            if viewModel.library.library.type == "movie" {
                InfoPill(title: "Films", value: library.fileCount != nil ? "\(library.fileCount!)" : "...", customBackgroundColor: Color(.secondarySystemBackground))
                InfoPill(title: "Taille", value: library.size != nil ? formatBytes(library.size!) : "...", customBackgroundColor: Color(.secondarySystemBackground))
            } else if viewModel.library.library.type == "show" {
                InfoPill(title: "Séries", value: library.fileCount != nil ? "\(library.fileCount!)" : "...", customBackgroundColor: Color(.secondarySystemBackground))
                InfoPill(title: "Épisodes", value: library.episodesCount != nil ? "\(library.episodesCount!)" : "...", customBackgroundColor: Color(.secondarySystemBackground))
                InfoPill(title: "Taille", value: library.size != nil ? formatBytes(library.size!) : "...", customBackgroundColor: Color(.secondarySystemBackground))
            }
        }
    }

    private func formatBytes(_ bytes: Int64) -> String {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useGB, .useMB, .useTB]
        formatter.countStyle = .binary
        return formatter.string(fromByteCount: bytes)
    }
}

private struct MediaGrowthChartView: View {
    let data: [(Date, Int)]
    
    var body: some View {
        VStack(alignment: .leading) {
            Text("Croissance de la bibliothèque")
                .font(.headline.bold())
                .padding(.bottom, 10)
            
            Chart {
                ForEach(data, id: \.0) { date, count in
                    LineMark(x: .value("Date", date), y: .value("Nombre de médias", count))
                        .interpolationMethod(.linear)
                        .foregroundStyle(Color.accentColor)

                    AreaMark(x: .value("Date", date), y: .value("Nombre de médias", count))
                        .interpolationMethod(.linear)
                        .foregroundStyle(
                            LinearGradient(
                                gradient: Gradient(colors: [Color.accentColor.opacity(0.4), Color.accentColor.opacity(0.01)]),
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                }
            }
            .chartXAxis {
                AxisMarks(values: .automatic(desiredCount: 5)) { value in
                    AxisGridLine()
                    AxisValueLabel(format: .dateTime.month(.twoDigits).year(.twoDigits))
                }
            }
            .chartYAxis { AxisMarks(position: .leading) }
            .frame(height: 180)
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(16)
    }
}
