import Foundation

extension Date {
    /// 当天零点（本地时区）
    var startOfDay: Date {
        Calendar.current.startOfDay(for: self)
    }

    /// 当月第一天零点（本地时区）
    var startOfMonth: Date {
        let comps = Calendar.current.dateComponents([.year, .month], from: self)
        return Calendar.current.date(from: comps) ?? self
    }

    /// 增加或减少若干天
    func adding(days: Int) -> Date {
        Calendar.current.date(byAdding: .day, value: days, to: self) ?? self
    }

    /// 是否与另一日期为同一天
    func isSameDay(as other: Date) -> Bool {
        Calendar.current.isDate(self, inSameDayAs: other)
    }
}
