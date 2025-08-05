import SwiftUI

struct AsyncImageView: View {
    let url: URL?
    var contentMode: ContentMode = .fill
    var onColorExtracted: ((Color) -> Void)?

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

    private func extractDominantColor(from image: UIImage) -> Color? {
        let size = CGSize(width: 1, height: 1)
        let renderer = UIGraphicsImageRenderer(size: size)

        let a_cgImage = renderer.image { context in
            image.draw(in: CGRect(origin: .zero, size: size))
        }.cgImage

        guard let a_cgImage = a_cgImage,
            let dataProvider = a_cgImage.dataProvider
        else {
            return nil
        }

        guard let data = dataProvider.data,
            let pointer = CFDataGetBytePtr(data)
        else {
            return nil
        }

        let red = CGFloat(pointer[0]) / 255.0
        let green = CGFloat(pointer[1]) / 255.0
        let blue = CGFloat(pointer[2]) / 255.0

        return Color(red: red, green: green, blue: blue)
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
            if let onColorExtracted = onColorExtracted,
                let color = extractDominantColor(from: cachedImage)
            {
                onColorExtracted(color)
            }
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
                    if let onColorExtracted = onColorExtracted,
                        let color = extractDominantColor(from: loadedImage)
                    {
                        onColorExtracted(color)
                    }
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
