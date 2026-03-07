import WidgetKit
import SwiftUI
import AppIntents

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
    let currentIndex: Int
    let totalCount: Int
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
            isPast: false,
            currentIndex: 0,
            totalCount: 1
        )
    }
}

// MARK: - UserDefaults 헬퍼

private let appGroupId = "group.juny.dayly"
private let keyWidgetsJson = "dayly_widgets_json"
private let keyCurrentPage = "dayly_current_page"

/// App Group UserDefaults에서 전체 위젯 목록을 불러온다.
func loadAllEntries() -> [[String: Any]] {
    guard
        let defaults = UserDefaults(suiteName: appGroupId),
        let jsonString = defaults.string(forKey: keyWidgetsJson),
        let jsonData = jsonString.data(using: .utf8),
        let array = try? JSONSerialization.jsonObject(with: jsonData) as? [[String: Any]],
        !array.isEmpty
    else {
        return []
    }
    return array
}

/// 현재 페이지 인덱스에 해당하는 위젯 엔트리를 반환한다.
func loadEntry() -> DaylyWidgetEntry {
    let allEntries = loadAllEntries()
    guard !allEntries.isEmpty else { return .placeholder }

    let totalCount = allEntries.count
    let defaults = UserDefaults(suiteName: appGroupId)
    let rawIndex = defaults?.integer(forKey: keyCurrentPage) ?? 0
    let safeIndex = max(0, min(rawIndex, totalCount - 1))

    return entryFromItem(allEntries[safeIndex], index: safeIndex, total: totalCount)
}

/// targetDate(yyyy-MM-dd)와 countdownMode로 실시간 D-Day 텍스트를 계산한다.
private func buildCountdownText(targetDateIso: String, countdownMode: String) -> String {
    guard !targetDateIso.isEmpty else { return "–" }
    let formatter = DateFormatter()
    formatter.dateFormat = "yyyy-MM-dd"
    formatter.timeZone = TimeZone.current
    guard let targetDate = formatter.date(from: targetDateIso) else { return "–" }

    let calendar = Calendar.current
    let today = calendar.startOfDay(for: Date())
    let target = calendar.startOfDay(for: targetDate)
    let dayDiff = calendar.dateComponents([.day], from: today, to: target).day ?? 0
    let days = abs(dayDiff)

    switch countdownMode {
    case "days":
        return dayDiff >= 0 ? "\(days) days left" : "\(days) days ago"
    case "dMinus":
        if dayDiff == 0 { return "D-Day" }
        return dayDiff > 0 ? "D-\(days)" : "D+\(days)"
    case "weeksDays":
        let weeks = days / 7
        let rem = days % 7
        if weeks <= 0 { return "\(days) days" }
        if rem == 0 { return "\(weeks) weeks" }
        return "\(weeks) weeks \(rem) days"
    case "mornings":
        return "\(days) mornings"
    case "nights":
        return "\(days) nights"
    case "hidden":
        return ""
    default:
        if dayDiff == 0 { return "D-Day" }
        return dayDiff > 0 ? "D-\(days)" : "D+\(days)"
    }
}

private func entryFromItem(_ item: [String: Any], index: Int, total: Int) -> DaylyWidgetEntry {
    let targetDateIso = item["targetDate"] as? String ?? ""
    let countdownMode = item["countdownMode"] as? String ?? "dMinus"
    let countdownText = buildCountdownText(targetDateIso: targetDateIso, countdownMode: countdownMode)

    return DaylyWidgetEntry(
        date: .now,
        id: item["id"] as? String ?? "",
        sentence: item["sentence"] as? String ?? "",
        countdownText: countdownText,
        dateLabel: item["targetDateLabel"] as? String ?? "",
        themePreset: item["themePreset"] as? String ?? "night",
        isPast: item["isPast"] as? Bool ?? false,
        currentIndex: index,
        totalCount: total
    )
}

// MARK: - Navigation AppIntents (iOS 17+ 인터랙티브 위젯)

/// 다음 D-Day 이벤트로 이동
struct NextEventIntent: AppIntent {
    static var title: LocalizedStringResource = "다음 이벤트"

    func perform() async throws -> some IntentResult {
        navigateEvent(direction: 1)
        return .result()
    }
}

/// 이전 D-Day 이벤트로 이동
struct PrevEventIntent: AppIntent {
    static var title: LocalizedStringResource = "이전 이벤트"

    func perform() async throws -> some IntentResult {
        navigateEvent(direction: -1)
        return .result()
    }
}

/// 페이지 인덱스를 변경하고 타임라인을 갱신한다.
private func navigateEvent(direction: Int) {
    guard let defaults = UserDefaults(suiteName: appGroupId) else { return }
    let totalCount = loadAllEntries().count
    guard totalCount > 1 else { return }

    let current = defaults.integer(forKey: keyCurrentPage)
    let next = (current + direction + totalCount) % totalCount
    defaults.set(next, forKey: keyCurrentPage)

    WidgetCenter.shared.reloadAllTimelines()
}

// MARK: - AppIntent (위젯 구성용 — 레거시)

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
        loadEntry()
    }

    func timeline(for configuration: SelectDaylyIntent, in context: Context) async -> Timeline<DaylyWidgetEntry> {
        let entry = loadEntry()

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

/// Small 위젯 뷰 (systemSmall) — 좌우 탭 존으로 네비게이션
struct DaylySmallView: View {
    let entry: DaylyWidgetEntry
    var body: some View {
        let theme = Color.forTheme(entry.themePreset)
        ZStack {
            // 배경 + 메인 콘텐츠
            VStack(spacing: 4) {
                Text(entry.countdownText)
                    .font(.system(size: 14, weight: .bold, design: .monospaced))
                    .foregroundColor(theme.text)
                    .minimumScaleFactor(0.3)
                    .lineLimit(2)
                Text(entry.sentence)
                    .font(.system(size: 11))
                    .foregroundColor(theme.sub)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)

                if entry.totalCount > 1 {
                    Text("\(entry.currentIndex + 1)/\(entry.totalCount)")
                        .font(.system(size: 9, weight: .medium, design: .monospaced))
                        .foregroundColor(theme.sub.opacity(0.6))
                        .padding(.top, 2)
                }
            }
            .padding(12)

            // 3분할 탭 존: 좌(이전) / 중앙(앱 열기) / 우(다음)
            if entry.totalCount > 1 {
                HStack(spacing: 0) {
                    Button(intent: PrevEventIntent()) {
                        Color.clear
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)

                    Link(destination: URL(string: "dayly://detail/\(entry.id)")!) {
                        Color.clear
                            .contentShape(Rectangle())
                    }

                    Button(intent: NextEventIntent()) {
                        Color.clear
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(theme.bg)
        .widgetURL(entry.totalCount <= 1 ? URL(string: "dayly://detail/\(entry.id)") : nil)
    }
}

/// Medium 위젯 뷰 (systemMedium) — 3분할 탭 존 네비게이션
struct DaylyMediumView: View {
    let entry: DaylyWidgetEntry
    var body: some View {
        let theme = Color.forTheme(entry.themePreset)
        ZStack {
            // 메인 콘텐츠
            VStack(spacing: 0) {
                Text(entry.dateLabel)
                    .font(.system(size: 10, weight: .regular))
                    .foregroundColor(theme.sub)
                    .frame(maxWidth: .infinity, alignment: .leading)

                Spacer(minLength: 4)

                Text(entry.countdownText)
                    .font(.system(size: 38, weight: .bold, design: .monospaced))
                    .foregroundColor(theme.text)
                    .minimumScaleFactor(0.3)
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

                HStack {
                    // 페이지 인디케이터
                    if entry.totalCount > 1 {
                        HStack(spacing: 4) {
                            Image(systemName: "chevron.left")
                                .font(.system(size: 8, weight: .medium))
                            Text("\(entry.currentIndex + 1) / \(entry.totalCount)")
                                .font(.system(size: 9, weight: .medium, design: .monospaced))
                            Image(systemName: "chevron.right")
                                .font(.system(size: 8, weight: .medium))
                        }
                        .foregroundColor(theme.sub.opacity(0.5))
                    }
                    Spacer()
                    // 워터마크
                    Text("dayly")
                        .font(.system(size: 9, weight: .medium))
                        .foregroundColor(theme.sub.opacity(0.4))
                }
            }
            .padding(16)

            // 3분할 탭 존: 좌(이전) / 중앙(앱 열기) / 우(다음)
            if entry.totalCount > 1 {
                HStack(spacing: 0) {
                    Button(intent: PrevEventIntent()) {
                        Color.clear
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)

                    Link(destination: URL(string: "dayly://detail/\(entry.id)")!) {
                        Color.clear
                            .contentShape(Rectangle())
                    }

                    Button(intent: NextEventIntent()) {
                        Color.clear
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(theme.bg)
        .widgetURL(entry.totalCount <= 1 ? URL(string: "dayly://detail/\(entry.id)") : nil)
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
