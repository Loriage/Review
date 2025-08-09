import SwiftUI
import CoreGraphics

struct AsyncImageView: View {
    let url: URL?
    var refreshTrigger: UUID?
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
                        .font(.title)
                        .foregroundColor(.secondary)
                }
            }
        }
        .onAppear(perform: loadImage)
        .onChange(of: url) { loadImage() }
        .onChange(of: refreshTrigger) { loadImage() }
    }

    private func extractDominantColor(from image: UIImage) -> Color? {
        guard let cgImage = image.cgImage else { return nil }

        let width = 20
        let height = 20
        let bytesPerPixel = 4
        let bytesPerRow = bytesPerPixel * width
        let bitsPerComponent = 8
        var rawData = [UInt8](repeating: 0, count: width * height * bytesPerPixel)
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let bitmapInfo = CGImageAlphaInfo.premultipliedLast.rawValue | CGBitmapInfo.byteOrder32Big.rawValue

        guard let context = CGContext(data: &rawData,
                                      width: width,
                                      height: height,
                                      bitsPerComponent: bitsPerComponent,
                                      bytesPerRow: bytesPerRow,
                                      space: colorSpace,
                                      bitmapInfo: bitmapInfo) else {
            return nil
        }
        
        context.draw(cgImage, in: CGRect(x: 0, y: 0, width: width, height: height))
        
        var colorCounts: [Int: Int] = [:]
        
        for i in stride(from: 0, to: rawData.count, by: bytesPerPixel) {
            let red = rawData[i]
            let green = rawData[i + 1]
            let blue = rawData[i + 2]
            
            let hsb = rgbToHsb(r: red, g: green, b: blue)

            if hsb.saturation > 0.4 && hsb.brightness > 0.35 && hsb.brightness < 0.95 {
                let colorInt = (Int(red) << 16) | (Int(green) << 8) | Int(blue)
                colorCounts[colorInt, default: 0] += 1
            }
        }

        if let mostFrequentColor = colorCounts.max(by: { $0.value < $1.value })?.key {
            let red = CGFloat((mostFrequentColor >> 16) & 0xFF) / 255.0
            let green = CGFloat((mostFrequentColor >> 8) & 0xFF) / 255.0
            let blue = CGFloat(mostFrequentColor & 0xFF) / 255.0
            return Color(red: red, green: green, blue: blue)
        }

        return nil
    }

    private func rgbToHsb(r: UInt8, g: UInt8, b: UInt8) -> (hue: CGFloat, saturation: CGFloat, brightness: CGFloat) {
        let red = CGFloat(r) / 255.0
        let green = CGFloat(g) / 255.0
        let blue = CGFloat(b) / 255.0
        
        let maxVal = max(red, green, blue)
        let minVal = min(red, green, blue)
        
        var hue: CGFloat = 0
        let brightness = maxVal
        let delta = maxVal - minVal
        
        let saturation = maxVal == 0 ? 0 : delta / maxVal
        
        if maxVal != minVal {
            if maxVal == red {
                hue = (green - blue) / delta + (green < blue ? 6 : 0)
            } else if maxVal == green {
                hue = (blue - red) / delta + 2
            } else { // maxVal == blue
                hue = (red - green) / delta + 4
            }
            hue /= 6
        }
        
        return (hue, saturation, brightness)
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
            if let onColorExtracted = onColorExtracted, let color = extractDominantColor(from: cachedImage) {
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
                    if let onColorExtracted = onColorExtracted, let color = extractDominantColor(from: loadedImage) {
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
