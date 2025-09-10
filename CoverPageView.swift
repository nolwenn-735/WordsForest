import SwiftUI

struct CoverPageView: View {
    var body: some View {
        ZStack {
            // 背景
            Color(.systemGreen)
                .opacity(0.20)
                .ignoresSafeArea()

            // タイトル＋サブタイトル
            VStack {
                Text("Words' Forest 🌳")
                    .font(.title)
                    .foregroundColor(Color(.systemGreen))
                    .shadow(color: Color.black.opacity(0.25), radius: 2, x: 1, y: 1)
                    .padding(.top, 70)

                Text("A gentle vocabulary journey")
                    .font(.subheadline)
                    .foregroundColor(.gray)
                    .padding(.top, 4)

                Spacer()
            }

            // 🐇 うさぎ
            Image("adj_rabbit_beige")
                .resizable()
                .scaledToFit()
                .frame(width: 200)
                .offset(y: 80)
                .opacity(0.95)
                .shadow(color: .black.opacity(0.6), radius: 4, x: 2, y: 2)
                .accessibilityHidden(true)

            // 🦋 黄色の蝶
            FlutteringButterfly(
                imageName: "butterfly_yellow",
                baseSize: 60,
                baseOffset: CGSize(width: 0, height: -80),
                rotation: -10,
                opacity: 0.85,
                xAmplitude: 4, yAmplitude: 6,
                rotationAmplitude: 6,
                period: 2.8
            )

            // 🦋 水色の蝶
            FlutteringButterfly(
                imageName: "butterfly_blue1",
                baseSize: 80,
                baseOffset: CGSize(width: -95, height: -135),
                rotation: 8,
                opacity: 0.9,
                xAmplitude: 8, yAmplitude: 12,
                rotationAmplitude: 10,
                period: 4.0
            )

            // 右下のきのこ
            VStack {
                Spacer()
                HStack {
                    Spacer()
                    Image("mycol_mushroom")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 140)
                        .padding(.trailing, 16)
                        .padding(.bottom, 16)
                }
            }

            // 左下ヒント
            VStack {
                Spacer()
                HStack {
                    Text("← スワイプして HOME へ")
                        .font(.footnote)
                        .foregroundColor(.secondary)
                        .padding(.leading, 16)
                        .padding(.bottom, 12)
                    Spacer()
                }
            }
            .allowsHitTesting(false)
        }
    }
}

// 同梱：フラッター（※他ファイルに同名定義があるならそちらは削除）
struct FlutteringButterfly: View {
    let imageName: String
    let baseSize: CGFloat
    let baseOffset: CGSize
    let rotation: Double
    let opacity: Double
    let xAmplitude: CGFloat
    let yAmplitude: CGFloat
    let rotationAmplitude: Double
    let period: Double

    var body: some View {
        TimelineView(.animation) { timeline in
            let t = timeline.date.timeIntervalSinceReferenceDate / period * 2 * .pi
            let dx = xAmplitude * CGFloat(sin(t))
            let dy = yAmplitude * CGFloat(cos(t * 0.9))
            let rot = rotation + rotationAmplitude * sin(t * 1.2)

            Image(imageName)
                .resizable()
                .scaledToFit()
                .frame(width: baseSize)
                .offset(x: baseOffset.width + dx,
                        y: baseOffset.height + dy)
                .rotationEffect(.degrees(rot))
                .opacity(opacity)
                .accessibilityHidden(true)
                .allowsHitTesting(false)
        }
    }
}
