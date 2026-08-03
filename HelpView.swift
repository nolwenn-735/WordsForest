//
//  HelpView.swift
//  WordsForest
//
//  Created by Nami .T on 2026/05/25.
//

import SwiftUI

struct HelpView: View {
    var body: some View {
        List {
            Section("単語カードを見る") {
                Text("名詞・動詞・形容詞・副詞など、品詞ごとに単語カードを見られます。")
                Text("カードをタップすると裏面が開き、意味・例文・ノートなどを確認できます。")
                Text("ページ上の品詞名の横の丸印を押すと、カードの英語と日本語をチェンジして学習できます。")
            }

            Section("お気に入りと覚えたBOX") {
                Text("ハートを押すと My Collection に入ります。自分の覚えにくい単語だけ集めて集中的に学習できます。")
                Text("チェックを押すとそのカードは「覚えたBOX」に入り、学習中のページから消えるのでどれだけ覚えたか把握するのに便利です。カードは完全に消去されるわけではありません。Boxをタップすると再び見たり、チェックを外すと学習中のページに戻すことができます。")
            }

            Section("宿題") {
                Text("先生から届いた宿題は、HOMEの「新しい宿題」から確認できます。")

                Text("「今回分へ」を押すと、今の宿題セットを開けます。")

                NavigationLink {
                    StudentHomeworkHelpView()
                } label: {
                    Label(
                        "宿題の受け取り方",
                        systemImage: "tray.and.arrow.down"
                    )
                }
            }

            Section("スペリング・チャレンジ") {
                Text("単語のつづりをゲームで練習できます。")
                Text("アルファベットのタイルを正しい単語になるようにドラッグ＆ドロップしましょう。間違えた単語は、あとで見直すきっかけにできます。")
            }
            
            Section("コラムを読む") {
                Text("コラムでは、単語や文法、発音のちょっとした解説を読めます。長い場合はスクロールして読んでください。")
                Text("HOMEの「コラム」から、コラム一覧を開けます。")
                Text("先生から新しいコラムが届いたときは、「新規取得」からコラムJSON（下で説明）を取り込みます。")
                Text("宿題とは別に、自習や復習の読み物として使えます。")
            }

            Section("表示設定") {
                Text("動物マスコットを表示するかどうかを選べます。")
                Text("不要なときは、マスコットを非表示にできます。")
            }

            Section("先生向け") {
                NavigationLink {
                    TeacherHomeworkHelpView()
                } label: {
                    Label("宿題の出し方", systemImage: "person.text.rectangle")
                }
            }
        }
        .navigationTitle("使い方")
    }
}

// ここから下に追加
struct StudentHomeworkHelpView: View {
    var body: some View {
        List {
            Section("先生から届くもの") {
                Text("新しい宿題が出ると、先生から「新着通知ファイル」と「宿題JSONファイル」が届きます。")
                Text("新着通知ファイルの名前は、wf-manifest.jsonです。")
                Text("AirDrop、メール、LINEなどで送られてきます。")
                Text("宿題の停止・再開・延長など、表示だけが変更される場合は、wf-manifest.jsonだけが届くこともあります。")
            }

            Section("最初に一度だけすること") {
                Text("Words’ Forestを一度起動してください。")
                Text("iphoneにあるファイルというアプリの「このiPhone内」に、WordsForestフォルダが表示されます。")
                Text("iPadでも同様で、ファイルというアプリの「このiPad内」に表示されます。")
            }

            Section("1. ファイルを受け取る") {
                Text("届いた .json ファイルをタップし、iPhoneの「ファイル」アプリに保存します。")
                Text("新しい宿題が届いたときは、wf-manifest.jsonと宿題JSONの両方を保存してください。")
                Text("延長・停止・再開などの変更だけの場合は、wf-manifest.jsonだけを保存します。")
            }

            Section("2. 新着通知ファイルを保存する") {
                Text("wf-manifest.jsonは、ファイルアプリの「このiPhone内 ＞ WordsForest」に保存します。")
                Text("iPadでは「このiPad内 ＞ WordsForest」に保存します。")
                Text("同じ名前のファイルがあると表示されたら、「置き換える」を選択してください。")
                Text("wf-manifest.jsonには、その時点での最新の宿題状態が入っています。")
            }

            Section("3. 宿題JSONを保存する") {
                Text("新しい宿題が出た場合は、その回の日付が入った宿題JSONも保存します。")
                Text("宿題JSONも、原則として「このiPhone内 ＞ WordsForest」に保存してください。")
                Text("通知ファイルと同じWordsForestの中にまとめておいた方が、宿題取得のときに見つけやすくなります。通知や宿題ファイルの容量はとても小さいので、端末の空き容量圧迫の心配はまずありません。")
                Text("しかしiCloud Driveやファイルの扱いに慣れている場合は、宿題JSONのみiCloud Driveへ保存してもかまいません。")
                Text("新着通知に書かれている日付と同じ宿題JSONを使用してください。")
            }

            Section("4. アプリで新着確認する") {
                Text("Words’ Forestを開き、HOMEの「📚新しい宿題」のところの「🔔新着確認」を押します。")
                Text("ファイルを選ぶ画面は開きません。")
                Text("WordsForestフォルダに保存されたwf-manifest.jsonが自動で読み込まれます。")
                Text("新しい宿題や、停止・再開・延長などの変更があると、HOMEの表示が更新されます。")
            }

            Section("5. 新しい宿題を取得する") {
                Text("新しい宿題が表示されたら、HOMEの青い「表示」という文字をタップして履歴欄を開き、中にある「🔵宿題取得」ボタンを押します。")
                Text("ファイルアプリが開いたら、通知と同じ日付の宿題JSONを選びます。")
                Text("取り込みが終わると、「🗓️今回分へ」から宿題を開けます。")
                Text("停止・再開・延長だけが変更された場合は、宿題JSONをもう一度取り込む必要はありません。")
            }

            Section("宿題の期間と延長について") {
                Text("「1週間」または「2週間」は、先生が最初に設定した学習期間です。")
                Text("先生が延長を設定すると、「＋1週延長」または「＋2週延長」と表示されます。")
                Text("延長が解除されると、延長表示は消えます。")
            }

            Section("気をつけること") {
                Text("wf-manifest.jsonは自動読み込みに使うため、iCloud Driveではなく必ず「このiPhone内＞WordsForestフォルダに保存してください。")
                Text("古いwf-manifest.jsonがある場合は、「置き換える」を選択してください。")
                Text("新しい宿題を取得するときは、通知と同じ日付の宿題JSONを選んでください。")
                Text("同じ宿題JSONをもう一度取り込むと、取得済みとして扱われます。")
            }
        }
        .navigationTitle("宿題の受け取り方")
    }
}

struct TeacherHomeworkHelpView: View {
    var body: some View {
        List {
            Section("先生が作るもの") {
                Text("新しい宿題を出すときに作るものは、基本的に2つです。")
                Text("1つめは、単語セットが入った「宿題JSON」です。")
                Text("2つめは、現在の宿題状態を知らせる「新着通知ファイル」です。")
                Text("新着通知ファイルの名前は、wf-manifest.jsonです。")
                Text("この2つを作って生徒に送ります。")
            }

            Section("先生側の基本の流れ") {
                Text("1. 「宿題編集」で、その回に出す単語セットを作ります。")
                Text("2. 「書き出し」で、宿題JSONを書き出します。")
                Text("3. 宿題あり・期間・延長などを確認します。")
                Text("4. 「通知」を押すと、直近の宿題情報が自動入力されます。")
                Text("5. 内容を確認して、wf-manifest.jsonを書き出します。")
                Text("6. 宿題JSONとwf-manifest.jsonの両方を、生徒に送ります。")
            }

            Section("表示だけを変更するとき") {
                Text("行事や休校などで学習期間を延長するときは、「＋1週延長」または「＋2週延長」を設定します。")
                Text("宿題を一時停止するときは「ストップ」、宿題をなくすときは「宿題なし」を設定します。")
                Text("設定を変更したら、新しいwf-manifest.jsonを書き出して生徒に送ります。")
                Text("宿題の単語セット自体が変わらない場合は、宿題JSONをもう一度送る必要はありません。")
            }

            Section("通知ファイルの考え方") {
                Text("wf-manifest.jsonは、前回との差分ではなく、その時点での正しい宿題状態をまとめて伝えるファイルです。")
                Text("宿題あり・停止・宿題なし・1週間・2週間・延長なし・＋1週・＋2週などの現在の設定が入ります。")
                Text("次の宿題を出すときは、その新しい宿題の状態でwf-manifest.jsonを作り直します。")
                Text("過去の延長設定が、次の宿題へ自動で引き継がれることはありません。")
            }

            Section("ファイルの保存について") {
                Text("書き出した宿題JSONとwf-manifest.jsonは、iPhoneやiPadの「ファイル」アプリに保存されます。")
                Text("生徒に送るときは、共有マークをタップし、AirDrop、メール、LINEなどを選択します。")
                Text("生徒には、wf-manifest.jsonと宿題JSONを、原則として「このiPhone内 ＞ WordsForest」に保存してもらいます。")
                Text("wf-manifest.jsonは自動読み込みに必要なため、必ずWordsForestフォルダへ保存してもらいます。")
                Text("宿題JSONは、iCloud Driveを使い慣れている生徒であれば、iCloud Driveへ保存してもかまいません。")
            }

            Section("1. TeacherLockを解除する") {
                Text("HOMEのTeacherボタンから先生用ロックを解除します。")
                Text("ロックを解除すると、宿題編集・書き出し・通知作成などのボタンが表示されます。")
            }

            Section("2. 宿題セットを編集する") {
                Text("「宿題編集」から、その回に出したい単語を選びます。")
                Text("必ず出したい単語は、必須単語として追加します。")
                Text("足りない分は、アプリ内の単語カードから自動で補充されます。")
                Text("単語を選んだら「プレビュー更新」を押し、実際に出題される単語を確認します。")
                Text("確認できたら「保存」を押します。")
                Text("その後「カード裏面を編集しますか？」と表示された場合は、例文やノートを続けて編集できます。")
                Text("途中で閉じても、選んだ必須単語は下書きとして残ります。")
            }

            Section("3. 宿題JSONを書き出す") {
                Text("「書き出し」から、その回の宿題JSONを書き出します。")
                Text("このファイルが、生徒が実際に取り込む宿題セットです。")
                Text("日付と品詞ペアを確認してから書き出してください。")
            }

            Section("4. 新着通知ファイルを作る") {
                Text("宿題JSONを書き出したあとに「通知」を押すと、通知作成画面が開きます。")
                Text("宿題ID・日付・品詞ペア・語数は、直近に書き出した宿題JSONから自動入力されます。")
                Text("宿題状態・基本期間・延長期間には、HOMEで現在選ばれている内容が入ります。")
                Text("内容を確認してから、「通知ファイルを書き出す」を押します。")
                Text("書き出される新着通知ファイルの名前は、wf-manifest.jsonです。")
                Text("宿題IDは、宿題JSONのidと同じ文字列です。例：2026-05-24-draft-pair1")
                Text("ファイル名に .json が付いていても、ID欄には .json を付ける必要はありません。")
                Text("pair0は名詞＋形容詞、pair1は動詞＋副詞を表します。")
            }

            Section("5. 生徒に送る") {
                Text("新しい宿題を出す場合は、宿題JSONとwf-manifest.jsonの両方を送ります。")
                Text("停止・再開・延長などの変更だけの場合は、更新したwf-manifest.jsonだけを送ります。")
                Text("共有マークからAirDrop、メール、LINEなどを選択して送ることができます。")
            }

            Section("6. 生徒側の流れ") {
                Text("生徒はwf-manifest.jsonを「このiPhone内 ＞ WordsForest」に保存し、古いファイルと置き換えます。")
                Text("その後、HOMEの「新着確認」を押します。")
                Text("新着確認ではファイル選択画面は開かず、保存されたwf-manifest.jsonが自動で読み込まれます。")
                Text("新しい宿題がある場合は「宿題取得」を押し、同じ日付の宿題JSONを選びます。")
                Text("取り込みが完了すると、「今回分へ」から宿題を開けます。")
            }

            Section("大切な注意") {
                Text("新しい宿題を配布するときは、wf-manifest.jsonと宿題JSONの日付・IDを一致させてください。")
                Text("通知だけ新しくして宿題JSONが古いままだと、正しく取得できないことがあります。")
                Text("延長・停止・再開だけを変更するときは、宿題IDと宿題JSONを変更する必要はありません。")
                Text("同じ宿題JSONをもう一度取り込むと、取得済みとして扱われます。")
            }

            Section("困ったとき") {
                Text("新着表示が更新されないときは、生徒端末の「このiPhone内 ＞ WordsForest」にwf-manifest.jsonがあるか確認してください。")
                Text("古い通知が表示される場合は、wf-manifest.jsonを置き換えたか確認してください。")
                Text("宿題が開けないときは、通知と同じ日付の宿題JSONを選んでいるか確認してください。")
                Text("必要な場合は、TeacherLock解除後に宿題修復を使います。")
            }

            Section("単語カードを作り置きする") {
                Text("品詞ページの「＋」から、単語カードを追加できます。")
                Text("意味・例文・ノートを先に作っておくと、あとで宿題編集からそのカードを選べます。")
                Text("宿題編集は、作っておいたカードを組み合わせて宿題セットにする場所です。")
            }

            Section("その他品詞について") {
                Text("その他品詞は、自習用の単語カードです。")
                Text("現在の宿題セットには含まれません。")
                Text("生徒に使わせたいその他品詞は、あらかじめアプリ内に用意しておきます。")
            }

            Section("コラムを配布する") {
                Text("コラムは、宿題とは別に配布できる読み物です。")
                Text("コラムページはスクロール方式なので、長さは適宜調整できます。")
                Text("コラムを作成・編集したあと、コラムJSONとして書き出します。")
                Text("その後、最新コラム番号を入れたwf-manifest.jsonを作成します。")
                Text("生徒には、コラムJSONとwf-manifest.jsonをAirDrop、メール、LINEなどで送ります。")
                Text("生徒はwf-manifest.jsonをWordsForestフォルダへ保存して「新着確認」を押します。")
                Text("コラムJSONは、HOMEの「コラム」から「新規取得」を押して取り込みます。")
            }
        }
        .navigationTitle("先生向け：宿題の出し方")
    }
}
