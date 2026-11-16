import SwiftUI

/// 全局可配置项的 UserDefaults key
enum AppSettingKey {
    static let timerMinutes = "settings.timerMinutes"
    static let temperatureStep = "settings.temperatureStep"
}

struct SettingsView: View {
    @AppStorage(AppSettingKey.timerMinutes) private var timerMinutes = 5
    @AppStorage(AppSettingKey.temperatureStep) private var temperatureStep = 0.05

    @State private var draftTimerMinutes: Int = 5
    @State private var draftTemperatureStep: Double = 0.05

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Picker("时长", selection: $draftTimerMinutes) {
                        ForEach([1, 3, 5, 10, 15], id: \.self) { minutes in
                            Text("\(minutes) 分钟").tag(minutes)
                        }
                    }
                    .pickerStyle(.menu)
                } header: {
                    Text("测温计时时长")
                } footer: {
                    Text("开始测温后倒计时该时长，到点闹铃提醒。")
                }

                Section {
                    Picker("步长", selection: $draftTemperatureStep) {
                        ForEach([0.01, 0.05, 0.1], id: \.self) { step in
                            Text(String(format: "%.2f °C", step)).tag(step)
                        }
                    }
                    .pickerStyle(.menu)
                } header: {
                    Text("基础体温微调步长")
                } footer: {
                    Text("记录体温时 +/- 按钮每次调整的幅度。")
                }
            }
            .navigationTitle("设置")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("保存") { save() }
                        .disabled(!hasChanges)
                }
            }
            .onAppear { loadDraft() }
        }
    }

    private var hasChanges: Bool {
        draftTimerMinutes != timerMinutes || draftTemperatureStep != temperatureStep
    }

    private func save() {
        timerMinutes = draftTimerMinutes
        temperatureStep = draftTemperatureStep
    }

    private func loadDraft() {
        draftTimerMinutes = timerMinutes
        draftTemperatureStep = temperatureStep
    }
}
