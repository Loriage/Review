import SwiftUI

struct LibrarySettingsView: View {
    @StateObject private var viewModel: LibrarySettingsViewModel
    @EnvironmentObject var serverViewModel: ServerViewModel
    @EnvironmentObject var authManager: PlexAuthManager

    @State private var showCopyHUD = false

    init(library: DisplayLibrary, serverViewModel: ServerViewModel, authManager: PlexAuthManager) {
        _viewModel = StateObject(wrappedValue: LibrarySettingsViewModel(library: library, serverViewModel: serverViewModel, authManager: authManager))
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Form {
                    Section(header: Text("library.settings.view.info.section.title")) {
                        VStack(alignment: .leading, spacing: 12) {
                            HStack(spacing: 12) {
                                InfoPill(title: "media.detail.id", value: viewModel.library.library.key)
                                InfoPill(title: "media.detail.name", value: viewModel.library.library.title)
                            }
                            HStack(spacing: 12) {
                                InfoPill(title: "media.detail.type", value: viewModel.library.library.type.capitalized)
                                InfoPill(title: "media.detail.language", value: viewModel.library.library.language)
                            }

                            ForEach(viewModel.library.library.locations) { location in
                                HStack(spacing: 10) {
                                    InfoPill(title: "media.detail.path", value: location.path)
                                    Button(action: {
                                        UIPasteboard.general.string = location.path
                                        withAnimation {
                                            showCopyHUD = true
                                        }
                                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                                            withAnimation {
                                                showCopyHUD = false
                                            }
                                        }
                                    }) {
                                        Image(systemName: "doc.on.doc")
                                            .font(.title2)
                                    }
                                    .buttonStyle(.borderless)
                                }
                            }
                        }
                        .padding(.vertical, 5)
                    }
                    .listRowInsets(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0))
                    .listRowBackground(Color.clear)

                    Section(header: Text("library.settings.sheet.library.settings")) {
                        ForEach(viewModel.preferenceItems) { item in
                            PreferenceRowView(viewModel: item)
                        }
                    }
                }
                if let hudMessage = viewModel.hudMessage {
                    HUDView(hudMessage: hudMessage)
                }
                if showCopyHUD {
                    HUDView(hudMessage: HUDMessage(iconName: "doc.on.doc.fill", text: "hud.copied", maxWidth: 180))
                        .transition(.scale.combined(with: .opacity))
                        .zIndex(1)
                }
            }
            .navigationTitle("settings.title")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    if viewModel.hasChanges {
                        Button("common.save") {
                            Task {
                                await viewModel.saveChanges()
                            }
                        }
                    }
                }
            }
        }
    }
}

struct PreferenceRowView: View {
    @ObservedObject var viewModel: PreferenceItemViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            controlView

            if !viewModel.summary.isEmpty {
                Text(viewModel.summary)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.leading, 1)
            }
        }
        .padding(.vertical, 5)
    }

    @ViewBuilder
    private var controlView: some View {
        switch viewModel.type {
        case "bool":
            Toggle(viewModel.label, isOn: viewModel.boolValue)
        case "int", "text":
            if !viewModel.enumValues.isEmpty {
                Picker(viewModel.label, selection: $viewModel.value) {
                    ForEach(viewModel.enumValues) { value in
                        Text(value.name).tag(value.id)
                    }
                }
            } else {
                Text("\(String(localized: "prefs.unsupported.field")) \(viewModel.id)")
            }
        default:
            Text("prefs.unknown.field \(viewModel.type)")
        }
    }
}
