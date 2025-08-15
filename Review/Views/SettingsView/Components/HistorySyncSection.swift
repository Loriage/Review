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
                        Text(statsViewModel.loadingStatusMessage.isEmpty ? "info.view.sync" : statsViewModel.loadingStatusMessage)
                            .font(.footnote)
                            .foregroundColor(.secondary)
                    } else {
                        Text(statsViewModel.isHistorySynced ? "info.view.resync" : "info.view.sync.history")
                    }
                }
            }
            .disabled(serverViewModel.selectedServerID == nil || statsViewModel.isLoading)
        } header: {
            Text("info.view.data")
        } footer: {
            if let formattedDateText = statsViewModel.formattedLastSyncDate {
                Text(formattedDateText)
            }
        }
    }
}
