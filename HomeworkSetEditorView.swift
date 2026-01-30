//
//  HomeworkSetEditorView.swift
//  WordsForest
//
//  Created by Nami .T on 2026/01/25.→01/30.note1つ版に変更
//

import SwiftUI

// =======================================================
// MARK: - 宿題セット編集（required + 補充 + 並び順）
// =======================================================

struct HomeworkSetEditorView: View {

    let posA: PartOfSpeech
    let posB: PartOfSpeech
    var targetPerPos: Int = 12

    @Environment(\.dismiss) private var dismiss
    @ObservedObject private var store = HomeworkStore.shared

    // required（順番付き）を UserDefaults に保存するためのDTO
    struct RequiredItem: Identifiable, Codable, Hashable {
        var id = UUID()
        var posRaw: String
        var word: String
        var meaning: String

        var pos: PartOfSpeech { PartOfSpeech(rawValue: posRaw) ?? .others }

        init(pos: PartOfSpeech, word: String, meaning: String) {
            self.posRaw = pos.rawValue
            self.word = word
            self.meaning = meaning
        }
    }

    // 画面上のドラフト（順番つき）
    @State private var requiredA: [RequiredItem] = []
    @State private var requiredB: [RequiredItem] = []

    // 検索
    @State private var queryA: String = ""
    @State private var queryB: String = ""

    // プレビュー（補充後の確定イメージ）
    @State private var previewA: [WordCard] = []
    @State private var previewB: [WordCard] = []

    // ===== 保存後フロー用 =====
    @State private var showPostSavePrompt = false
    @State private var isBulkEditing = false
    @State private var bulkQueue: [WordCard] = []
    @State private var bulkIndex: Int = 0
    @State private var editingCard: WordCard? = nil

    // 保存しましたバナー（任意）
    @State private var showSavedBanner = false
    @State private var savedBannerText = "保存しました"

    // 保存キー（posペアごとに保存）
    private var orderKeyA: String { "required_order_v1_\(posA.rawValue)_\(posB.rawValue)_A" }
    private var orderKeyB: String { "required_order_v1_\(posA.rawValue)_\(posB.rawValue)_B" }

    var body: some View {
        NavigationStack {
            List {
                Section("🧷 必須（\(posA.displayName)）※並べ替え可") {
                    requiredListSection(required: $requiredA, pos: posA)
                }

                Section("➕ 追加（\(posA.displayName)）") {
                    pickerSection(pos: posA, query: $queryA, required: $requiredA)
                }

                Section("🧷 必須（\(posB.displayName)）※並べ替え可") {
                    requiredListSection(required: $requiredB, pos: posB)
                }

                Section("➕ 追加（\(posB.displayName)）") {
                    pickerSection(pos: posB, query: $queryB, required: $requiredB)
                }

                Section("👀 プレビュー（自動補充後）") {
                    if previewA.isEmpty && previewB.isEmpty {
                        Text("まだプレビューがありません。下の「プレビュー更新」を押してください。")
                            .foregroundStyle(.secondary)
                    } else {
                        previewBlock(title: "\(posA.displayName) \(previewA.count)語", cards: previewA)
                        previewBlock(title: "\(posB.displayName) \(previewB.count)語", cards: previewB)
                        Text("合計 \(previewA.count + previewB.count)語")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .navigationTitle("宿題セットを編集")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("閉じる") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("保存") {
                        // ① required順を保存
                        saveRequiredOrder()

                        // ②（任意）storeの required(Set) へ反映したいならここで反映
                        applyRequiredFlagsToStore()

                        // ✅ 保存後フロー開始（dismissはしない）
                        afterSaveTapped()
                    }
                }
            }
            .safeAreaInset(edge: .bottom) {
                bottomBar
            }
            .onAppear {
                loadRequiredOrder()
            }
        }

        // ✅ 保存後：編集する？の確認
        .alert("カード裏面を編集しますか？", isPresented: $showPostSavePrompt) {
            Button("する") { startBulkEditing() }
            Button("あとで") { dismiss() }
        } message: {
            Text("この宿題セットに入った単語の例文などを、順番に編集できます。")
        }

        // ✅ 既存の編集画面に統一（pen & square と同じ場所へ）
        .sheet(item: $editingCard) { card in
            ExampleEditorView(pos: card.pos, word: card.word)
        }

        // ✅ iOS17+ 推奨：シグネチャ（黄色⚠️を消す）
        .onChange(of: editingCard) { _, newValue in
            // シートが閉じた（nilに戻った）タイミングで次へ
            guard newValue == nil, isBulkEditing else { return }
            advanceBulkEditingIfNeeded()
        }

        // ✅ 保存しましたバナー
        .overlay(alignment: .top) {
            if showSavedBanner {
                Text(savedBannerText)
                    .font(.callout)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .background(.ultraThinMaterial, in: Capsule())
                    .padding(.top, 12)
            }
        }
    }

    // =======================================================
    // MARK: - 保存後フロー
    // =======================================================

    private func afterSaveTapped() {
        // まず「保存しました」を見せる
        savedBannerText = "保存しました"
        showSavedBannerNow()

        // ここは「確定セット」なので、最新プレビューを作ってから使う
        updatePreview()

        let finalCards = previewA + previewB
        guard !finalCards.isEmpty else {
            dismiss()
            return
        }

        bulkQueue = finalCards
        bulkIndex = 0
        showPostSavePrompt = true
    }

    private func startBulkEditing() {
        isBulkEditing = true
        bulkIndex = 0
        editingCard = bulkQueue.first
    }

    private func advanceBulkEditingIfNeeded() {
        guard isBulkEditing else { return }

        let next = bulkIndex + 1
        if next < bulkQueue.count {
            bulkIndex = next
            editingCard = bulkQueue[next]
        } else {
            isBulkEditing = false
            savedBannerText = "編集が完了しました"
            showSavedBannerNow()
            dismiss()
        }
    }

    private func showSavedBannerNow() {
        showSavedBanner = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
            showSavedBanner = false
        }
    }

    // =======================================================
    // MARK: UI parts
    // =======================================================

    private var bottomBar: some View {
        HStack(spacing: 12) {
            Button {
                updatePreview()
            } label: {
                Label("プレビュー更新", systemImage: "arrow.triangle.2.circlepath")
            }
            .buttonStyle(.borderedProminent)

            Button(role: .destructive) {
                requiredA.removeAll()
                requiredB.removeAll()
                previewA = []
                previewB = []
                saveRequiredOrder()
                // storeのrequired(Set)もクリアしたければ下も呼ぶ
                // clearRequiredFlagsInStore()
            } label: {
                Label("必須をクリア", systemImage: "trash")
            }
            .buttonStyle(.bordered)
        }
        .padding(.horizontal)
        .padding(.vertical, 10)
        .background(.ultraThinMaterial)
    }

    private func requiredListSection(required: Binding<[RequiredItem]>, pos: PartOfSpeech) -> some View {
        let items = required.wrappedValue

        return VStack(alignment: .leading, spacing: 8) {
            if items.isEmpty {
                Text("まだ必須がありません。下のリストから追加してください。")
                    .foregroundStyle(.secondary)
            } else {
                ForEach(items) { it in
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(it.word).font(.headline)
                            Text(it.meaning).font(.footnote).foregroundStyle(.secondary)
                        }
                        Spacer()
                        Button {
                            removeRequired(it, from: pos)
                        } label: {
                            Image(systemName: "minus.circle.fill")
                                .foregroundStyle(.red)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .onMove { from, to in
                    required.wrappedValue.move(fromOffsets: from, toOffset: to)
                }
            }
        }
    }

    private func pickerSection(pos: PartOfSpeech,
                               query: Binding<String>,
                               required: Binding<[RequiredItem]>) -> some View {
        let all = store.list(for: pos)
        let filtered = all.filter { c in
            let q = query.wrappedValue.trimmingCharacters(in: .whitespacesAndNewlines)
            if q.isEmpty { return true }
            let w = c.word.lowercased()
            let m = (c.meanings.first ?? "").lowercased()
            return w.contains(q.lowercased()) || m.contains(q.lowercased())
        }

        return VStack(alignment: .leading, spacing: 8) {
            TextField("検索（word / meaning）", text: query)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()

            ForEach(filtered, id: \.id) { c in
                Button {
                    addRequired(from: c, into: pos)
                } label: {
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(c.word).font(.body)
                            Text(c.meanings.first ?? "")
                                .font(.footnote)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                        Image(systemName: "plus.circle")
                    }
                }
                .buttonStyle(.plain)
            }

            if filtered.isEmpty {
                Text("該当がありません")
                    .foregroundStyle(.secondary)
            }
        }
    }

    private func previewBlock(title: String, cards: [WordCard]) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title).font(.headline)
            ForEach(cards) { c in
                Text("• \(c.word) — \(c.meanings.first ?? "")")
                    .font(.footnote)
            }
        }
        .padding(.vertical, 4)
    }

    // =======================================================
    // MARK: required操作
    // =======================================================

    private func addRequired(from card: WordCard, into pos: PartOfSpeech) {
        let w = card.word.trimmingCharacters(in: .whitespacesAndNewlines)
        let m = (card.meanings.first ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        let item = RequiredItem(pos: pos, word: w, meaning: m)

        if pos == posA {
            if !requiredA.contains(where: { same($0, item) }) { requiredA.append(item) }
        } else if pos == posB {
            if !requiredB.contains(where: { same($0, item) }) { requiredB.append(item) }
        }
    }

    private func removeRequired(_ item: RequiredItem, from pos: PartOfSpeech) {
        if pos == posA { requiredA.removeAll { same($0, item) } }
        if pos == posB { requiredB.removeAll { same($0, item) } }
    }

    private func same(_ a: RequiredItem, _ b: RequiredItem) -> Bool {
        a.posRaw == b.posRaw &&
        a.word.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        == b.word.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() &&
        a.meaning.trimmingCharacters(in: .whitespacesAndNewlines)
        == b.meaning.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    // =======================================================
    // MARK: プレビュー作成（required + 補充）
    // =======================================================

    private func updatePreview() {
        previewA = buildDeck(pos: posA, required: requiredA, target: targetPerPos)
        previewB = buildDeck(pos: posB, required: requiredB, target: targetPerPos)
    }

    private func buildDeck(pos: PartOfSpeech, required: [RequiredItem], target: Int) -> [WordCard] {
        let all = store.list(for: pos)

        // required順でまず確定
        var result: [WordCard] = []
        for r in required {
            if let hit = all.first(where: { isSameCard($0, r) }) {
                if !result.contains(hit) { result.append(hit) }
            }
        }

        // 足りない分を補充（順番は安定ソート）
        if result.count < target {
            let existingWords = Set(result.map { $0.word.lowercased() })
            let fillers = all.filter { !existingWords.contains($0.word.lowercased()) }
            let stable = fillers.sorted { $0.word.lowercased() < $1.word.lowercased() }

            for c in stable {
                result.append(c)
                if result.count >= target { break }
            }
        }

        // requiredが多い場合は target超え → そのまま返す
        return result
    }

    private func isSameCard(_ c: WordCard, _ r: RequiredItem) -> Bool {
        let w1 = c.word.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        let w2 = r.word.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        let m1 = (c.meanings.first ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        let m2 = r.meaning.trimmingCharacters(in: .whitespacesAndNewlines)
        return (w1 == w2 && m1 == m2)
    }

    // =======================================================
    // MARK: 永続化（順番つき required）
    // =======================================================

    private func loadRequiredOrder() {
        requiredA = loadArray(key: orderKeyA)
        requiredB = loadArray(key: orderKeyB)
    }

    private func saveRequiredOrder() {
        saveArray(requiredA, key: orderKeyA)
        saveArray(requiredB, key: orderKeyB)
    }

    private func loadArray(key: String) -> [RequiredItem] {
        guard let data = UserDefaults.standard.data(forKey: key),
              let arr = try? JSONDecoder().decode([RequiredItem].self, from: data)
        else { return [] }
        return arr
    }

    private func saveArray(_ arr: [RequiredItem], key: String) {
        guard let data = try? JSONEncoder().encode(arr) else { return }
        UserDefaults.standard.set(data, forKey: key)
    }

    // =======================================================
    // MARK: HomeworkStore の required(Set) へ反映（必要なら）
    // =======================================================

    private func applyRequiredFlagsToStore() {
        applyRequiredFor(pos: posA, required: requiredA)
        applyRequiredFor(pos: posB, required: requiredB)
    }

    private func applyRequiredFor(pos: PartOfSpeech, required: [RequiredItem]) {
        let all = store.list(for: pos)

        // いったん全部OFF
        for c in all { store.setRequired(c, enabled: false) }

        // requiredだけON
        for r in required {
            if let hit = all.first(where: { isSameCard($0, r) }) {
                store.setRequired(hit, enabled: true)
            }
        }
    }

    private func clearRequiredFlagsInStore() {
        [posA, posB].forEach { pos in
            store.list(for: pos).forEach { store.setRequired($0, enabled: false) }
        }
    }
}

// =======================================================
// MARK: - PartOfSpeech 表示名（なければここで付ける）
// =======================================================

private extension PartOfSpeech {
    var displayName: String {
        switch self {
        case .noun: return "名詞"
        case .verb: return "動詞"
        case .adj: return "形容詞"
        case .adv: return "副詞"
        case .others: return "その他"
        }
    }
}

#Preview {
    HomeworkSetEditorView(posA: .verb, posB: .adv)
}
