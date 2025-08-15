import SwiftUI

struct CustomLinearProgressViewStyle: ProgressViewStyle {
    var trackColor: Color
    var progressColor: Color
    var height: CGFloat

    func makeBody(configuration: Configuration) -> some View {
        let progress = configuration.fractionCompleted ?? 0.0

        return GeometryReader { geometry in
            ZStack(alignment: .leading) {
                Rectangle()
                    .fill(trackColor)
                    .frame(height: height)

                Rectangle()
                    .fill(progressColor)
                    .frame(width: geometry.size.width * progress, height: height)
            }
            .cornerRadius(0)
        }
        .frame(height: height)
    }
}
