//
//  HomeworkSetEditorView.swift
//  WordsForest
//
//  Created by Nami .T on 2026/01/25.→01/30.note1つ版に変更
//
//  HomeworkSetEditorView.swift

import SwiftUI

// =======================================================
// MARK: - 宿題セット編集（required + 補充 + 並び順）
// =======================================================

struct HomeworkSetEditorView: View {

    let posA: PartOfSpeech
    let posB: PartOfSpeech
    let cycleOffset: Int

    init(
        posA: PartOfSpeech,
        posB: PartOfSpeech,
        cycleOffset: Int = 1
    ) {
        self.posA = posA
        self.posB = posB
        self.cycleOffset = cycleOffset
    }

    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var hw: HomeworkState

    private var targetPerPos: Int {
        max(1, hw.totalCount / 2)
    }
    @ObservedObject private var store = HomeworkStore.shared
    @Environment(\.colorScheme) private var colorScheme

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
    
    // 必須語の選択上限メッセージ
    @State private var requiredLimitMessage: String? = nil

    // 保存キー（cycle + posペアごとに保存）
    private var orderKeyA: String {
        "required_order_v2_cycle\(targetCycleIndex)_\(posA.rawValue)_\(posB.rawValue)_A"
    }

    private var orderKeyB: String {
        "required_order_v2_cycle\(targetCycleIndex)_\(posA.rawValue)_\(posB.rawValue)_B"
    }
    // 作業途中の下書きキー（中断→再開用）
    // 今回・次回・次々回をcycle番号で区別する
    private var targetCycleIndex: Int {
        hw.currentCycleIndex + cycleOffset
    }

    private var draftKeyA: String {
        "homework_editor_draft_v2_cycle\(targetCycleIndex)_\(posA.rawValue)_\(posB.rawValue)_A"
    }

    private var draftKeyB: String {
        "homework_editor_draft_v2_cycle\(targetCycleIndex)_\(posA.rawValue)_\(posB.rawValue)_B"
    }

    private var preparedFollowingDraftPair: PosPair? {
        let editingPair: PosPair

        if posA == .noun && posB == .adj {
            editingPair = .nounAdj
        } else if posA == .verb && posB == .adv {
            editingPair = .verbAdv
        } else {
            return nil
        }

        // 「次回分」を編集中のときだけ、次々回の作り置きを確認する
        guard cycleOffset == 1,
              editingPair == hw.currentPair.next else {
            return nil
        }

        let followingPair = editingPair.next
        let followingCycleIndex = targetCycleIndex + 1

        guard HomeworkPackStore.shared.loadDraft(
            cycleIndex: followingCycleIndex,
            pair: followingPair
        ) != nil else {
            return nil
        }

        return followingPair
    }
    var body: some View {
        NavigationStack {
            List {

                if let pair = preparedFollowingDraftPair {
                    Section {
                        VStack(alignment: .leading, spacing: 6) {
                            Text("次々回分（\(pair.jaTitle)）は編集済みです。")
                                .font(.subheadline.weight(.semibold))

                            Text("品詞ペアは交互に出題されます。次回分から順に使用してください。")
                                .font(.footnote)
                                .foregroundStyle(.secondary)
                        }
                        .padding(.vertical, 4)
                    }
                }

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
                            .font(.footnote)
                            .padding(.vertical, 4)
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
                        
                        // ✅ 正式保存できたので、作業途中ドラフトは削除
                        clearEditorDraft()


                        // ✅ 保存後フロー開始（dismissはしない）
                        afterSaveTapped()
                    }
                }
            }
            .safeAreaInset(edge: .bottom) {
                bottomBar
            }
            .onAppear {
                loadEditorDraftIfNeeded()
            }
            .onChange(of: requiredA) { _, _ in
                saveEditorDraft()
            }
            .onChange(of: requiredB) { _, _ in
                saveEditorDraft()
            }
        }

        // ✅ 必須語の選択上限
        .alert(
            "選択できる語数の上限です",
            isPresented: Binding(
                get: { requiredLimitMessage != nil },
                set: { if !$0 { requiredLimitMessage = nil } }
            )
        ) {
            Button("OK", role: .cancel) {
                requiredLimitMessage = nil
            }
        } message: {
            Text(requiredLimitMessage ?? "")
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
        saveDraftForEditedPair(from: finalCards)
        
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

    private func saveDraftForEditedPair(from cards: [WordCard]) {

        guard !cards.isEmpty else {
            #if DEBUG
            print("⚠️ draft save skipped: cards empty")
            #endif
            return
        }

        let editPair: PosPair
        if posA == .noun && posB == .adj {
            editPair = .nounAdj
        } else if posA == .verb && posB == .adv {
            editPair = .verbAdv
        } else {
            #if DEBUG
            print("⚠️ draft save skipped: unsupported pos pair \(posA.rawValue)+\(posB.rawValue)")
            #endif
            return
        }


        guard let draft = HomeworkPackStore.shared.makeDraftPayload(
            hw: hw,
            pair: editPair,
            cards: cards,
            targetCycleIndex: targetCycleIndex,
            requiredCount: cards.filter {
                HomeworkStore.shared.isRequired($0)
            }.count,
            totalCount: cards.count
        ) else {
            #if DEBUG
            print("❌ makeDraftPayload returned nil")
            #endif
            return
        }

        if cycleOffset == 0 {
            // ⚠️ 今回分を修正 → 正式固定パックへ上書き
            HomeworkPackStore.shared.saveEditedCurrentPack(
                draft,
                cycleIndex: targetCycleIndex,
                pair: editPair
            )
        } else {
            // 次回・次々回 → cycle + pair のドラフト棚へ保存
            HomeworkPackStore.shared.saveDraft(
                draft,
                cycleIndex: targetCycleIndex,
                pair: editPair
            )
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
                    .font(.callout.weight(.semibold))
                    .foregroundStyle(.blue)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .fill(Color(.secondarySystemBackground))
                    )
            }
            .buttonStyle(.plain)

            Button(role: .destructive) {
                requiredA.removeAll()
                requiredB.removeAll()
                previewA = []
                previewB = []
                saveRequiredOrder()
                // storeのrequired(Set)もクリアしたければ下も呼ぶ
                // clearRequiredFlagsInStore()
            } label: {
                Label("必須選択をクリア", systemImage: "trash")
                    .font(.callout.weight(.semibold))
                    .foregroundStyle(.red)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .fill(Color(.secondarySystemBackground))
                    )
            }
            .buttonStyle(.plain)
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

            // すでに必須に入っているカードは追加候補から除外
            let alreadyRequired = required.wrappedValue.contains { r in
                isSameCard(c, r)
            }

            if alreadyRequired {
                return false
            }

            // 検索文字で絞り込み
            let q = query.wrappedValue
                .trimmingCharacters(in: .whitespacesAndNewlines)
                .lowercased()

            if q.isEmpty {
                return true
            }

            let w = c.word.lowercased()
            let m = (c.meanings.first ?? "").lowercased()

            return w.contains(q) || m.contains(q)
        }


        return VStack(alignment: .leading, spacing: 8) {
            TextField("検索（word / meaning）", text: query)
                .textFieldStyle(.plain)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .foregroundStyle(colorScheme == .dark ? .white : .primary)
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(colorScheme == .dark
                              ? Color(red: 0.16, green: 0.16, blue: 0.17)
                              : Color(.secondarySystemBackground))
                )

            ForEach(filtered) { c in
                pickerCandidateRow(c: c, pos: pos)
            }

            if filtered.isEmpty {
                Text("該当がありません")
                    .foregroundStyle(.secondary)
            }
        }
    }

    @ViewBuilder
    private func pickerCandidateRow(c: WordCard, pos: PartOfSpeech) -> some View {
        let firstMeaning = (c.meanings.first ?? "").trimmingCharacters(in: .whitespacesAndNewlines)

        let hasExample: Bool = {
            guard !firstMeaning.isEmpty else { return false }
            return ExampleStore.shared.firstExample(pos: c.pos, word: c.word, meaning: firstMeaning) != nil
        }()

        let hasWordNote: Bool = {
            let note = ExampleStore.shared.wordNote(pos: c.pos, word: c.word)
                .trimmingCharacters(in: .whitespacesAndNewlines)
            return !note.isEmpty
        }()


        
        Button {
            addRequired(from: c, into: pos)
        } label: {
            HStack(alignment: .center, spacing: 10) {
                VStack(alignment: .leading, spacing: 3) {
                    HStack(spacing: 6) {
                        Text(c.word)
                            .font(.body)
                            .foregroundStyle(.primary)

                        if hasExample {
                            Image(systemName: "text.quote")
                                .font(.caption)
                                .foregroundStyle(.blue)
                                .accessibilityLabel("例文あり")
                        }

                        if hasWordNote {
                            Image(systemName: "note.text")
                                .font(.caption)
                                .foregroundStyle(.orange)
                                .accessibilityLabel("ノートあり")
                        }
                    }

                    Text(c.meanings.first ?? "")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Image(systemName: "plus.circle")
                    .foregroundStyle(.primary)
            }
        }
        .buttonStyle(.plain)
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

            // 同じカードなら何もしない
            guard !requiredA.contains(where: { same($0, item) }) else {
                return
            }

            // この品詞の上限を超えない
            guard requiredA.count < targetPerPos else {
                requiredLimitMessage = "\(pos.jaTitle)は\(targetPerPos)語まで選択できます。"
                return
            }

            requiredA.append(item)

        } else if pos == posB {

            // 同じカードなら何もしない
            guard !requiredB.contains(where: { same($0, item) }) else {
                return
            }

            // この品詞の上限を超えない
            guard requiredB.count < targetPerPos else {
                requiredLimitMessage = "\(pos.jaTitle)は\(targetPerPos)語まで選択できます。"
                return
            }

            requiredB.append(item)
        }
    }

    private func removeRequired(_ item: RequiredItem, from pos: PartOfSpeech) {
        if pos == posA {
            requiredA.removeAll { same($0, item) }
        }

        if pos == posB {
            requiredB.removeAll { same($0, item) }
        }
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
    
    private func loadSavedPreviewIfAvailable() {
        let editPair: PosPair

        if posA == .noun && posB == .adj {
            editPair = .nounAdj
        } else if posA == .verb && posB == .adv {
            editPair = .verbAdv
        } else {
            return
        }

        let payload: HomeworkExportPayload?

        if cycleOffset == 0 {
            payload = HomeworkPackStore.shared.load(
                cycleIndex: targetCycleIndex,
                pair: editPair
            )
        } else {
            payload = HomeworkPackStore.shared.loadDraft(
                cycleIndex: targetCycleIndex,
                pair: editPair
            )
        }

        guard let payload else {
            return
        }

        var restoredA: [WordCard] = []
        var restoredB: [WordCard] = []

        for item in payload.items {
            guard let itemPos = PartOfSpeech(rawValue: item.pos),
                  let card = HomeworkStore.shared.card(
                    word: item.word,
                    meanings: item.meanings,
                    pos: itemPos
                  )
            else {
                continue
            }

            if itemPos == posA {
                restoredA.append(card)
            } else if itemPos == posB {
                restoredB.append(card)
            }
        }

        if !restoredA.isEmpty || !restoredB.isEmpty {
            previewA = restoredA
            previewB = restoredB
        }
    }
    
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
    
    // MARK: - 編集途中ドラフト（中断→再開）

    private func loadEditorDraftIfNeeded() {
        let draftA: [RequiredItem] = loadArray(key: draftKeyA)
        let draftB: [RequiredItem] = loadArray(key: draftKeyB)

        // 編集途中の下書きがあれば、そちらを最優先
        if !draftA.isEmpty || !draftB.isEmpty {
            requiredA = draftA
            requiredB = draftB
        } else {
            // 下書きがなければ、そのcycleの保存済みrequiredを読む
            loadRequiredOrder()

            // 保存済みの確定セットがあれば、previewもそのまま復元
            loadSavedPreviewIfAvailable()
        }
    }

    private func saveEditorDraft() {
        saveArray(requiredA, key: draftKeyA)
        saveArray(requiredB, key: draftKeyB)
    }

    private func clearEditorDraft() {
        UserDefaults.standard.removeObject(forKey: draftKeyA)
        UserDefaults.standard.removeObject(forKey: draftKeyB)
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
