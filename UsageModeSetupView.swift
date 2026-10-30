//
//  UsageModeSetupView.swift
//  WordsForest
//
//  Created by Nami .T on 2026/10/30.
//

import SwiftUI

struct UsageModeSetupView: View {
    @ObservedObject private var teacher = TeacherMode.shared

    @AppStorage(DefaultsKeys.usageMode)
    private var usageMode: UsageMode = .classroom

    @AppStorage(DefaultsKeys.usageModeConfigured)
    private var usageModeConfigured: Bool = false

    @State private var showClassroomSetupNotice = false
    @State private var showTeacherInitialSetup = false

    var body: some View {
        VStack(spacing: 28) {
            Spacer()

            Text("利用方法を選択してください")
                .font(.title2)
                .fontWeight(.bold)

            Text("""
            Words’ Forest は、
            個人学習でも教室でも利用できます。
            """)
            .multilineTextAlignment(.center)
            .foregroundStyle(.secondary)

            VStack(spacing: 16) {
                Button {
                    usageMode = .individual
                    usageModeConfigured = true
                } label: {
                    VStack(spacing: 6) {
                        Text("個人")
                            .font(.title3)
                            .fontWeight(.semibold)

                        Text("自分で単語カードや宿題を編集します")
                            .font(.footnote)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 18)
                }
                .buttonStyle(.bordered)

                Button {
                    showClassroomSetupNotice = true
                } label: {
                    VStack(spacing: 6) {
                        Text("教室")
                            .font(.title3)
                            .fontWeight(.semibold)

                        Text("先生が学習内容を管理します")
                            .font(.footnote)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 18)
                }
                .buttonStyle(.bordered)
            }
            .padding(.horizontal, 32)

            Text("選択した利用方法は、HOME画面の「設定」からあとで変更できます。")
                .font(.footnote)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)

            Spacer()
        }
        .padding()
        .alert(
            "教室モードの設定",
            isPresented: $showClassroomSetupNotice
        ) {
            Button("戻る", role: .cancel) {
                showClassroomSetupNotice = false
            }

            Button("先生が設定する") {
                showClassroomSetupNotice = false

                if teacher.hasConfiguredPasscode {
                    teacher.requestUnlock {
                        usageMode = .classroom
                        usageModeConfigured = true
                    }
                } else {
                    showTeacherInitialSetup = true
                }
            }
        } message: {
            Text("""
            教室モードを利用する場合は、先生による事前設定が必要です。

            生徒の方は設定を行わず、先生に事前設定をしてもらってから使用してください。
            """)
        }
        .sheet(isPresented: $showTeacherInitialSetup) {
            TeacherInitialSetupSheet(
                teacher: teacher
            ) {
                usageMode = .classroom
                usageModeConfigured = true
            }
        }
    }
}
