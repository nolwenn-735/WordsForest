import SwiftUI
import Foundation

struct CoverPageView: View {
    /// 表紙を閉じて Home を見せる時に呼ばれる
    var onStart: () -> Void = {}

    @State private var dragX: CGFloat = 0

    var body: some View {
        GeometryReader { geo in
            ZStack {
                // 背景（薄いグリーン）
                Color.coverMintA.ignoresSafeArea()

                // タイトル＋サブタイトル
                VStack {
                    Text("Words' Forest 🌳")
                        .font(.title)
                        .foregroundColor(Color(.systemGreen))
                        .shadow(color: .black.opacity(0.25), radius: 2, x: 1, y: 1)
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

                // 🦋 黄色い蝶
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
            .frame(maxWidth: .infinity, maxHeight: .infinity)   // ✅ これにする
            .offset(x: dragX)
            .gesture(
                DragGesture(minimumDistance: 24)
                    .onChanged { value in
                        // 左方向だけ追従
                        dragX = min(0, value.translation.width)
                    }
                    .onEnded { value in
                        if value.translation.width < -80 {
                            // しきい値超えたら画面外まで送り出してから閉じる
                            withAnimation(.easeInOut(duration: 0.22)) {
                                dragX = -geo.size.width
                            }
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.22) {
                                onStart()
                                dragX = 0
                            }
                        } else {
                            // 戻す
                            withAnimation(.spring(response: 0.28)) {
                                dragX = 0
                            }
                        }
                    }
            )
        }
        .interactiveDismissDisabled(true)// 下スワイプで閉じる誤作動を防止
    }
}

extension Color {
    /// Mint A (220,245,232)
    static let coverMintA = Color(.sRGB, red: 220/255, green: 245/255, blue: 232/255, opacity: 1)

    /// Mint B (202,238,220)
    static let coverMintB = Color(.sRGB, red: 202/255, green: 238/255, blue: 220/255, opacity: 1)

    /// Mint C (186,232,208)
    static let coverMintC = Color(.sRGB, red: 186/255, green: 232/255, blue: 208/255, opacity: 1)
}
