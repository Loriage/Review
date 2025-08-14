import SwiftUI

struct PrefsView: View {
    @StateObject private var viewModel = PrefsViewModel()
    @EnvironmentObject var serverViewModel: ServerViewModel
    @EnvironmentObject var authManager: PlexAuthManager
    @Environment(\.dismiss) private var dismiss
    @State private var showingExitAlert = false

    var body: some View {
        Form {
            if viewModel.isLoading {
                ProgressView()
            } else {
                Section {
                    Toggle("Paramètres avancés du serveur", isOn: $viewModel.showAdvanced)
                        .padding(.vertical, 2)
                } footer: {
                    Text("Paramètres supplémentaires pour administrateur de serveur expérimenté uniquement.")
                }
                
                Section {
                    navigationLink(for: "general", title: "Général")
                    navigationLink(for: "library", title: "Bibliothèque")
                    navigationLink(for: "network", title: "Réseau")
                    navigationLink(for: "transcoder", title: "Transcodeur")
                    navigationLink(for: "dlna", title: "DLNA")
                    navigationLink(for: "butler", title: "Tâches planifiées")
                    navigationLink(for: "extras", title: "Bonus")
                }
            }
        }
        .navigationTitle("Préférences")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            if viewModel.hasChanges {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Sauvegarder") {
                        Task {
                            await viewModel.saveChanges(serverViewModel: serverViewModel, authManager: authManager)
                        }
                    }
                }
            }
        }
        .task {
            await viewModel.loadPrefs(serverViewModel: serverViewModel, authManager: authManager)
        }
        .alert("Quitter sans sauvegarder ?", isPresented: $showingExitAlert) {
            Button("Quitter", role: .destructive) { dismiss() }
            Button("Rester", role: .cancel) {}
        } message: {
            Text("Vous avez des modifications non sauvegardées. Êtes-vous sûr de vouloir quitter ?")
        }
    }
    
    private func navigationLink(for group: String, title: String) -> some View {
        NavigationLink(title) {
            PrefsSectionView(viewModel: viewModel, group: group, title: title)
                .toolbar {
                    if viewModel.hasChanges {
                        ToolbarItem(placement: .confirmationAction) {
                            Button("Sauvegarder") {
                                Task {
                                    await viewModel.saveChanges(serverViewModel: serverViewModel, authManager: authManager)
                                }
                            }
                        }
                    }
                }
                .onDisappear {
                    if viewModel.hasChanges {
                        showingExitAlert = true
                    }
                }
        }
    }
}

struct PrefsSectionView: View {
    @ObservedObject var viewModel: PrefsViewModel
    let group: String
    let title: String
    
    var body: some View {
        Form {
            ForEach(viewModel.groupSettings(for: group)) { settingVM in
                    PrefsSettingRowView(vm: settingVM)
            }
        }
        .navigationTitle(title)
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct PrefsSettingRowView: View {
    @ObservedObject var vm: PlexServerSettingViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            settingControl
            if let summary = vm.setting.summary, !summary.isEmpty {
                Text(summary)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 4)
    }

    @ViewBuilder
    private var settingControl: some View {
        switch vm.setting.type {
        case "bool":
            Toggle(vm.setting.label, isOn: vm.boolValue)
        
        case "int", "text":
            if !vm.enumValues.isEmpty {
                Picker(vm.setting.label, selection: $vm.value) {
                    ForEach(vm.enumValues) { value in
                        Text(value.name).tag(value.id)
                    }
                }
            } else {
                HStack {
                    Text(vm.setting.label)
                    Spacer()
                    TextField("Non défini", text: $vm.value)
                        .multilineTextAlignment(.trailing)
                        .textFieldStyle(.automatic)
                        .foregroundColor(.secondary)
                }
            }
        
        default:
            Text("Type de champ inconnu : \(vm.setting.type)")
        }
    }
}
