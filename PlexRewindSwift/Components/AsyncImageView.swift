import SwiftUI

struct AsyncImageView: View {
    let url: URL?
    var contentMode: ContentMode = .fill

    @State private var image: UIImage?
    @State private var isLoading = true

    var body: some View {
        Group {
            if isLoading {
                ZStack {
                    Color(.secondarySystemBackground)
                    ProgressView()
                }
            } else if let image = image {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: contentMode)
            } else {
                ZStack {
                    Color(.secondarySystemBackground)
                    Image(systemName: "photo.fill")
                        .font(.largeTitle)
                        .foregroundColor(.secondary)
                }
            }
        }
        .onAppear(perform: loadImage)
        .onChange(of: url) {
            loadImage()
        }
    }

    private func loadImage() {
        guard let url = url else {
            isLoading = false
            image = nil
            return
        }

        if let cachedImage = ImageCache.shared.get(for: url) {
            self.image = cachedImage
            self.isLoading = false
            return
        }

        isLoading = true
        image = nil

        Task {
            do {
                let (data, _) = try await URLSession.shared.data(from: url)
                if let loadedImage = UIImage(data: data) {
                    ImageCache.shared.set(loadedImage, for: url)
                    self.image = loadedImage
                } else {
                    self.image = nil
                }
            } catch {
                self.image = nil
            }
            self.isLoading = false
        }
    }
}
