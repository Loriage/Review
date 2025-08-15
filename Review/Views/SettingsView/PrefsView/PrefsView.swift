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
                    Toggle("prefs.advanced.toggle", isOn: $viewModel.showAdvanced)
                        .padding(.vertical, 2)
                } footer: {
                    Text("prefs.advanced.footer")
                }
                
                Section {
                    navigationLink(for: "general", title: "prefs.group.general")
                    navigationLink(for: "library", title: "prefs.group.library")
                    navigationLink(for: "network", title: "prefs.group.network")
                    navigationLink(for: "transcoder", title: "prefs.group.transcoder")
                    navigationLink(for: "dlna", title: "prefs.group.dlna")
                    navigationLink(for: "butler", title: "prefs.group.butler")
                    navigationLink(for: "extras", title: "prefs.group.extras")
                }
            }
        }
        .navigationTitle("prefs.view.title")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            if viewModel.hasChanges {
                ToolbarItem(placement: .confirmationAction) {
                    Button("common.save") {
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
        .alert("prefs.unsaved.changes.alert.title", isPresented: $showingExitAlert) {
            Button("prefs.unsaved.changes.alert.leave", role: .destructive) { dismiss() }
            Button("prefs.unsaved.changes.alert.stay", role: .cancel) {}
        } message: {
            Text("prefs.unsaved.changes.alert.message")
        }
    }
    
    private func navigationLink(for group: String, title: LocalizedStringKey) -> some View {
        NavigationLink(title) {
            PrefsSectionView(viewModel: viewModel, group: group, title: title)
                .toolbar {
                    if viewModel.hasChanges {
                        ToolbarItem(placement: .confirmationAction) {
                            Button("common.save") {
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
    let title: LocalizedStringKey
    
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
                    TextField("common.undefined", text: $vm.value)
                        .multilineTextAlignment(.trailing)
                        .textFieldStyle(.automatic)
                        .foregroundColor(.secondary)
                }
            }
        
        default:
            Text("prefs.unknown.field \(vm.setting.type)")
        }
    }
}
