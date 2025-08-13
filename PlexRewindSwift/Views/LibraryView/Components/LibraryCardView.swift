import SwiftUI

struct LibraryCardView: View {
    @ObservedObject var displayLibrary: DisplayLibrary
    @State private var dominantColor: Color = .clear

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: -35){
                if displayLibrary.recentItemURLs.isEmpty {
                    ForEach(0..<5, id: \.self) { index in
                        ZStack {
                            Color(.secondarySystemBackground)
                            ProgressView()
                        }
                        .frame(width: 60, height: 90)
                        .cornerRadius(8)
                        .shadow(radius: 3)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color.black.opacity(0.1), lineWidth: 1)
                        )
                        .zIndex(Double(-index))
                    }
                } else {
                    ForEach(Array(displayLibrary.recentItemURLs.prefix(5).enumerated()), id: \.element) { index, url in
                        AsyncImageView(url: url, onColorExtracted: { color in
                            if index == 0 {
                                self.dominantColor = color
                            }
                        })
                        .frame(width: 60, height: 90)
                        .cornerRadius(8)
                        .shadow(radius: 3)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color.black.opacity(0.2), lineWidth: 1)
                        )
                        .zIndex(Double(-index))
                    }
                }
            }
            HStack(alignment: .top, spacing: 15) {
                VStack(alignment: .leading, spacing: 12) {
                    Text(displayLibrary.library.title)
                        .font(.title2.bold())

                    VStack(alignment: .leading, spacing: 5) {
                        Label {
                            HStack {
                                Text("Nombre de \(PlexMediaTypeHelper.formattedTypeNamePlural(for: displayLibrary.library.type)) :")
                                    .fontWeight(.semibold)
                                Spacer()
                                if let count = displayLibrary.fileCount {
                                    Text("\(count)")
                                        .fontWeight(.semibold)
                                } else {
                                    ProgressView().scaleEffect(0.7)
                                }
                            }
                        } icon: {
                            Image(systemName: PlexMediaTypeHelper.iconName(for: displayLibrary.library.type))
                                .symbolRenderingMode(.monochrome)
                                .fontWeight(.semibold)
                                .frame(width: 20)
                        }
                        
                        Label {
                            HStack {
                                Text("Taille :")
                                    .fontWeight(.semibold)
                                Spacer()
                                if let size = displayLibrary.size {
                                    Text(formatBytes(size))
                                        .fontWeight(.semibold)
                                } else {
                                    ProgressView().scaleEffect(0.7)
                                }
                            }
                        } icon: {
                            Image(systemName: "externaldrive.fill")
                                .frame(width: 20)
                        }

                        Label {
                            Text("Créée le :")
                                .fontWeight(.semibold)
                            Spacer()
                            Text(formatDate(displayLibrary.library.createdAt))
                                .fontWeight(.semibold)
                        } icon: {
                            Image(systemName: "calendar.badge.plus")
                                .frame(width: 20)
                        }

                        Label {
                            Text("Dernier scan :")
                                .fontWeight(.semibold)
                            Spacer()
                            Text(formatDate(displayLibrary.library.scannedAt))
                                .fontWeight(.semibold)
                        } icon: {
                            Image(systemName: "arrow.trianglehead.counterclockwise")
                                .fontWeight(.semibold)
                                .frame(width: 20)
                        }
                    }
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                }
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 20))
        .background(
            MeshGradient(
                width: 3, height: 3,
                points: [ [0, 0], [0.5, 0], [1, 0], [0, 0.5], [0.5, 0.5], [1, 0.5], [0, 1], [0.5, 1], [1, 1] ],
                colors: [ .clear, dominantColor.opacity(0.3), .clear, Color.accentColor.opacity(0.2), dominantColor.opacity(0.3), Color.accentColor.opacity(0.2), .clear, .clear, dominantColor.opacity(0.2) ]
            )
        )
        .cornerRadius(20)
        .animation(.spring(), value: dominantColor)
    }

    private func formatDate(_ timestamp: Int) -> String {
        let date = Date(timeIntervalSince1970: TimeInterval(timestamp))
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "fr_FR")
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter.string(from: date)
    }
    
    private func formatBytes(_ bytes: Int64) -> String {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useGB, .useMB, .useTB]
        formatter.countStyle = .binary
        return formatter.string(fromByteCount: bytes)
    }
}
