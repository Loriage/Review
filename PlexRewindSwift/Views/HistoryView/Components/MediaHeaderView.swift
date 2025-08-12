import SwiftUI

struct MediaHeaderView: View {
    @ObservedObject var viewModel: MediaHistoryViewModel

    var body: some View {
        Section {
            VStack(spacing: 0) {
                poster
                if let summary = viewModel.summary, !summary.isEmpty {
                    summarySection(with: summary)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.bottom)
        }
        .listRowInsets(EdgeInsets())
        .listRowSeparator(.hidden)
        .listRowBackground(Color.clear)
    }

    private var poster: some View {
        AsyncImageView(url: viewModel.displayPosterURL, refreshTrigger: viewModel.imageRefreshId, contentMode: .fit)
            .aspectRatio(2/3, contentMode: .fit)
            .frame(height: 250)
            .cornerRadius(16)
            .shadow(color: .black.opacity(0.25), radius: 5, y: 5)
            .padding(.top, 5)
            .padding(.bottom, 20)
    }

    private func summarySection(with summary: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Résumé")
                .font(.title2.bold())
            Text(summary)
                .font(.body)
                .foregroundColor(.secondary)
        }
    }
}
