import SwiftUI
import UserNotifications

/// 测温计时：开始后按设定时长通过本地通知（闹铃）提醒。
/// 本地通知由系统调度，即使关闭 App 或手机熄屏也会按时提醒。
struct TemperatureTimerView: View {
    @AppStorage(AppSettingKey.timerMinutes) private var timerMinutes = 5

    @State private var endDate: Date?
    @State private var showConfirm = false

    private var duration: TimeInterval { TimeInterval(timerMinutes) * 60 }
    private static let notificationID = "tempMeasurementDone"

    var body: some View {
        Section {
            TimelineView(.periodic(from: .now, by: 1)) { context in
                content(now: context.date)
            }
        } header: {
            Text("测温计时")
        }
        .alert("开始测温", isPresented: $showConfirm) {
            Button("开始") { start() }
            Button("取消", role: .cancel) {}
        } message: {
            Text("请先将温度计放置好，再点击「开始」。")
        }
    }

    @ViewBuilder
    private func content(now: Date) -> some View {
        if let endDate {
            if endDate > now {
                runningView(endDate: endDate, now: now)
            } else {
                finishedView
            }
        } else {
            idleView
        }
    }

    private var idleView: some View {
        Button {
            showConfirm = true
        } label: {
            Label("测温计时", systemImage: "timer")
        }
    }

    private func runningView(endDate: Date, now: Date) -> some View {
        VStack(spacing: 10) {
            HStack {
                Label("测温中…", systemImage: "timer")
                Spacer()
                Text(timeString(from: endDate.timeIntervalSince(now)))
                    .font(.title2.monospacedDigit().bold())
            }
            Button("取消计时", role: .destructive) { cancel() }
                .frame(maxWidth: .infinity)
        }
    }

    private var finishedView: some View {
        HStack {
            Label("测温结束，请记录读数", systemImage: "checkmark.circle.fill")
                .foregroundStyle(.green)
            Spacer()
            Button("重新计时") { showConfirm = true }
        }
    }

    private func timeString(from interval: TimeInterval) -> String {
        let total = max(0, Int(interval.rounded(.up)))
        return String(format: "%d:%02d", total / 60, total % 60)
    }

    private func start() {
        scheduleNotification()
        endDate = Date().addingTimeInterval(duration)
    }

    private func cancel() {
        UNUserNotificationCenter.current()
            .removePendingNotificationRequests(withIdentifiers: [Self.notificationID])
        endDate = nil
    }

    private func scheduleNotification() {
        let center = UNUserNotificationCenter.current()
        center.requestAuthorization(options: [.alert, .sound]) { granted, _ in
            guard granted else { return }

            let content = UNMutableNotificationContent()
            content.title = "测温结束"
            content.body = "\(timerMinutes) 分钟到了，请记录温度计读数。"
            content.sound = .default

            let trigger = UNTimeIntervalNotificationTrigger(timeInterval: duration, repeats: false)
            let request = UNNotificationRequest(identifier: Self.notificationID, content: content, trigger: trigger)

            center.removePendingNotificationRequests(withIdentifiers: [Self.notificationID])
            center.add(request)
        }
    }
}
