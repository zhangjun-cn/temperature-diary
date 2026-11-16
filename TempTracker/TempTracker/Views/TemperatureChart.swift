import SwiftUI
import Charts

extension Color {
    /// 经期血滴：深红
    static let bloodRed = Color(red: 0.75, green: 0.05, blue: 0.12)
    /// 性生活爱心：浅粉
    static let softPink = Color(red: 1.0, green: 0.66, blue: 0.78)
}

/// 可复用的体温折线图：支持横向滑动查看更早数据，并带「回到今天」按钮。
struct TemperatureChart: View {
    let records: [DayRecord]

    /// 可见窗口天数：默认展示「今天往前 N 天」
    var visibleDays: Int = 7
    /// 折线图高度
    var chartHeight: CGFloat = 210

    @Binding var scrollPosition: TimeInterval

    private var plotRecords: [DayRecord] {
        records.filter { $0.temperature != nil }
    }

    private var windowSeconds: Double {
        Double(visibleDays) * 86_400
    }

    var body: some View {
        if plotRecords.isEmpty {
            ContentUnavailableView(
                "暂无体温数据",
                systemImage: "chart.xyaxis.line",
                description: Text("记录体温后，这里会显示体温折线图。")
            )
        } else {
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Text("最近 \(visibleDays) 天")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    Spacer()
                    Button("回到今天") { scrollToToday(animated: true) }
                        .font(.subheadline)
                }

                chart
                legend
            }
        }
    }

    private var chart: some View {
        Chart {
            // 体温折线
            ForEach(plotRecords) { record in
                LineMark(
                    x: .value("日期", record.day),
                    y: .value("体温", record.temperature ?? 0)
                )
                .interpolationMethod(.catmullRom)
                .foregroundStyle(Color.accentColor)
                .lineStyle(StrokeStyle(lineWidth: 2, dash: [6, 4]))
            }

            // 经期：红色血滴（空心=少，1滴=正常，2滴=多，3滴=很多）
            ForEach(plotRecords.filter(\.isPeriod)) { record in
                PointMark(
                    x: .value("日期", record.day),
                    y: .value("体温", record.temperature ?? 0)
                )
                .symbolSize(0)
                .annotation(position: .overlay, alignment: .center, spacing: 0) {
                    BloodDropMarker(flow: record.flow ?? .normal)
                }
            }

            // 性生活（非经期）：粉红爱心
            ForEach(plotRecords.filter { $0.hadSex && !$0.isPeriod }) { record in
                PointMark(
                    x: .value("日期", record.day),
                    y: .value("体温", record.temperature ?? 0)
                )
                .symbolSize(0)
                .annotation(position: .overlay, alignment: .center, spacing: 0) {
                    Image(systemName: "heart.fill")
                        .foregroundStyle(Color.softPink)
                        .font(.system(size: 11))
                }
            }

            // 普通日：绿色圆点
            ForEach(plotRecords.filter { !$0.isPeriod && !$0.hadSex }) { record in
                PointMark(
                    x: .value("日期", record.day),
                    y: .value("体温", record.temperature ?? 0)
                )
                .symbolSize(0)
                .annotation(position: .overlay, alignment: .center, spacing: 0) {
                    Circle()
                        .fill(Color.green)
                        .frame(width: 7, height: 7)
                }
            }
        }
        .chartScrollableAxes(.horizontal)
        .chartXScale(domain: fullDomain)
        .chartXVisibleDomain(length: windowSeconds)
        .chartScrollPosition(x: $scrollPosition)
        .chartYScale(domain: yDomain)
        .chartXAxis {
            AxisMarks(values: .automatic(desiredCount: 6)) { _ in
                AxisGridLine()
                AxisTick()
                AxisValueLabel(format: .dateTime.month().day())
            }
        }
        .frame(height: chartHeight)
    }

    /// 完整可滚动范围：从最早一条记录到今天（右端固定为今天）
    private var fullDomain: ClosedRange<Date> {
        let today = Date().startOfDay
        let earliest = plotRecords.map(\.day).min() ?? today
        let lower = min(earliest, today.addingTimeInterval(-windowSeconds))
        return lower...today
    }

    private var yDomain: ClosedRange<Double> {
        let temps = plotRecords.compactMap(\.temperature)
        guard let lo = temps.min(), let hi = temps.max() else { return 35.0...38.0 }
        let paddedLo = max(34.8, lo - 0.25)
        let paddedHi = min(38.5, hi + 0.25)
        return paddedLo...paddedHi
    }

    /// 回到今天：让窗口右端对齐今天，显示「今天往前 N 天」
    private func scrollToToday(animated: Bool) {
        let today = Date().startOfDay
        let leading = today.addingTimeInterval(-windowSeconds)
        if animated {
            withAnimation(.easeInOut(duration: 0.5)) {
                scrollPosition = leading.timeIntervalSinceReferenceDate
            }
        } else {
            scrollPosition = leading.timeIntervalSinceReferenceDate
        }
    }

    private var legend: some View {
        HStack(spacing: 14) {
            legendItem(text: "体温") {
                Path { path in
                    path.move(to: CGPoint(x: 0, y: 1.5))
                    path.addLine(to: CGPoint(x: 14, y: 1.5))
                }
                .stroke(Color.accentColor, style: StrokeStyle(lineWidth: 3, dash: [5, 3]))
                .frame(width: 14, height: 3)
            }
            legendItem(text: "经期") {
                Image(systemName: "drop.fill")
                    .foregroundStyle(Color.bloodRed)
                    .font(.system(size: 11))
            }
            legendItem(text: "性生活") {
                Image(systemName: "heart.fill")
                    .foregroundStyle(Color.softPink)
                    .font(.system(size: 11))
            }
            legendItem(text: "普通日") {
                Circle().fill(Color.green).frame(width: 7, height: 7)
            }
        }
        .font(.caption)
        .foregroundStyle(.secondary)
    }

    private func legendItem<Icon: View>(text: String, @ViewBuilder icon: () -> Icon) -> some View {
        HStack(spacing: 4) {
            icon()
            Text(text)
        }
    }
}

/// 经期血滴图标：空心表示「少」，实心 1/2/3 滴表示「正常/多/很多」。
struct BloodDropMarker: View {
    let flow: PeriodFlow

    var body: some View {
        Group {
            switch flow {
            case .light:
                Image(systemName: "drop")
                    .font(.system(size: 10))
            case .normal:
                Image(systemName: "drop.fill")
                    .font(.system(size: 10))
            case .heavy:
                HStack(spacing: 1) {
                    Image(systemName: "drop.fill")
                    Image(systemName: "drop.fill")
                }
                .font(.system(size: 9))
            case .veryHeavy:
                VStack(spacing: 1) {
                    Image(systemName: "drop.fill")
                    HStack(spacing: 1) {
                        Image(systemName: "drop.fill")
                        Image(systemName: "drop.fill")
                    }
                }
                .font(.system(size: 8))
            }
        }
        .foregroundStyle(Color.bloodRed)
    }
}
