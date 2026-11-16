import SwiftUI

struct ContentView: View {
    var body: some View {
        TabView {
            RecordView()
                .tabItem { Label("记录", systemImage: "thermometer.medium") }

            StatisticsView()
                .tabItem { Label("统计", systemImage: "chart.xyaxis.line") }

            SettingsView()
                .tabItem { Label("设置", systemImage: "gearshape") }
        }
    }
}
