# 体温日记（TempTracker）

一款面向女性的基础体温记录 iOS App。每天记录体温，标记是否经期（以及月经量），并记录当天是否有性行为，最后汇总成统计表和折线图。

## 功能

- **每日记录**：按日期填写基础体温（°C，支持一位/两位小数，可用步进器微调 0.05）。
- **经期标记**：开关「是否经期」；开启后选择月经量（少 / 正常 / 多 / 很多）。
- **性行为记录**：开关「当天有性行为」。
- **统计页**：
  - 概览卡片：平均 / 最高 / 最低体温、记录天数、经期天数、性行为天数。
  - **体温折线图**：按日期展示体温趋势；经期点标为粉色、普通日为橙色、性行为日标为绿色菱形。
  - **统计表**：按月分组，列出日期、体温、经期/量、性行为。

## 技术要点

- SwiftUI + Swift Charts（折线图）。
- `@Observable`（iOS 17+）作为状态管理，数据用 JSON 自动持久化到 App 沙盒的 Documents 目录（`temperature_records.json`）。
- 最低支持系统：**iOS 17.0**，仅 iPhone（竖屏）。

## 如何运行

1. 安装 **Xcode 15 或更高版本**（含 iOS 17 模拟器）。
2. 双击打开 `TempTracker/TempTracker.xcodeproj`。
3. 在 Xcode 顶部选择一个 iPhone 模拟器（或你自己的真机）。
4. 点击 **Run（▶）** 即可。

> 真机运行需要登录 Apple ID 并配置签名。当前工程已开启 `Automatic` 签名，Bundle ID 为 `com.example.TempTracker`，如需上架请改成你自己的唯一标识。

## 目录结构

```
TempTracker/
├── TempTracker.xcodeproj          Xcode 工程
└── TempTracker/
    ├── TempTrackerApp.swift       应用入口
    ├── Models/
    │   ├── DateExtensions.swift   日期工具（当天零点、月份分组等）
    │   ├── DayRecord.swift        单日记录 + 月经量枚举
    │   └── CycleStore.swift       记录存储 / 统计 / JSON 持久化
    └── Views/
        ├── ContentView.swift       标签页容器
        ├── RecordView.swift        记录页（体温/经期/性行为）
        ├── StatisticsView.swift    统计页（概览/表格）
        └── TemperatureChart.swift  体温折线图
```

## 数据说明

- 体温以「摄氏度」保存，精度两位小数。
- 月经量仅在标记为经期时才有值；关闭经期开关会自动清空月经量。
- 清空某天所有内容后，该天记录会被自动删除。
