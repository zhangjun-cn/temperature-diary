import SwiftUI
import UIKit

/// 横屏全屏的「一个月」折线图详情页。
struct ChartDetailView: View {
    let records: [DayRecord]

    @Environment(\.dismiss) private var dismiss

    @State private var scrollPosition: TimeInterval = (Date().startOfDay.addingTimeInterval(-30 * 86_400)).timeIntervalSinceReferenceDate

    var body: some View {
        NavigationStack {
            TemperatureChart(records: records, visibleDays: 30, chartHeight: 300, scrollPosition: $scrollPosition)
                .padding(.horizontal)
                .padding(.vertical, 8)
                .navigationTitle("一个月体温")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .topBarLeading) {
                        Button("关闭") { dismiss() }
                    }
                }
        }
        .onAppear { enterLandscape() }
        .onDisappear { enterPortrait() }
    }

    private func enterLandscape() {
        AppDelegate.orientationLock = .landscapeRight
        UIDevice.current.setValue(UIInterfaceOrientation.landscapeRight.rawValue, forKey: "orientation")
        UIViewController.attemptRotationToDeviceOrientation()
    }

    private func enterPortrait() {
        AppDelegate.orientationLock = .portrait
        UIDevice.current.setValue(UIInterfaceOrientation.portrait.rawValue, forKey: "orientation")
        UIViewController.attemptRotationToDeviceOrientation()
    }
}
