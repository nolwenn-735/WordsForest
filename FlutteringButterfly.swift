import SwiftUI

struct FlutteringButterfly: View {
    var imageName: String
    var baseSize: CGFloat
    var baseOffset: CGSize
    var rotation: Double
    var opacity: Double
    var xAmplitude: CGFloat
    var yAmplitude: CGFloat
    var rotationAmplitude: Double
    var period: Double

    @State private var animating = false

    var body: some View {
        Image(imageName)
            .resizable()
            .frame(width: baseSize, height: baseSize)
            .opacity(opacity)
            .rotationEffect(.degrees(rotation + (animating ? rotationAmplitude : -rotationAmplitude)))
            .offset(
                x: baseOffset.width + (animating ? xAmplitude : -xAmplitude),
                y: baseOffset.height + (animating ? yAmplitude : -yAmplitude)
            )
            .onAppear {
                withAnimation(Animation.easeInOut(duration: period).repeatForever(autoreverses: true)) {
                    animating.toggle()
                }
            }
    }
}
