import SwiftUI

struct StatisticsView: View {
    @Environment(CycleStore.self) private var store

    @State private var showDetail = false
    @State private var chartScroll: TimeInterval = (Date().startOfDay.addingTimeInterval(-7 * 86_400)).timeIntervalSinceReferenceDate
    @State private var editingDay: Date?

    private var visibleDays: Int { 7 }
    private var windowSeconds: Double { Double(visibleDays) * 86_400 }

    var body: some View {
        NavigationStack {
            List {
                overviewSection
                chartSection
                tableSection
            }
            .navigationTitle("统计")
            .fullScreenCover(isPresented: $showDetail) {
                ChartDetailView(records: store.sortedRecords)
            }
            .sheet(isPresented: editingBinding) {
                if let day = editingDay {
                    EditRecordSheet(day: day)
                }
            }
        }
    }

    // MARK: - 概览

    private var overviewSection: some View {
        Section("概览") {
            LazyVGrid(
                columns: [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)],
                spacing: 12
            ) {
                MetricCard(title: "平均体温", value: fmt(store.averageTemperature), unit: "°C")
                MetricCard(title: "记录天数", value: "\(store.recordedDays.count)", unit: "天")
                MetricCard(title: "最高体温", value: fmt(store.maxTemperature), unit: "°C")
                MetricCard(title: "最低体温", value: fmt(store.minTemperature), unit: "°C")
                MetricCard(title: "经期天数", value: "\(store.periodDays)", unit: "天")
                MetricCard(title: "性生活天数", value: "\(store.sexDays)", unit: "天")
            }
            .padding(.vertical, 4)
        }
    }

    private func fmt(_ value: Double?) -> String {
        guard let value else { return "—" }
        return String(format: "%.2f", value)
    }

    // MARK: - 折线图

    private var chartSection: some View {
        Section {
            TemperatureChart(records: store.sortedRecords, visibleDays: visibleDays, scrollPosition: $chartScroll)
                .frame(minHeight: 260)
                .padding(.vertical, 4)
        } header: {
            HStack {
                Text("体温折线图")
                Spacer()
                Button("详细") { showDetail = true }
                    .disabled(store.temperatureValues.isEmpty)
            }
        }
    }

    // MARK: - 统计表

    private var tableSection: some View {
        Section {
            HStack {
                Button {
                    shiftWindow(days: -visibleDays)
                } label: {
                    Label("前一周", systemImage: "chevron.left")
                }
                .buttonStyle(.borderless)

                Spacer()

                Button("回到今天") { backToToday() }
                    .buttonStyle(.bordered)

                Spacer()

                Button {
                    shiftWindow(days: visibleDays)
                } label: {
                    Label("后一周", systemImage: "chevron.right")
                }
                .buttonStyle(.borderless)
            }
            .font(.subheadline)

            Text(rangeLabel)
                .font(.caption)
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity, alignment: .center)

            tableHeader

            if windowRecords.isEmpty {
                Text("该时间段暂无记录")
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 8)
            } else {
                ForEach(windowRecords) { record in
                    Button {
                        editingDay = record.day
                    } label: {
                        RecordRow(record: record)
                    }
                    .buttonStyle(.plain)
                }
            }
        } header: {
            Text("统计表")
        } footer: {
            Text("点击某一行可修改当天的记录。")
        }
    }

    private var tableHeader: some View {
        HStack(spacing: 8) {
            Text("日期")
                .frame(width: 56, alignment: .leading)
            Text("体温")
                .frame(maxWidth: .infinity, alignment: .center)
            Text("经期/量")
                .frame(width: 88, alignment: .center)
            Text("性生活")
                .frame(width: 52, alignment: .center)
        }
        .font(.caption.bold())
        .foregroundStyle(.secondary)
    }

    // MARK: - 窗口同步

    private var today: Date { Date().startOfDay }

    private var windowLeading: Date {
        Date(timeIntervalSinceReferenceDate: chartScroll)
    }

    private var windowTrailing: Date {
        windowLeading.addingTimeInterval(windowSeconds)
    }

    private var maxLeading: Date {
        today.addingTimeInterval(-windowSeconds)
    }

    private var minLeading: Date {
        let earliest = store.sortedRecords.map(\.day).min() ?? today
        return min(earliest, maxLeading)
    }

    private var windowRecords: [DayRecord] {
        let leading = windowLeading.startOfDay
        let trailing = windowTrailing.startOfDay
        return store.sortedRecords.filter { $0.day >= leading && $0.day <= trailing }
    }

    private var rangeLabel: String {
        "\(windowLeading.formatted(.dateTime.month().day())) – \(windowTrailing.formatted(.dateTime.month().day()))"
    }

    private func shiftWindow(days: Int) {
        var newLeading = windowLeading.addingTimeInterval(Double(days) * 86_400)
        newLeading = min(max(newLeading, minLeading), maxLeading)
        withAnimation(.easeInOut(duration: 0.5)) {
            chartScroll = newLeading.timeIntervalSinceReferenceDate
        }
    }

    private func backToToday() {
        withAnimation(.easeInOut(duration: 0.5)) {
            chartScroll = maxLeading.timeIntervalSinceReferenceDate
        }
    }

    // MARK: - 编辑

    private var editingBinding: Binding<Bool> {
        Binding(
            get: { editingDay != nil },
            set: { if !$0 { editingDay = nil } }
        )
    }
}

// MARK: - 概览卡片

struct MetricCard: View {
    let title: String
    let value: String
    let unit: String

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
            HStack(alignment: .firstTextBaseline, spacing: 2) {
                Text(value)
                    .font(.title2.bold())
                    .minimumScaleFactor(0.6)
                    .lineLimit(1)
                Text(unit)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(Color(uiColor: .secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

// MARK: - 表格行

struct RecordRow: View {
    let record: DayRecord

    var body: some View {
        HStack(spacing: 8) {
            Text(record.day, format: .dateTime.month().day())
                .frame(width: 56, alignment: .leading)
                .font(.subheadline.monospacedDigit())

            Text(temperatureText)
                .frame(maxWidth: .infinity, alignment: .center)
                .font(.subheadline.monospacedDigit())

            Text(periodText)
                .frame(width: 88, alignment: .center)
                .font(.subheadline)
                .foregroundStyle(record.isPeriod ? Color.pink : Color.secondary)

            Text(record.hadSex ? "有" : "无")
                .frame(width: 52, alignment: .center)
                .font(.subheadline)
                .foregroundStyle(record.hadSex ? Color.green : Color.secondary)
        }
        .padding(.vertical, 2)
    }

    private var temperatureText: String {
        if let t = record.temperature {
            return String(format: "%.2f", t)
        }
        return "—"
    }

    private var periodText: String {
        if record.isPeriod {
            let flow = record.flow ?? .normal
            return "经期·\(flow.label)"
        }
        return "—"
    }
}
