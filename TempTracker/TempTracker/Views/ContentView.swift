import SwiftUI

struct ContentView: View {
    @State private var selection: Int = ContentView.initialTab

    var body: some View {
        TabView(selection: $selection) {
            RecordView()
                .tabItem { Label("记录", systemImage: "thermometer.medium") }
                .tag(0)

            StatisticsView()
                .tabItem { Label("统计", systemImage: "chart.xyaxis.line") }
                .tag(1)

            SettingsView()
                .tabItem { Label("设置", systemImage: "gearshape") }
                .tag(2)
        }
    }

    /// 供截图/调试用：环境变量 INITIAL_TAB 或启动参数 `-tab N` 选择初始标签页（0=记录 1=统计 2=设置）。
    private static var initialTab: Int {
        if let v = ProcessInfo.processInfo.environment["INITIAL_TAB"], let n = Int(v) {
            return n
        }
        let args = ProcessInfo.processInfo.arguments
        if let i = args.firstIndex(of: "-tab"), i + 1 < args.count {
            return Int(args[i + 1]) ?? 0
        }
        return 0
    }
}
