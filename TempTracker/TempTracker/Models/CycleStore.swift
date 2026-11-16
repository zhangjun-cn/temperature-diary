import Foundation
import Observation

/// 记录存储：负责内存中的记录集合与本地 JSON 持久化。
@Observable
final class CycleStore {
    private(set) var records: [DayRecord] = []

    private let fileName = "temperature_records.json"

    init() {
        load()
    }

    // MARK: - 访问

    /// 获取某天的记录；不存在时返回一个空记录（不会写入存储）。
    func record(on day: Date) -> DayRecord {
        let d = day.startOfDay
        if let r = records.first(where: { $0.day == d }) {
            return r
        }
        return DayRecord(day: d)
    }

    /// 按日期升序排列的记录
    var sortedRecords: [DayRecord] {
        records.sorted { $0.day < $1.day }
    }

    /// 保存 / 更新某天记录；空记录会被移除。
    func update(_ record: DayRecord) {
        let d = record.day.startOfDay
        if record.isEmpty {
            records.removeAll { $0.day == d }
        } else if let idx = records.firstIndex(where: { $0.day == d }) {
            records[idx] = record
        } else {
            records.append(record)
        }
        save()
    }

    // MARK: - 统计

    var recordedDays: [DayRecord] { sortedRecords }

    var temperatureValues: [Double] {
        sortedRecords.compactMap(\.temperature)
    }

    var averageTemperature: Double? {
        let values = temperatureValues
        guard !values.isEmpty else { return nil }
        return values.reduce(0, +) / Double(values.count)
    }

    var maxTemperature: Double? { temperatureValues.max() }
    var minTemperature: Double? { temperatureValues.min() }

    var periodDays: Int { sortedRecords.filter(\.isPeriod).count }
    var sexDays: Int { sortedRecords.filter(\.hadSex).count }

    // MARK: - 持久化

    private var fileURL: URL {
        let dir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        return dir.appendingPathComponent(fileName)
    }

    private func load() {
        guard let data = try? Data(contentsOf: fileURL),
              let loaded = try? JSONDecoder().decode([DayRecord].self, from: data)
        else {
            records = []
            return
        }
        records = loaded
    }

    private func save() {
        guard let data = try? JSONEncoder().encode(records) else { return }
        try? data.write(to: fileURL, options: .atomic)
    }
}
