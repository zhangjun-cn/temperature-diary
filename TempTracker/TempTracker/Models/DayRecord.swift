import Foundation

/// 月经量：少 / 正常 / 多 / 很多
enum PeriodFlow: String, Codable, CaseIterable, Identifiable, Hashable {
    case light
    case normal
    case heavy
    case veryHeavy

    var id: String { rawValue }

    var label: String {
        switch self {
        case .light: return "少"
        case .normal: return "正常"
        case .heavy: return "多"
        case .veryHeavy: return "很多"
        }
    }
}

/// 性生活时间选项：昨天 / 今天
enum SexDay: String, CaseIterable, Identifiable {
    case yesterday
    case today

    var id: String { rawValue }

    var label: String {
        switch self {
        case .yesterday: return "昨天"
        case .today: return "今天"
        }
    }
}

/// 某一天的记录
struct DayRecord: Identifiable, Codable, Hashable {
    /// 以当天零点作为唯一标识
    var id: Date { day }

    /// 记录所属日期（当天零点）
    var day: Date
    /// 基础体温（摄氏度），未填写时为 nil
    var temperature: Double?
    /// 是否为经期
    var isPeriod: Bool
    /// 月经量（仅经期时有效）
    var flow: PeriodFlow?
    /// 当天是否有性生活
    var hadSex: Bool

    init(
        day: Date,
        temperature: Double? = nil,
        isPeriod: Bool = false,
        flow: PeriodFlow? = nil,
        hadSex: Bool = false
    ) {
        self.day = day.startOfDay
        self.temperature = temperature
        self.isPeriod = isPeriod
        self.flow = flow
        self.hadSex = hadSex
    }

    /// 是否不含任何有效内容（用于清理空记录）
    var isEmpty: Bool {
        temperature == nil && !isPeriod && !hadSex
    }
}
