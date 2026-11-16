import SwiftUI

/// 从统计表点击某一行后弹出的「修改当天记录」表单。
struct EditRecordSheet: View {
    let day: Date

    @Environment(CycleStore.self) private var store
    @Environment(\.dismiss) private var dismiss
    @AppStorage(AppSettingKey.temperatureStep) private var temperatureStep = 0.05

    @State private var tempInput: String = ""
    @State private var isPeriod: Bool = false
    @State private var flow: PeriodFlow = .normal
    @State private var hadSex: Bool = false
    @State private var sexDay: SexDay = .yesterday
    @FocusState private var tempFocused: Bool

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    LabeledContent("日期", value: day.formatted(.dateTime.year().month().day()))
                }

                temperatureSection
                periodSection
                sexSection
            }
            .navigationTitle("修改记录")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("保存") { save() }
                        .disabled(!canSave)
                }
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button("完成") { tempFocused = false }
                }
            }
            .onAppear { loadDraft() }
        }
    }

    private var temperatureSection: some View {
        Section("基础体温") {
            HStack(spacing: 8) {
                TextField("36.50", text: $tempInput)
                    .keyboardType(.decimalPad)
                    .font(.system(size: 32, weight: .semibold, design: .rounded))
                    .multilineTextAlignment(.trailing)
                    .focused($tempFocused)
                Text("°C")
                    .font(.title2)
                    .foregroundStyle(.secondary)
            }
            Stepper(value: temperatureBinding, in: 34.0...42.0, step: temperatureStep) {
                Label("微调 \(stepText) °C", systemImage: "plusminus")
            }
            if invalidTemp {
                Text("请输入 34.0–42.0 之间的数字")
                    .foregroundStyle(.red)
            }
        }
    }

    private var periodSection: some View {
        Section("经期") {
            Toggle("是否经期", isOn: $isPeriod)
            if isPeriod {
                Picker("月经量", selection: $flow) {
                    ForEach(PeriodFlow.allCases) { item in
                        Text(item.label).tag(item)
                    }
                }
                .pickerStyle(.segmented)
            }
        }
    }

    private var sexSection: some View {
        Section("性生活") {
            Toggle("是否有性生活", isOn: $hadSex)
            if hadSex {
                Picker("时间", selection: $sexDay) {
                    ForEach(SexDay.allCases) { day in
                        Text(day.label).tag(day)
                    }
                }
                .pickerStyle(.segmented)
            }
        }
    }

    private var stepText: String {
        String(format: "%.2f", temperatureStep)
    }

    private var temperatureBinding: Binding<Double> {
        Binding(
            get: { parsedTemperature ?? 36.5 },
            set: { newValue in
                let v = min(42.0, max(34.0, newValue))
                tempInput = String(format: "%.2f", v)
            }
        )
    }

    private var cleanedTempInput: String {
        tempInput
            .replacingOccurrences(of: ",", with: ".")
            .replacingOccurrences(of: "，", with: ".")
            .replacingOccurrences(of: "．", with: ".")
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var invalidTemp: Bool {
        guard !cleanedTempInput.isEmpty else { return false }
        guard let v = Double(cleanedTempInput), (34.0...42.0).contains(v) else { return true }
        return false
    }

    private var parsedTemperature: Double? {
        guard !cleanedTempInput.isEmpty else { return nil }
        guard let v = Double(cleanedTempInput), (34.0...42.0).contains(v) else { return nil }
        return v
    }

    private func sexChanged() -> Bool {
        let rec = store.record(on: day)
        if !hadSex {
            return rec.hadSex != false
        }
        switch sexDay {
        case .today:
            return rec.hadSex != true
        case .yesterday:
            let prev = store.record(on: day.adding(days: -1))
            return rec.hadSex != false || prev.hadSex != true
        }
    }

    private var hasChanges: Bool {
        let rec = store.record(on: day)
        if invalidTemp { return true }
        if parsedTemperature != rec.temperature { return true }
        if isPeriod != rec.isPeriod { return true }
        if isPeriod && flow != (rec.flow ?? .normal) { return true }
        if sexChanged() { return true }
        return false
    }

    private var canSave: Bool {
        hasChanges && !invalidTemp
    }

    private func save() {
        guard !invalidTemp else { return }
        var rec = store.record(on: day)
        rec.temperature = parsedTemperature
        rec.isPeriod = isPeriod
        rec.flow = isPeriod ? flow : nil
        if hadSex {
            switch sexDay {
            case .today:
                rec.hadSex = true
            case .yesterday:
                rec.hadSex = false
                var prev = store.record(on: day.adding(days: -1))
                prev.hadSex = true
                store.update(prev)
            }
        } else {
            rec.hadSex = false
        }
        store.update(rec)
        dismiss()
    }

    private func loadDraft() {
        let rec = store.record(on: day)
        if let t = rec.temperature {
            tempInput = String(format: "%.2f", t)
        } else {
            tempInput = ""
        }
        isPeriod = rec.isPeriod
        flow = rec.flow ?? .normal
        if rec.hadSex {
            hadSex = true
            sexDay = .today
        } else if store.record(on: day.adding(days: -1)).hadSex {
            hadSex = true
            sexDay = .yesterday
        } else {
            hadSex = false
            sexDay = .yesterday
        }
    }
}
