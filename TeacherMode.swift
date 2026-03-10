//
//  TeacherMode.swift
//  WordsForest
//
//  Created by Nami .T on 2025/12/14.→2026/1/5.→1/12🔒機能変更→3/11パスコード変更機能追加

//

import SwiftUI
import CryptoKit

@MainActor
final class TeacherMode: ObservableObject {
    static let shared = TeacherMode()

    @Published var unlocked: Bool = false
    @Published var showingUnlockSheet: Bool = false
    @Published var showingChangePasscodeFlow: Bool = false

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
    func tryUnlock(code: String, dismissSheet: Bool = true) -> Bool {
        let stored = UserDefaults.standard.string(forKey: passHashKey) ?? ""
        let ok = (hash(code) == stored)

        if ok {
            unlocked = true

            if dismissSheet {
                showingUnlockSheet = false
            }

            // 解除期限を保存
            let until = Date().addingTimeInterval(unlockDuration)
            saveUnlockUntil(until)

            // 自動ロック予約は張り直す
            autoLockTask?.cancel()
            autoLockTask = nil
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
    func verifyCurrentCode(_ code: String) -> Bool {
        let stored = UserDefaults.standard.string(forKey: passHashKey) ?? ""
        return hash(code) == stored
    }

    func isValidPasscodeFormat(_ code: String) -> Bool {
        code.count == 4 && code.allSatisfy(\.isNumber)
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

    @State private var mode: SheetMode = .unlock

    @State private var currentCode: String = ""
    @State private var newCode: String = ""
    @State private var confirmCode: String = ""

    @State private var changeErrorMessage: String = ""
    @State private var showChangeSuccess = false

    enum SheetMode {
        case unlock
        case menu
        case changePasscode
    }

    var body: some View {
        NavigationStack {
            Form {
                switch mode {
                case .unlock:
                    unlockSection

                case .menu:
                    unlockedMenuSection

                case .changePasscode:
                    changePasscodeSection
                }
            }
            .navigationTitle("Teacher")
            .navigationBarTitleDisplayMode(.inline)
            .onAppear {
                mode = teacher.unlocked ? .menu : .unlock
            }
            .alert("変更しました", isPresented: $showChangeSuccess) {
                Button("OK") {
                    mode = .menu
                    currentCode = ""
                    newCode = ""
                    confirmCode = ""
                    changeErrorMessage = ""
                }
            } message: {
                Text("Teacherパスコードを更新しました。")
            }
        }
    }

    // MARK: - Unlock

    private var unlockSection: some View {
        Group {
            Section("TEACHER ロック解除（60分）") {
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
                    let ok = teacher.tryUnlock(code: code, dismissSheet: false)
                    showError = !ok
                    if ok {
                        mode = .menu
                        code = ""
                    }
                }
                .disabled(code.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)

                Button("キャンセル", role: .cancel) {
                    teacher.showingUnlockSheet = false
                }
            }
        }
    }

    // MARK: - Menu

    private var unlockedMenuSection: some View {
        Group {
            Section {
                Text("Teacher は現在解除中です。")
                    .foregroundStyle(.secondary)
            }

            Section("設定") {
                Button("パスコード変更") {
                    mode = .changePasscode
                    currentCode = ""
                    newCode = ""
                    confirmCode = ""
                    changeErrorMessage = ""
                }

                Button("ロックする", role: .destructive) {
                    teacher.lock()
                }
            }

            Section {
                Button("閉じる") {
                    teacher.showingUnlockSheet = false
                }
            }
        }
    }

    // MARK: - Change Passcode

    private var changePasscodeSection: some View {
        Group {
            Section("現在のパスコード") {
                SecureField("現在の4桁", text: $currentCode)
                    .textContentType(.oneTimeCode)
                    .keyboardType(.numberPad)
            }

            Section("新しいパスコード") {
                SecureField("新しい4桁", text: $newCode)
                    .textContentType(.oneTimeCode)
                    .keyboardType(.numberPad)

                SecureField("確認用にもう一度入力", text: $confirmCode)
                    .textContentType(.oneTimeCode)
                    .keyboardType(.numberPad)
            }

            if !changeErrorMessage.isEmpty {
                Text(changeErrorMessage)
                    .font(.footnote)
                    .foregroundStyle(.red)
            }

            Section {
                Button("変更する") {
                    submitPasscodeChange()
                }
                .disabled(
                    currentCode.isEmpty ||
                    newCode.isEmpty ||
                    confirmCode.isEmpty
                )

                Button("戻る", role: .cancel) {
                    mode = .menu
                }
            }
        }
    }

    // MARK: - Submit

    private func submitPasscodeChange() {
        changeErrorMessage = ""

        guard teacher.verifyCurrentCode(currentCode) else {
            changeErrorMessage = "現在のパスコードが違います"
            return
        }

        guard teacher.isValidPasscodeFormat(newCode) else {
            changeErrorMessage = "新しいパスコードは4桁の数字で入力してください"
            return
        }

        guard newCode == confirmCode else {
            changeErrorMessage = "新しいパスコードが一致しません"
            return
        }

        guard newCode != currentCode else {
            changeErrorMessage = "現在と同じパスコードは使えません"
            return
        }

        teacher.setPasscode(newCode)
        showChangeSuccess = true
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
