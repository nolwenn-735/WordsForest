//
//  TeacherMode.swift
//  WordsForest
//
//  Created by Nami .T on 2025/12/14.→2026/1/5.→1/12🔒機能変更

//

import SwiftUI
import CryptoKit

@MainActor
final class TeacherMode: ObservableObject {
    static let shared = TeacherMode()

    @Published var unlocked: Bool = false
    @Published var showingUnlockSheet: Bool = false

    private let passHashKey = "teacherPassHash.v1"
    private let unlockUntilKey = "teacherUnlockUntilISO.v1"

    /// 解除の有効時間：60分
    private let unlockDuration: TimeInterval = 60 * 60

    private var pendingAction: (() -> Void)?
    private var autoLockTask: Task<Void, Never>?

    private init(isPreview: Bool = false) {
        guard !isPreview else { return }

        // 初回だけデフォルト暗証（例：0000）をセット
        if UserDefaults.standard.string(forKey: passHashKey) == nil {
            UserDefaults.standard.set(hash("0000"), forKey: passHashKey)
        }

        // アプリ起動時：期限が残っていれば復元
        refreshLockState()
    }

    // MARK: - Public API

    /// ロック解除を要求（解除中なら即 action、期限切れならシート）
    func requestUnlock(runAfterUnlock action: (() -> Void)? = nil) {
        refreshLockState()

        if unlocked {
            action?()
            return
        }
        pendingAction = action
        showingUnlockSheet = true
    }

    func lock() {
        unlocked = false
        pendingAction = nil
        showingUnlockSheet = false

        // 期限を消す
        UserDefaults.standard.removeObject(forKey: unlockUntilKey)

        // 自動ロック予約も停止
        autoLockTask?.cancel()
        autoLockTask = nil
    }

    /// 入力コードで解除（成功したら60分間 unlocked）
    @discardableResult
    func tryUnlock(code: String) -> Bool {
        let stored = UserDefaults.standard.string(forKey: passHashKey) ?? ""
        let ok = (hash(code) == stored)

        if ok {
            unlocked = true
            showingUnlockSheet = false

            // 解除期限を保存
            let until = Date().addingTimeInterval(unlockDuration)
            saveUnlockUntil(until)

            // 期限で自動ロック
            scheduleAutoLock(until: until)

            // 保留していた操作を実行
            let a = pendingAction
            pendingAction = nil
            a?()
        }

        return ok
    }

    /// 先生が暗証番号を変える（運用は「解除中だけ呼ぶ」）
    func setPasscode(_ newCode: String) {
        UserDefaults.standard.set(hash(newCode), forKey: passHashKey)
    }

    /// アプリがアクティブになった時などに呼ぶと安全（任意）
    func refreshLockState() {
        let now = Date()
        guard let until = loadUnlockUntil() else {
            unlocked = false
            return
        }

        if now < until {
            unlocked = true
            scheduleAutoLock(until: until) // 二重予約は中で防ぐ
        } else {
            lock()
        }
    }

    // MARK: - Unlock Until (persist)

    private func saveUnlockUntil(_ date: Date) {
        let iso = ISO8601DateFormatter()
        UserDefaults.standard.set(iso.string(from: date), forKey: unlockUntilKey)
    }

    private func loadUnlockUntil() -> Date? {
        guard let s = UserDefaults.standard.string(forKey: unlockUntilKey) else { return nil }
        return ISO8601DateFormatter().date(from: s)
    }

    // MARK: - Auto lock

    private func scheduleAutoLock(until: Date) {
        // すでに予約があれば張り直さない（雑に増殖させない）
        if autoLockTask != nil { return }

        let seconds = max(0, until.timeIntervalSinceNow)
        autoLockTask = Task { [weak self] in
            // 期限まで待つ
            try? await Task.sleep(nanoseconds: UInt64(seconds * 1_000_000_000))

            guard let self else { return }
            self.autoLockTask = nil
            self.lock()
        }
    }

    // MARK: - Hash

    private func hash(_ s: String) -> String {
        let data = Data(s.utf8)
        let digest = SHA256.hash(data: data)
        return digest.map { String(format: "%02x", $0) }.joined()
    }

    // MARK: - Preview helper

    #if DEBUG
    static func preview(unlocked: Bool = false) -> TeacherMode {
        let t = TeacherMode(isPreview: true)
        t.unlocked = unlocked
        return t
    }
    #endif // DEBUG
}

// MARK: - Unlock Sheet

struct TeacherUnlockSheet: View {
    @EnvironmentObject private var teacher: TeacherMode
    @State private var code: String = ""
    @State private var showError = false

    var body: some View {
        NavigationStack {
            Form {
                Section("Teacher ロック解除（60分）") {
                    SecureField("パスコード", text: $code)
                        .textContentType(.oneTimeCode)
                        .keyboardType(.numberPad)
                }

                if showError {
                    Text("パスコードが違います")
                        .font(.footnote)
                        .foregroundStyle(.red)
                }

                Section {
                    Button("解除") {
                        let ok = teacher.tryUnlock(code: code)
                        showError = !ok
                    }
                    .disabled(code.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)

                    Button("キャンセル", role: .cancel) {
                        teacher.showingUnlockSheet = false
                    }
                }
            }
            .navigationTitle("Teacher")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

// MARK: - Guarded Button

struct GuardedButton<Label: View>: View {
    @EnvironmentObject private var teacher: TeacherMode
    let action: () -> Void
    @ViewBuilder let label: () -> Label

    var body: some View {
        Button {
            teacher.requestUnlock(runAfterUnlock: action)
        } label: {
            label()
        }
    }
}
