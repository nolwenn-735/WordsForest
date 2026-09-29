//
//  StudentMemoRichTextEditor.swift
//  WordsForest
//
//  Created by Nami .T on 2026/09/29.
//

import SwiftUI
import UIKit

struct StudentMemoRichTextEditor: UIViewRepresentable {

    @Binding var text: String
    @Binding var markerRanges: [StudentMemoMarkerRange]
    @Binding var selectedRange: NSRange

    func makeCoordinator() -> Coordinator {
        Coordinator(parent: self)
    }

    func makeUIView(context: Context) -> UITextView {
        let textView = UITextView()

        textView.delegate = context.coordinator
        textView.backgroundColor = .clear
        textView.isEditable = true
        textView.isSelectable = true
        textView.alwaysBounceVertical = true

        textView.font = UIFont.preferredFont(forTextStyle: .body)
        textView.adjustsFontForContentSizeCategory = true

        textView.textContainerInset = UIEdgeInsets(
            top: 8,
            left: 8,
            bottom: 8,
            right: 8
        )

        applyAttributedText(
            to: textView,
            text: text,
            markerRanges: markerRanges,
            preserving: selectedRange
        )

        context.coordinator.lastAppliedMarkerRanges = markerRanges

        return textView
    }

    func updateUIView(
        _ textView: UITextView,
        context: Context
    ) {
        context.coordinator.parent = self

        // 日本語変換中はSwiftUI側から書き換えない
        guard textView.markedTextRange == nil else {
            return
        }

        let currentText = textView.text ?? ""

        if currentText != text
            || context.coordinator.lastAppliedMarkerRanges != markerRanges {

            context.coordinator.isApplyingProgrammaticUpdate = true

            applyAttributedText(
                to: textView,
                text: text,
                markerRanges: markerRanges,
                preserving: selectedRange
            )

            context.coordinator.isApplyingProgrammaticUpdate = false
            context.coordinator.workingMarkerRanges = markerRanges
            context.coordinator.lastAppliedMarkerRanges = markerRanges
            context.coordinator.lastKnownText = text
        }
    }

    private func applyAttributedText(
        to textView: UITextView,
        text: String,
        markerRanges: [StudentMemoMarkerRange],
        preserving selection: NSRange
    ) {
        let attributed = NSMutableAttributedString(string: text)

        let fullLength = (text as NSString).length

        if fullLength > 0 {
            let fullRange = NSRange(
                location: 0,
                length: fullLength
            )

            attributed.addAttributes(
                [
                    .font: UIFont.preferredFont(forTextStyle: .body),
                    .foregroundColor: UIColor.label
                ],
                range: fullRange
            )
        }

        for marker in markerRanges {
            let range = NSRange(
                location: marker.location,
                length: marker.length
            )

            guard range.location >= 0,
                  range.length > 0,
                  NSMaxRange(range) <= fullLength else {
                continue
            }

            attributed.addAttribute(
                .backgroundColor,
                value: uiColor(for: marker.color),
                range: range
            )
        }

        textView.attributedText = attributed

        let safeLocation = min(
            selection.location,
            fullLength
        )

        let safeLength = min(
            selection.length,
            max(0, fullLength - safeLocation)
        )

        textView.selectedRange = NSRange(
            location: safeLocation,
            length: safeLength
        )
    }

    private func uiColor(
        for color: StudentMemoMarkerColor
    ) -> UIColor {

        switch color {

        case .yellow:
            return UIColor(
                red: 1.00,
                green: 0.82,
                blue: 0.28,
                alpha: 0.58
            )

        case .pink:
            return UIColor(
                red: 1.00,
                green: 0.48,
                blue: 0.62,
                alpha: 0.52
            )

        case .green:
            return UIColor(
                red: 0.38,
                green: 0.84,
                blue: 0.55,
                alpha: 0.50
            )

        case .blue:
            return UIColor(
                red: 0.38,
                green: 0.70,
                blue: 1.00,
                alpha: 0.52
            )

        case .purple:
            return UIColor(
                red: 0.78,
                green: 0.52,
                blue: 1.00,
                alpha: 0.50
            )
        }
    }


    // MARK: - Coordinator

    final class Coordinator: NSObject, UITextViewDelegate {

        var parent: StudentMemoRichTextEditor

        // 現在の本文に対応する最新のマーカー座標
        var workingMarkerRanges: [StudentMemoMarkerRange] = []

        var lastAppliedMarkerRanges: [StudentMemoMarkerRange] = []

        // 直前にUITextViewに実在していた本文
        var lastKnownText: String

        // SwiftUI側からUITextViewを書き換えている最中かどうか
        var isApplyingProgrammaticUpdate = false

        init(parent: StudentMemoRichTextEditor) {
            self.parent = parent
            self.workingMarkerRanges = parent.markerRanges
            self.lastAppliedMarkerRanges = parent.markerRanges
            self.lastKnownText = parent.text
        }
        
        func textViewDidChange(
            _ textView: UITextView
        ) {
            guard !isApplyingProgrammaticUpdate else {
                return
            }

            let newText = textView.text ?? ""

            // 「変更前」と「実際に変更された後」の本文を比較して、
            // 本当に増減した位置と長さを求める
            if let edit = textEdit(
                from: lastKnownText,
                to: newText
            ) {
                workingMarkerRanges = adjustedMarkerRanges(
                    workingMarkerRanges,
                    replacing: edit.range,
                    replacementLength: edit.replacementLength
                )
            }

            // 次の編集に備えて、実際の最新本文を保持
            lastKnownText = newText

            let newMarkerRanges = workingMarkerRanges
            let newSelection = textView.selectedRange

            DispatchQueue.main.async { [weak self] in
                guard let self else { return }

                self.parent.text = newText
                self.parent.markerRanges = newMarkerRanges
                self.parent.selectedRange = newSelection
            }
        }


        func textViewDidChangeSelection(
            _ textView: UITextView
        ) {
            guard !isApplyingProgrammaticUpdate else {
                return
            }

            let range = textView.selectedRange

            // マーカー用には「最後に実際に選択した範囲」を保持する。
            // ツールバーをタップした瞬間に選択が0へ戻っても、
            // 選んでいた文字範囲を失わないようにする。
            guard range.length > 0 else {
                return
            }

            DispatchQueue.main.async { [weak self] in
                self?.parent.selectedRange = range
            }
        }

        private func textEdit(
            from oldText: String,
            to newText: String
        ) -> (
            range: NSRange,
            replacementLength: Int
        )? {

            let oldUnits = Array(oldText.utf16)
            let newUnits = Array(newText.utf16)

            // 先頭から同じ部分を探す
            var prefix = 0

            while prefix < oldUnits.count,
                  prefix < newUnits.count,
                  oldUnits[prefix] == newUnits[prefix] {
                prefix += 1
            }

            // 末尾から同じ部分を探す
            var oldEnd = oldUnits.count
            var newEnd = newUnits.count

            while oldEnd > prefix,
                  newEnd > prefix,
                  oldUnits[oldEnd - 1] == newUnits[newEnd - 1] {
                oldEnd -= 1
                newEnd -= 1
            }

            let removedLength = oldEnd - prefix
            let insertedLength = newEnd - prefix

            guard removedLength > 0 || insertedLength > 0 else {
                return nil
            }

            return (
                range: NSRange(
                    location: prefix,
                    length: removedLength
                ),
                replacementLength: insertedLength
            )
        }
        
        private func adjustedMarkerRanges(
            _ ranges: [StudentMemoMarkerRange],
            replacing editedRange: NSRange,
            replacementLength: Int
        ) -> [StudentMemoMarkerRange] {

            let editStart = editedRange.location
            let editEnd = NSMaxRange(editedRange)

            let delta =
                replacementLength - editedRange.length

            return ranges.compactMap { marker in

                let markerStart = marker.location
                let markerEnd =
                    marker.location + marker.length

                // 編集位置より完全に前
                if markerEnd <= editStart {
                    return marker
                }

                // 編集位置より完全に後ろ
                if markerStart >= editEnd {
                    var shifted = marker
                    shifted.location += delta
                    return shifted
                }

                // マーカー範囲と編集箇所が重なっている
                let newStart: Int

                if markerStart < editStart {
                    newStart = markerStart
                } else {
                    newStart = editStart
                }

                let newEnd: Int

                if markerEnd > editEnd {
                    newEnd = markerEnd + delta
                } else {
                    newEnd = editStart + replacementLength
                }

                let newLength =
                    max(0, newEnd - newStart)

                guard newLength > 0 else {
                    return nil
                }

                return StudentMemoMarkerRange(
                    location: newStart,
                    length: newLength,
                    color: marker.color
                )
            }
        }
    }
}
