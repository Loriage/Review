import SwiftUI

struct UserHistoryListView: View {
    @ObservedObject var viewModel: UserHistoryViewModel

    var body: some View {
        Section(header: Text("history.view.title")) {
            ForEach(viewModel.sessions) { session in
                NavigationLink(destination: mediaHistoryDestination(for: session)) {
                    UserHistoryRow(session: session, viewModel: viewModel)
                }
            }
        }
    }
    
    private func mediaHistoryDestination(for session: WatchSession) -> some View {
        MediaHistoryView(
            ratingKey: session.ratingKey ?? "",
            mediaType: session.type ?? "",
            grandparentRatingKey: session.computedGrandparentRatingKey,
            serverViewModel: viewModel.serverViewModel,
            authManager: viewModel.authManager,
            statsViewModel: viewModel.statsViewModel
        )
    }
}

private struct UserHistoryRow: View {
    let session: WatchSession
    @ObservedObject var viewModel: UserHistoryViewModel
    
    var body: some View {
        HStack(spacing: 15) {
            AsyncImageView(url: viewModel.posterURL(for: session), contentMode: .fill)
                .frame(width: 60, height: 90)
                .cornerRadius(8)
            
            VStack(alignment: .leading, spacing: 4) {
                mediaTitles
                
                if let viewedAt = session.viewedAt {
                    Text("\(Date(timeIntervalSince1970: viewedAt).formatted(.relative(presentation: .named)))")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }
            .padding(.vertical, 4)
        }
    }
    
    @ViewBuilder
    private var mediaTitles: some View {
        if session.type == "movie" {
            Text(session.title ?? "common.unknown.title")
                .font(.headline)
        } else if session.type == "episode" {
            Text(session.grandparentTitle ?? "common.unknown.show")
                .font(.headline)
            Text(session.title ?? "common.unknown.episode")
                .font(.subheadline)
                .foregroundColor(.secondary)
            Text("S\(session.parentIndex ?? 0) - E\(session.index ?? 0)")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
    }
}
