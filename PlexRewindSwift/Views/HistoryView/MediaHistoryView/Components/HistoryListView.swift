import SwiftUI

struct HistoryListView: View {
    @ObservedObject var viewModel: MediaHistoryViewModel

    var body: some View {
        if viewModel.historyItems.isEmpty {
            emptyHistoryView
        } else {
            historySection
        }
    }

    private var historySection: some View {
        VStack(alignment: .leading) {
            LazyVStack(spacing: 0) {
                ForEach(viewModel.historyItems) { item in
                    historyRow(for: item)
                    if item.id != viewModel.historyItems.last?.id {
                        Divider().padding(.leading, 16)
                    }
                }
            }
            .background(Color(.secondarySystemBackground))
            .cornerRadius(12)
        }
        .padding(.horizontal)
    }
    
    private func historyRow(for item: MediaHistoryItem) -> some View {
        HStack(spacing: 15) {
            AsyncImageView(url: item.userThumbURL)
                .frame(width: 50, height: 50)
                .clipShape(Circle())
            VStack(alignment: .leading, spacing: 5) {
                if item.session.type == "episode" {
                    Text(item.session.showTitle)
                        .font(.headline)
                } else {
                    Text(item.session.title ?? "Titre inconnu")
                        .font(.headline)
                }
                
                if item.session.type == "episode" {
                    Text("S\(item.session.parentIndex ?? 0) - E\(item.session.index ?? 0) - \(item.session.title ?? "Titre inconnu")")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                if let viewedAt = item.session.viewedAt {
                    Text("\(item.userName ?? "Utilisateur inconnu") - \(Date(timeIntervalSince1970: viewedAt).formatted(.relative(presentation: .named)))")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 12)
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var emptyHistoryView: some View {
        VStack(spacing: 10) {
            Image(systemName: "film.stack")
                .font(.system(size: 20))
                .foregroundColor(.secondary)
            Text("Aucun historique trouvé")
                .font(.title3.bold())
            Text("L'historique pour ce média est vide.")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 50)
    }
}
