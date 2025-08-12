import SwiftUI

struct HistorySyncSection: View {
    @EnvironmentObject var serverViewModel: ServerViewModel
    @EnvironmentObject var statsViewModel: StatsViewModel

    var body: some View {
        Section {
            Button(action: {
                Task {
                    await statsViewModel.syncFullHistory()
                }
            }) {
                HStack {
                    if statsViewModel.isLoading {
                        ProgressView()
                        Text(statsViewModel.loadingStatusMessage.isEmpty ? "Synchronisation..." : statsViewModel.loadingStatusMessage)
                            .font(.footnote)
                            .foregroundColor(.secondary)
                    } else {
                        Text(statsViewModel.isHistorySynced ? "Re-synchroniser l'historique" : "Synchroniser l'historique complet")
                    }
                }
            }
            .disabled(serverViewModel.selectedServerID == nil || statsViewModel.isLoading)
        } header: {
            Text("Données")
        } footer: {
            if let formattedDateText = statsViewModel.formattedLastSyncDate {
                Text(formattedDateText)
            }
        }
    }
}
