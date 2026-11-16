import SwiftUI

struct RecordView: View {
    @Environment(CycleStore.self) private var store
    @AppStorage(AppSettingKey.temperatureStep) private var temperatureStep = 0.05

    @State private var day: Date = .now
    @State private var tempInput: String = ""
    @State private var isPeriod: Bool = false
    @State private var flow: PeriodFlow = .normal
    @State private var hadSex: Bool = false
    @State private var sexDay: SexDay = .yesterday
    @State private var pendingDay: Date?
    @State private var showDiscardAlert: Bool = false
    @FocusState private var tempFocused: Bool

    var body: some View {
        NavigationStack {
            Form {
                dateSection
                TemperatureTimerView()
                temperatureSection
                periodSection
                sexSection
            }
            .navigationTitle("记录")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("保存") { save() }
                        .disabled(!canSave)
                }
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button("完成") { tempFocused = false }
                }
            }
            .alert("有未保存的修改", isPresented: $showDiscardAlert) {
                if canSave {
                    Button("保存并切换") {
                        save()
                        applyPendingDay()
                    }
                }
                Button("放弃修改", role: .destructive) {
                    applyPendingDay()
                }
                Button("取消", role: .cancel) {
                    pendingDay = nil
                }
            } message: {
                Text("切换日期前要保存当前的修改吗？")
            }
            .onAppear { loadDraft() }
            .onChange(of: day) { _, _ in loadDraft() }
        }
    }

    // MARK: - 日期导航

    private var dateSection: some View {
        Section {
            HStack(spacing: 16) {
                Button {
                    requestDayChange(to: day.adding(days: -1))
                } label: {
                    Image(systemName: "chevron.left")
                        .font(.headline)
                        .frame(width: 36, height: 36)
                }
                .buttonStyle(.bordered)

                Spacer()

                VStack(spacing: 6) {
                    DatePicker("选择日期", selection: pickerBinding, displayedComponents: .date)
                        .labelsHidden()
                        .datePickerStyle(.compact)
                    Text(relativeLabel)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Button {
                    requestDayChange(to: day.adding(days: 1))
                } label: {
                    Image(systemName: "chevron.right")
                        .font(.headline)
                        .frame(width: 36, height: 36)
                }
                .buttonStyle(.bordered)
            }
            .padding(.vertical, 4)

            if !day.isSameDay(as: .now) {
                Button("回到今天") { requestDayChange(to: .now) }
                    .frame(maxWidth: .infinity)
            }
        }
    }

    /// DatePicker 的绑定：先把目标日期暂存，再决定是否需要确认
    private var pickerBinding: Binding<Date> {
        Binding(
            get: { day },
            set: { newDate in requestDayChange(to: newDate) }
        )
    }

    /// 切换日期；有未保存修改时先弹窗确认
    private func requestDayChange(to newDay: Date) {
        guard !newDay.isSameDay(as: day) else { return }
        if hasChanges {
            pendingDay = newDay
            showDiscardAlert = true
        } else {
            day = newDay
        }
    }

    private func applyPendingDay() {
        if let target = pendingDay {
            day = target
        }
        pendingDay = nil
    }

    private var relativeLabel: String {
        let cal = Calendar.current
        if cal.isDateInToday(day) { return "今天" }
        if cal.isDateInYesterday(day) { return "昨天" }
        if cal.isDateInTomorrow(day) { return "明天" }
        let days = cal.dateComponents([.day], from: day.startOfDay, to: Date().startOfDay).day ?? 0
        if days < 0 { return "\(-days) 天后" }
        return "\(days) 天前"
    }

    // MARK: - 体温

    private var temperatureSection: some View {
        Section {
            HStack(spacing: 8) {
                TextField("36.50", text: $tempInput)
                    .keyboardType(.decimalPad)
                    .font(.system(size: 44, weight: .semibold, design: .rounded))
                    .multilineTextAlignment(.trailing)
                    .focused($tempFocused)
                Text("°C")
                    .font(.title2)
                    .foregroundStyle(.secondary)
            }

            Stepper(value: temperatureBinding, in: 34.0...42.0, step: temperatureStep) {
                Label("微调 \(stepText) °C", systemImage: "plusminus")
            }
        } header: {
            Text("基础体温")
        } footer: {
            if invalidTemp {
                Text("请输入 34.0–42.0 之间的数字")
                    .foregroundStyle(.red)
            } else {
                Text("请填入当天早晨的基础体温（约 36.0–37.0 °C）。")
            }
        }
    }

    private var stepText: String {
        String(format: "%.2f", temperatureStep)
    }

    /// 仅改动草稿，不写入存储
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

    /// 输入非空但无法解析为有效体温时为 true
    private var invalidTemp: Bool {
        guard !cleanedTempInput.isEmpty else { return false }
        guard let v = Double(cleanedTempInput), (34.0...42.0).contains(v) else { return true }
        return false
    }

    /// 解析后的体温；空或无效时为 nil
    private var parsedTemperature: Double? {
        guard !cleanedTempInput.isEmpty else { return nil }
        guard let v = Double(cleanedTempInput), (34.0...42.0).contains(v) else { return nil }
        return v
    }

    // MARK: - 经期

    private var periodSection: some View {
        Section {
            Toggle("是否经期", isOn: $isPeriod)

            if isPeriod {
                Picker("月经量", selection: $flow) {
                    ForEach(PeriodFlow.allCases) { item in
                        Text(item.label).tag(item)
                    }
                }
                .pickerStyle(.segmented)
            }
        } header: {
            Text("经期")
        } footer: {
            if isPeriod {
                Text("已标记为经期，请选择当天的月经量。")
            }
        }
    }

    // MARK: - 性生活

    private var sexSection: some View {
        Section {
            Toggle("是否有性生活", isOn: $hadSex)

            if hadSex {
                Picker("时间", selection: $sexDay) {
                    ForEach(SexDay.allCases) { day in
                        Text(day.label).tag(day)
                    }
                }
                .pickerStyle(.segmented)
            }
        } header: {
            Text("性生活")
        } footer: {
            if hadSex {
                Text("「昨天」标记前一天，「今天」标记当天。")
            }
        }
    }

    // MARK: - 保存

    /// 性生活状态是否与存储不一致
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

    /// 是否有未保存的修改
    private var hasChanges: Bool {
        let rec = store.record(on: day)
        if invalidTemp { return true }
        if parsedTemperature != rec.temperature { return true }
        if isPeriod != rec.isPeriod { return true }
        if isPeriod && flow != (rec.flow ?? .normal) { return true }
        if sexChanged() { return true }
        return false
    }

    /// 有修改且输入合法时才允许保存
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

        loadDraft()
    }

    /// 从存储载入当前日期的记录到草稿
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
