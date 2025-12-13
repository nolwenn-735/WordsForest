//
//  TeacherMode.swift
//  WordsForest
//
//  Created by Nami .T on 2025/12/14.
//

import SwiftUI
import CryptoKit

@MainActor
final class TeacherMode: ObservableObject {
    static let shared = TeacherMode()

    @Published var unlocked: Bool = false
    @Published var showingUnlockSheet: Bool = false

    private let passHashKey = "teacherPassHash.v1"
    private var pendingAction: (() -> Void)?

    private init() {
        // 初回だけデフォルト暗証（例：0000）をセット
        if UserDefaults.standard.string(forKey: passHashKey) == nil {
            UserDefaults.standard.set(hash("0000"), forKey: passHashKey)
        }
    }

    /// ロック解除を要求（ロック中ならシートを出す。解除済みなら即 action 実行）
    func requestUnlock(runAfterUnlock action: (() -> Void)? = nil) {
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
    }

    /// 入力コードで解除を試みる（成功したら pendingAction を実行）
    @discardableResult
    func tryUnlock(code: String) -> Bool {
        let stored = UserDefaults.standard.string(forKey: passHashKey) ?? ""
        let ok = (hash(code) == stored)
        if ok {
            unlocked = true
            showingUnlockSheet = false

            let a = pendingAction
            pendingAction = nil
            a?()
        }
        return ok
    }

    /// ✅ これは消さなくていい（先生が後で変更したいなら残す）
    /// ただし「ロック解除中だけ呼ぶ」運用にしてね
    func setPasscode(_ newCode: String) {
        UserDefaults.standard.set(hash(newCode), forKey: passHashKey)
    }

    private func hash(_ s: String) -> String {
        let data = Data(s.utf8)
        let digest = SHA256.hash(data: data)
        return digest.map { String(format: "%02x", $0) }.joined()
    }
}

// MARK: - Unlock Sheet

struct TeacherUnlockSheet: View {
    @EnvironmentObject private var teacher: TeacherMode
    @State private var code: String = ""
    @State private var showError = false

    var body: some View {
        NavigationStack {
            Form {
                Section("Teacher ロック解除") {
                    SecureField("パスコード", text: $code)
                        .textContentType(.oneTimeCode)
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
