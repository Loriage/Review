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
        Section(header: Text("Historique des visionnages")) {
            ForEach(viewModel.historyItems) { item in
                historyRow(for: item)
            }
        }
    }
    
    private func historyRow(for item: MediaHistoryItem) -> some View {
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
        .padding(.vertical, 8)
    }

    private var emptyHistoryView: some View {
        Section {
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
        }
        .listRowInsets(EdgeInsets())
        .listRowSeparator(.hidden)
        .listRowBackground(Color.clear)
    }
}
