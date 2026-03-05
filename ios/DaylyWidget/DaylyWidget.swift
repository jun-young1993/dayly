import WidgetKit
import SwiftUI

// MARK: - 데이터 모델

/// home_widget 패키지가 UserDefaults(App Group)에 저장한 JSON을 읽는 구조체.
struct DaylyWidgetEntry: TimelineEntry {
    let date: Date
    let id: String
    let sentence: String
    let countdownText: String
    let dateLabel: String
    let themePreset: String
    let isPast: Bool
}

extension DaylyWidgetEntry {
    static var placeholder: DaylyWidgetEntry {
        DaylyWidgetEntry(
            date: .now,
            id: "",
            sentence: "소중한 날까지",
            countdownText: "D-23",
            dateLabel: "2026.06.01",
            themePreset: "night",
            isPast: false
        )
    }
}

// MARK: - UserDefaults 헬퍼

private let appGroupId = "group.juny.dayly"
private let keyWidgetsJson = "dayly_widgets_json"
private let keySelectedId = "dayly_selected_widget_id"

/// App Group UserDefaults에서 위젯 데이터를 불러온다.
/// selectedId가 있으면 해당 항목, 없으면 첫 번째 항목을 반환한다.
func loadEntry(selectedId: String? = nil) -> DaylyWidgetEntry {
    guard
        let defaults = UserDefaults(suiteName: appGroupId),
        let jsonString = defaults.string(forKey: keyWidgetsJson),
        let jsonData = jsonString.data(using: .utf8),
        let array = try? JSONSerialization.jsonObject(with: jsonData) as? [[String: Any]],
        !array.isEmpty
    else {
        return .placeholder
    }

    let fallbackId = selectedId ?? defaults.string(forKey: keySelectedId)
    let item: [String: Any]

    if let sid = fallbackId, let found = array.first(where: { $0["id"] as? String == sid }) {
        item = found
    } else {
        item = array[0]
    }

    return DaylyWidgetEntry(
        date: .now,
        id: item["id"] as? String ?? "",
        sentence: item["sentence"] as? String ?? "",
        countdownText: item["countdownText"] as? String ?? "–",
        dateLabel: item["targetDateLabel"] as? String ?? "",
        themePreset: item["themePreset"] as? String ?? "night",
        isPast: item["isPast"] as? Bool ?? false
    )
}

// MARK: - AppIntent (사용자 D-Day 선택)

import AppIntents

struct SelectDaylyIntent: WidgetConfigurationIntent {
    static var title: LocalizedStringResource = "D-Day 선택"
    static var description = IntentDescription("표시할 D-Day를 선택하세요.")

    @Parameter(title: "D-Day ID")
    var widgetId: String?
}

// MARK: - TimelineProvider

struct DaylyProvider: AppIntentTimelineProvider {
    typealias Entry = DaylyWidgetEntry
    typealias Intent = SelectDaylyIntent

    func placeholder(in context: Context) -> DaylyWidgetEntry { .placeholder }

    func snapshot(for configuration: SelectDaylyIntent, in context: Context) async -> DaylyWidgetEntry {
        loadEntry(selectedId: configuration.widgetId)
    }

    func timeline(for configuration: SelectDaylyIntent, in context: Context) async -> Timeline<DaylyWidgetEntry> {
        let entry = loadEntry(selectedId: configuration.widgetId)

        // 매일 자정에 갱신 (D-Day 숫자가 바뀌는 시점)
        let midnight = Calendar.current.startOfDay(for: .now).addingTimeInterval(86_400)
        return Timeline(entries: [entry], policy: .after(midnight))
    }
}

// MARK: - 색상 헬퍼

extension Color {
    static func forTheme(_ preset: String) -> (bg: Color, text: Color, sub: Color) {
        switch preset {
        case "paper":
            return (Color(hex: 0xF7F2EA), Color(hex: 0x0B1220), Color(hex: 0x6B7280))
        case "fog":
            return (Color(hex: 0xE9F0F7), Color(hex: 0x0B1220), Color(hex: 0x6B7280))
        case "lavender":
            return (Color(hex: 0xF1ECF8), Color(hex: 0x0B1220), Color(hex: 0x6B7280))
        case "blush":
            return (Color(hex: 0xF8EDEF), Color(hex: 0x0B1220), Color(hex: 0x6B7280))
        default: // night
            return (Color(hex: 0x111827), Color(hex: 0xF4F6FA), Color(hex: 0x7090B0))
        }
    }

    init(hex: UInt32) {
        self.init(
            red: Double((hex >> 16) & 0xFF) / 255,
            green: Double((hex >> 8) & 0xFF) / 255,
            blue: Double(hex & 0xFF) / 255
        )
    }
}

// MARK: - SwiftUI Views

/// Small 위젯 뷰 (systemSmall)
struct DaylySmallView: View {
    let entry: DaylyWidgetEntry
    var body: some View {
        let theme = Color.forTheme(entry.themePreset)
        VStack(spacing: 4) {
            Text(entry.countdownText)
                .font(.system(size: 28, weight: .bold, design: .monospaced))
                .foregroundColor(theme.text)
                .minimumScaleFactor(0.6)
                .lineLimit(1)
            Text(entry.sentence)
                .font(.system(size: 11))
                .foregroundColor(theme.sub)
                .multilineTextAlignment(.center)
                .lineLimit(2)
        }
        .padding(12)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(theme.bg)
        .widgetURL(URL(string: "dayly://detail/\(entry.id)"))
    }
}

/// Medium 위젯 뷰 (systemMedium)
struct DaylyMediumView: View {
    let entry: DaylyWidgetEntry
    var body: some View {
        let theme = Color.forTheme(entry.themePreset)
        VStack(spacing: 0) {
            Text(entry.dateLabel)
                .font(.system(size: 10, weight: .regular))
                .foregroundColor(theme.sub)
                .frame(maxWidth: .infinity, alignment: .leading)

            Spacer(minLength: 4)

            Text(entry.countdownText)
                .font(.system(size: 38, weight: .bold, design: .monospaced))
                .foregroundColor(theme.text)
                .minimumScaleFactor(0.5)
                .lineLimit(1)
                .frame(maxWidth: .infinity, alignment: .leading)

            // 감성 구분점
            HStack(spacing: 4) {
                ForEach(0..<3, id: \.self) { _ in
                    Circle()
                        .fill(theme.sub.opacity(0.5))
                        .frame(width: 4, height: 4)
                }
                Spacer()
            }
            .padding(.vertical, 8)

            Text(entry.sentence)
                .font(.system(size: 13))
                .foregroundColor(theme.sub)
                .multilineTextAlignment(.leading)
                .lineLimit(2)
                .frame(maxWidth: .infinity, alignment: .leading)

            Spacer(minLength: 4)

            // 워터마크
            Text("dayly")
                .font(.system(size: 9, weight: .medium))
                .foregroundColor(theme.sub.opacity(0.4))
                .frame(maxWidth: .infinity, alignment: .trailing)
        }
        .padding(16)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(theme.bg)
        .widgetURL(URL(string: "dayly://detail/\(entry.id)"))
    }
}

/// 진입점 View — 크기에 따라 분기
struct DaylyWidgetEntryView: View {
    @Environment(\.widgetFamily) var family
    let entry: DaylyWidgetEntry

    var body: some View {
        switch family {
        case .systemSmall:
            DaylySmallView(entry: entry)
        default:
            DaylyMediumView(entry: entry)
        }
    }
}

// MARK: - Widget 정의

@main
struct DaylyWidget: Widget {
    let kind = "DaylyWidget"

    var body: some WidgetConfiguration {
        AppIntentConfiguration(
            kind: kind,
            intent: SelectDaylyIntent.self,
            provider: DaylyProvider()
        ) { entry in
            DaylyWidgetEntryView(entry: entry)
                .containerBackground(.clear, for: .widget)
        }
        .configurationDisplayName("dayly")
        .description("D-Day 카운트다운을 홈화면에서 바로 확인하세요.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}
