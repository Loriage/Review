import SwiftUI

struct MediaHeaderView: View {
    @ObservedObject var viewModel: MediaHistoryViewModel

    var body: some View {
        VStack(spacing: 20) {
            poster
        }
        .frame(maxWidth: .infinity)
    }

    private var poster: some View {
        AsyncImageView(url: viewModel.displayPosterURL, refreshTrigger: viewModel.imageRefreshId, contentMode: .fit)
            .aspectRatio(2/3, contentMode: .fit)
            .frame(height: 250)
            .cornerRadius(16)
            .shadow(color: .black.opacity(0.25), radius: 5, y: 5)
    }
}
