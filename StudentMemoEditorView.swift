//
//  StudentMemoEditorView.swift
//  WordsForest
//
//  Created by Nami .T on 2026/09/19.
//

import SwiftUI

struct StudentMemoEditorView: View {

    let pageID: UUID

    @ObservedObject var store: StudentMemoStore

    @State private var title = ""
    @State private var bodyText = ""
    @State private var markerRanges: [StudentMemoMarkerRange] = []
    @State private var selectedRange = NSRange(location: 0, length: 0)
    @State private var hasLoaded = false

    var body: some View {
        VStack(spacing: 0) {

            TextField("タイトル", text: $title)
                .font(.title2.bold())
                .padding(.horizontal)
                .padding(.top, 12)
                .padding(.bottom, 10)

            Divider()

            // MARK: - Marker Toolbar

            HStack(spacing: 14) {

                Image(systemName: "highlighter")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                ForEach(
                    StudentMemoMarkerColor.allCases,
                    id: \.self
                ) { color in

                    Button {
                        applyMarker(color)
                    } label: {
                        Circle()
                            .fill(markerDisplayColor(color))
                            .frame(width: 24, height: 24)
                            .overlay(
                                Circle()
                                    .stroke(
                                        Color.primary.opacity(0.15),
                                        lineWidth: 1
                                    )
                            )
                    }
                    .buttonStyle(.plain)
                }

                Spacer()

                Button {
                    removeMarker()
                } label: {
                    Image(systemName: "eraser")
                        .font(.title3)
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal)
            .padding(.vertical, 8)

            Divider()

            StudentMemoRichTextEditor(
                text: $bodyText,
                markerRanges: $markerRanges,
                selectedRange: $selectedRange
            )
        }
        .navigationTitle("📝 メモ")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            loadPage()
        }
        .onChange(of: title) {
            savePage()
        }
        .onChange(of: bodyText) {
            savePage()
        }
        .onChange(of: markerRanges) {
            savePage()
        }
    }


    // MARK: - 読み込み

    private func loadPage() {
        guard let page = store.page(id: pageID) else {
            return
        }

        title = page.title
        bodyText = page.body
        markerRanges = page.markerRanges ?? []
        hasLoaded = true
    }


    // MARK: - 自動保存

    private func savePage() {
        guard hasLoaded else {
            return
        }

        store.updatePage(
            id: pageID,
            title: title,
            body: bodyText,
            markerRanges: markerRanges
        )
    }
    
    // MARK: - Marker

    private func applyMarker(
        _ color: StudentMemoMarkerColor
    ) {
        let range = selectedRange

        let fullLength = (bodyText as NSString).length

        guard range.length > 0,
              range.location >= 0,
              NSMaxRange(range) <= fullLength else {
            return
        }

        // 選択範囲にすでにあるマーカーをいったん切り抜く
        var updated = markerRangesRemovingOverlap(
            from: markerRanges,
            with: range
        )

        // 新しい色を追加
        updated.append(
            StudentMemoMarkerRange(
                location: range.location,
                length: range.length,
                color: color
            )
        )

        markerRanges = mergedMarkerRanges(updated)
    }


    private func removeMarker() {
        let range = selectedRange

        guard range.length > 0 else {
            return
        }

        markerRanges = markerRangesRemovingOverlap(
            from: markerRanges,
            with: range
        )
    }


    private func markerRangesRemovingOverlap(
        from ranges: [StudentMemoMarkerRange],
        with target: NSRange
    ) -> [StudentMemoMarkerRange] {

        let targetStart = target.location
        let targetEnd = NSMaxRange(target)

        return ranges.flatMap { marker -> [StudentMemoMarkerRange] in

            let markerStart = marker.location
            let markerEnd = marker.location + marker.length

            // 重なっていない
            if markerEnd <= targetStart
                || markerStart >= targetEnd {
                return [marker]
            }

            var pieces: [StudentMemoMarkerRange] = []

            // 選択範囲より左側を残す
            if markerStart < targetStart {
                pieces.append(
                    StudentMemoMarkerRange(
                        location: markerStart,
                        length: targetStart - markerStart,
                        color: marker.color
                    )
                )
            }

            // 選択範囲より右側を残す
            if markerEnd > targetEnd {
                pieces.append(
                    StudentMemoMarkerRange(
                        location: targetEnd,
                        length: markerEnd - targetEnd,
                        color: marker.color
                    )
                )
            }

            return pieces
        }
    }


    private func mergedMarkerRanges(
        _ ranges: [StudentMemoMarkerRange]
    ) -> [StudentMemoMarkerRange] {

        let sorted = ranges
            .filter { $0.length > 0 }
            .sorted { $0.location < $1.location }

        var result: [StudentMemoMarkerRange] = []

        for marker in sorted {

            guard var last = result.last else {
                result.append(marker)
                continue
            }

            let lastEnd = last.location + last.length
            let markerEnd = marker.location + marker.length

            // 同色で隣接・連続していれば1本にまとめる
            if last.color == marker.color,
               lastEnd >= marker.location {

                last.length =
                    max(lastEnd, markerEnd) - last.location

                result[result.count - 1] = last

            } else {

                result.append(marker)
            }
        }

        return result
    }


    private func markerDisplayColor(
        _ color: StudentMemoMarkerColor
    ) -> Color {

        switch color {
        case .yellow:
            return Color(
                red: 1.00,
                green: 0.82,
                blue: 0.28
            )

        case .pink:
            return Color(
                red: 1.00,
                green: 0.48,
                blue: 0.62
            )

        case .green:
            return Color(
                red: 0.38,
                green: 0.84,
                blue: 0.55
            )

        case .blue:
            return Color(
                red: 0.38,
                green: 0.70,
                blue: 1.00
            )

        case .purple:
            return Color(
                red: 0.78,
                green: 0.52,
                blue: 1.00
            )
        }
    }
}
