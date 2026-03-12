# Android 홈화면 위젯 개발 가이드

> dayly 앱의 Android 홈화면 위젯 구조, 동작 원리, 수정 방법을 정리한 문서.
> 처음 코드를 보는 사람도 혼자 수정할 수 있도록 작성됨.

---

## 목차

1. [전체 구조 한눈에 보기](#1-전체-구조-한눈에-보기)
2. [파일 구조](#2-파일-구조)
3. [데이터 흐름: Flutter → 위젯](#3-데이터-흐름-flutter--위젯)
4. [핵심 개념: RemoteViews와 StackView](#4-핵심-개념-remoteviews와-stackview)
5. [위젯 업데이트 타이밍](#5-위젯-업데이트-타이밍)
6. [테마 시스템](#6-테마-시스템)
7. [자주 하는 수정 작업](#7-자주-하는-수정-작업)
8. [새 크기 위젯 추가하는 법](#8-새-크기-위젯-추가하는-법)
9. [새 테마 추가하는 법](#9-새-테마-추가하는-법)
10. [알려진 함정과 주의사항](#10-알려진-함정과-주의사항)
11. [디버깅 팁](#11-디버깅-팁)

---

## 1. 전체 구조 한눈에 보기

```
Flutter 앱 (Dart)
    └─ DaylyWidgetStorage.saveWidgetsToNative()
           └─ SharedPreferences에 JSON 저장 ("HomeWidgetPreferences" / "dayly_widgets_json")

Android 위젯 시스템
    ├─ DaylyAppWidget         ← Small(2×2) 위젯 Provider
    ├─ DaylyAppWidgetMedium   ← Medium(4×2) 위젯 Provider (DaylyAppWidget 상속)
    │
    ├─ updateWidget()         ← 공통 렌더링 로직 (companion object)
    │       └─ RemoteViews로 컨테이너 레이아웃 구성
    │       └─ StackView에 RemoteViewsService 연결
    │
    └─ DaylyWidgetRemoteViewsService
            └─ DaylyRemoteViewsFactory
                    └─ SharedPreferences JSON 읽기
                    └─ getViewAt() → 각 D-Day 카드를 RemoteViews로 반환
```

**핵심 원칙**: Android 위젯은 별도 프로세스에서 렌더링된다. 일반 View를 직접 쓸 수 없고, `RemoteViews`라는 제한된 뷰 시스템을 통해서만 UI를 그릴 수 있다.

---

## 2. 파일 구조

```
android/app/src/main/
├── kotlin/juny/dayly/
│   ├── DaylyAppWidget.kt               ← Small 위젯 Provider + 공통 로직
│   ├── DaylyAppWidgetMedium.kt         ← Medium 위젯 Provider
│   └── DaylyWidgetRemoteViewsService.kt ← StackView 아이템 데이터 공급
│
├── res/
│   ├── layout/
│   │   ├── dayly_widget_small.xml              ← Small 위젯 컨테이너 (StackView 포함)
│   │   ├── dayly_widget_medium.xml             ← Medium 위젯 컨테이너 (StackView 포함)
│   │   ├── dayly_widget_stack_item_small.xml   ← Small 카드 1장 레이아웃
│   │   └── dayly_widget_stack_item_medium.xml  ← Medium 카드 1장 레이아웃
│   │
│   ├── xml/
│   │   ├── dayly_widget_info_small.xml   ← Small 위젯 메타정보 (크기, 업데이트 주기 등)
│   │   └── dayly_widget_info_medium.xml  ← Medium 위젯 메타정보
│   │
│   └── drawable/
│       ├── dayly_widget_bg.xml           ← night 테마 배경
│       ├── dayly_widget_bg_paper.xml     ← paper 테마 배경
│       ├── dayly_widget_bg_fog.xml       ← fog 테마 배경
│       ├── dayly_widget_bg_lavender.xml  ← lavender 테마 배경
│       └── dayly_widget_bg_blush.xml     ← blush 테마 배경
│
└── AndroidManifest.xml  ← 두 Provider 모두 receiver로 등록되어 있음
```

### 레이아웃 2단계 구조

위젯 레이아웃은 **컨테이너**와 **카드 아이템** 두 단계로 나뉜다.

| 역할 | Small 파일 | Medium 파일 |
|------|-----------|-------------|
| 컨테이너 (StackView 껍데기) | `dayly_widget_small.xml` | `dayly_widget_medium.xml` |
| 카드 1장 (실제 내용) | `dayly_widget_stack_item_small.xml` | `dayly_widget_stack_item_medium.xml` |

컨테이너는 거의 손댈 일이 없다. 실제 디자인 변경은 대부분 **stack_item** 파일에서 한다.

---

## 3. 데이터 흐름: Flutter → 위젯

### Flutter 쪽 (Dart)

`lib/storage/dayly_widget_storage.dart`에서 위젯 목록을 저장할 때 native SharedPreferences에도 동기화한다.

```dart
// Flutter → Native로 보내는 JSON 구조 (배열)
[
  {
    "id": "uuid-1234",
    "sentence": "설레는 그 날까지",
    "targetDate": "2026-06-01",       // yyyy-MM-dd
    "targetDateLabel": "2026.06.01",  // 표시용 문자열
    "countdownMode": "dMinus",        // days | dMinus | weeksDays | mornings | nights | hidden
    "themePreset": "night"            // night | paper | fog | lavender | blush
  },
  ...
]
```

저장 위치:
- **SharedPreferences 이름**: `HomeWidgetPreferences`
- **키**: `dayly_widgets_json`

### Android 쪽 (Kotlin)

`DaylyRemoteViewsFactory.onDataSetChanged()`에서 이 JSON을 읽어 `WidgetDisplayData` 리스트로 변환한다.

```kotlin
// DaylyWidgetRemoteViewsService.kt 하단 companion object
private const val HW_PREFS = "HomeWidgetPreferences"
private const val KEY_WIDGETS_JSON = "dayly_widgets_json"
```

> **중요**: Flutter에서 저장하는 SharedPreferences 키 이름과 Kotlin에서 읽는 키 이름이 반드시 일치해야 한다. 어느 한쪽만 바꾸면 위젯이 빈 화면으로 표시된다.

---

## 4. 핵심 개념: RemoteViews와 StackView

### RemoteViews란?

Android 위젯은 앱 프로세스가 아닌 런처(홈화면) 프로세스에서 렌더링된다. 그래서 일반 `View`나 `Fragment`를 직접 사용할 수 없고, `RemoteViews`라는 직렬화 가능한 뷰 래퍼를 써야 한다.

**RemoteViews에서 쓸 수 있는 뷰 목록** (이것 외에는 crash):
- `TextView`, `ImageView`, `Button`, `ImageButton`
- `FrameLayout`, `LinearLayout`, `RelativeLayout`, `GridLayout`
- `ListView`, `GridView`, `StackView`, `AdapterViewFlipper`
- `ProgressBar`, `Chronometer`, `AnalogClock`

**주의**: `View` (기본 클래스), `RecyclerView`, 커스텀 뷰는 쓸 수 없다.
현재 `dayly_widget_stack_item_medium.xml`에서 구분점 dot에 `View` 태그를 사용하는 부분이 있는데, 일부 구형 기기에서 문제가 될 수 있다. 이슈 발생 시 `ImageView`로 교체하는 것을 권장한다.

### StackView와 RemoteViewsService

여러 D-Day 이벤트를 스와이프로 넘겨볼 수 있는 것은 `StackView` + `RemoteViewsService` 조합 덕분이다.

```
StackView (컨테이너에 배치)
    └─ RemoteViewsService (데이터 공급자 서비스)
            └─ RemoteViewsFactory (실제 데이터 로직)
                    ├─ getCount()        → 총 카드 수
                    ├─ getViewAt(i)      → i번째 카드 RemoteViews 반환
                    └─ onDataSetChanged() → 데이터 새로고침
```

`notifyAppWidgetViewDataChanged()`를 호출하면 `onDataSetChanged()`가 트리거되어 데이터가 갱신된다.

### 클릭 이벤트: PendingIntentTemplate + FillInIntent

StackView 아이템의 클릭은 두 단계로 처리된다:

```kotlin
// 1단계: Provider에서 템플릿 PendingIntent 등록 (공통 액션)
views.setPendingIntentTemplate(R.id.widget_stack, pendingIntent)

// 2단계: Factory의 getViewAt()에서 아이템별 고유 데이터 채워넣기
val fillInIntent = Intent().apply {
    this.data = Uri.parse("dayly://detail/${data.id}")
}
setOnClickFillInIntent(R.id.widget_container, fillInIntent)
```

최종 Intent = 템플릿 + fill-in이 병합된 결과. `FLAG_MUTABLE`이 템플릿 PendingIntent에 필수다.

---

## 5. 위젯 업데이트 타이밍

위젯은 세 가지 경로로 업데이트된다:

| 경로 | 주기 | 담당 |
|------|------|------|
| `updatePeriodMillis` | 30분마다 | `dayly_widget_info_small/medium.xml` |
| 자정 AlarmManager | 매일 00:00:01 | `DaylyAppWidget.scheduleMidnightUpdate()` |
| Flutter 앱 데이터 변경 | 앱 저장 직후 | `home_widget` Flutter 패키지 |

**자정 업데이트 구조**:
- `onEnabled()` (첫 위젯 추가 시) → `scheduleMidnightUpdate()` 호출
- 알람 발동 → `ACTION_MIDNIGHT_UPDATE` 브로드캐스트
- `DaylyAppWidget.onReceive()` → small 위젯 업데이트 + 다음 날 알람 재예약
- `DaylyAppWidgetMedium.onReceive()` → medium 위젯 업데이트

**Android 12+ 주의사항**: `SCHEDULE_EXACT_ALARM` 권한을 사용자가 거부하면 `setExactAndAllowWhileIdle()`이 실패한다. 이 경우 `setWindow()` (±5분)으로 fallback된다.

---

## 6. 테마 시스템

### 현재 테마 목록

| 테마 키 | 배경 drawable | 배경 분위기 | 텍스트 |
|---------|--------------|------------|--------|
| `night` | `dayly_widget_bg` | 어두운 남색 그라데이션 | 밝은 색 |
| `paper` | `dayly_widget_bg_paper` | 크림/종이 느낌 | 어두운 색 |
| `fog` | `dayly_widget_bg_fog` | 안개/회색 느낌 | 어두운 색 |
| `lavender` | `dayly_widget_bg_lavender` | 연보라 느낌 | 어두운 색 |
| `blush` | `dayly_widget_bg_blush` | 연분홍 느낌 | 어두운 색 |

### 색상 결정 위치

`DaylyWidgetRemoteViewsService.kt`의 `themeColors()` 함수:

```kotlin
private fun themeColors(preset: String): WidgetThemeColors = when (preset) {
    "paper" -> WidgetThemeColors(
        bgDrawable    = R.drawable.dayly_widget_bg_paper,
        textColor     = Color.parseColor("#0B1220"),  // 카운트다운 숫자
        subColor      = Color.parseColor("#6B7280"),  // 감성 문구, 날짜
        dotColor      = Color.parseColor("#9090A8"),  // 구분점, 페이지 인디케이터
        watermarkColor= Color.parseColor("#C0C8D0"),  // "dayly" 워터마크
    )
    // ...
}
```

---

## 7. 자주 하는 수정 작업

### 텍스트 크기 바꾸기

**Small 카드** → `res/layout/dayly_widget_stack_item_small.xml`
```xml
android:id="@+id/widget_countdown"  → android:textSize="22sp"  (카운트다운 숫자)
android:id="@+id/widget_sentence"   → android:textSize="9sp"   (감성 문구)
```

**Medium 카드** → `res/layout/dayly_widget_stack_item_medium.xml`
```xml
android:id="@+id/widget_countdown"  → android:textSize="38sp"
android:id="@+id/widget_sentence"   → android:textSize="13sp"
android:id="@+id/widget_date_label" → android:textSize="10sp"
```

### 카운트다운 포맷 바꾸기

`DaylyAppWidget.kt`의 `buildCountdownText()` 함수를 수정한다. Flutter의 `lib/utils/dayly_sentence_templates.dart`와 동일한 로직이어야 한다. **둘이 다르면 앱과 위젯에서 다른 텍스트가 표시된다.**

```kotlin
"dMinus" -> if (dayDiff == 0) "D-Day" else if (dayDiff > 0) "D-$days" else "D+$days"
```

### 배경 모서리 둥글기 바꾸기

각 테마 drawable XML에서 수정:
```xml
<!-- res/drawable/dayly_widget_bg.xml -->
<corners android:radius="20dp" />  ← 이 값을 바꾼다
```

---

## 8. 새 크기 위젯 추가하는 법

예시: `Large(4×4)` 위젯 추가

### Step 1: 레이아웃 XML 만들기

`res/layout/dayly_widget_large.xml` — 컨테이너 (StackView 껍데기, small/medium과 동일한 구조)

`res/layout/dayly_widget_stack_item_large.xml` — 카드 아이템 레이아웃

### Step 2: 위젯 메타정보 XML 만들기

`res/xml/dayly_widget_info_large.xml`:
```xml
<appwidget-provider ...
    android:minWidth="250dp"
    android:minHeight="250dp"
    android:targetCellWidth="4"
    android:targetCellHeight="4"
    android:initialLayout="@layout/dayly_widget_large"
    android:previewLayout="@layout/dayly_widget_stack_item_large"
    android:resizeMode="horizontal|vertical"
    android:updatePeriodMillis="1800000"
    android:widgetCategory="home_screen" />
```

### Step 3: Provider 클래스 만들기

`DaylyAppWidgetLarge.kt`:
```kotlin
class DaylyAppWidgetLarge : DaylyAppWidget() {
    override fun onUpdate(...) {
        appWidgetIds.forEach { id ->
            updateWidget(context, appWidgetManager, id, forceMedium = false, forceLarge = true)
        }
    }
    // onAppWidgetOptionsChanged, onReceive도 동일하게 override
}
```

`DaylyAppWidget.updateWidget()`에 `forceLarge` 파라미터를 추가하고,
`DaylyWidgetRemoteViewsService`에 `EXTRA_IS_LARGE` extra를 추가해야 한다.

### Step 4: 매니페스트에 등록

`AndroidManifest.xml`:
```xml
<receiver android:name=".DaylyAppWidgetLarge" android:exported="false">
    <intent-filter>
        <action android:name="android.appwidget.action.APPWIDGET_UPDATE"/>
        <action android:name="juny.dayly.MIDNIGHT_UPDATE"/>
    </intent-filter>
    <meta-data
        android:name="android.appwidget.provider"
        android:resource="@xml/dayly_widget_info_large"/>
</receiver>
```

### Step 5: RemoteViewsFactory에서 large 레이아웃 처리

`DaylyWidgetRemoteViewsService.kt`의 `getViewAt()`에 large 분기 추가.

---

## 9. 새 테마 추가하는 법

예시: `ocean` 테마 추가

### Step 1: 배경 drawable 만들기

`res/drawable/dayly_widget_bg_ocean.xml`:
```xml
<shape android:shape="rectangle">
    <gradient android:type="linear" android:angle="135"
        android:startColor="#0A1A2A" android:endColor="#0D2540" />
    <corners android:radius="20dp" />
</shape>
```

### Step 2: themeColors()에 케이스 추가

`DaylyWidgetRemoteViewsService.kt`:
```kotlin
"ocean" -> WidgetThemeColors(
    bgDrawable     = R.drawable.dayly_widget_bg_ocean,
    textColor      = Color.parseColor("#E0F0FF"),
    subColor       = Color.parseColor("#7090A8"),
    dotColor       = Color.parseColor("#3060A0"),
    watermarkColor = Color.parseColor("#1A3050"),
)
```

### Step 3: Flutter 쪽도 추가

`lib/theme/dayly_theme_presets.dart`에 `DaylyThemePreset.ocean` 추가.
Flutter에서 저장하는 `themePreset` 문자열이 `"ocean"`이어야 Kotlin의 `when` 분기가 매칭된다.

---

## 10. 알려진 함정과 주의사항

### RemoteViews 크기 제한

RemoteViews 객체의 총 크기는 **1MB 이하**여야 한다. 이미지를 직접 넣으려고 하면 이 제한에 걸릴 수 있다. 위젯 배경은 반드시 XML drawable로 만들고, 비트맵 이미지 직접 삽입은 피한다.

### StackView URI 고유성

각 위젯 인스턴스가 독립적인 데이터 Factory를 갖도록 serviceIntent에 고유 URI를 설정한다:
```kotlin
data = Uri.parse("dayly://widget/$appWidgetId/$isMedium")
```
이 URI를 제거하거나 변경하면 여러 위젯 인스턴스가 같은 Factory를 공유해서 데이터가 섞인다.

### setRemoteAdapter 후 반드시 notifyAppWidgetViewDataChanged 호출

```kotlin
appWidgetManager.updateAppWidget(appWidgetId, views)
appWidgetManager.notifyAppWidgetViewDataChanged(appWidgetId, R.id.widget_stack)  // ← 이게 없으면 StackView가 빈 화면
```

### Samsung One UI 런처 특이사항

삼성 런처는 위젯 크기 조정 시 "remove → re-add" 방식으로 처리하는 경우가 있다. 이때 Provider가 실패하면 "Couldn't add widget" 에러가 표시된다. 각 크기를 별도 Provider 클래스로 분리한 이유가 여기에 있다.

### countdownMode 동기화

`DaylyAppWidget.buildCountdownText()`와 Flutter의 `buildCountdownPhrase()`는 동일한 로직이어야 한다. 한쪽만 바꾸면 앱과 위젯의 표시가 달라진다.

### 자정 알람 취소 주의

`onDisabled()`는 해당 Provider의 마지막 위젯이 삭제될 때 호출된다. `DaylyAppWidget.onDisabled()`는 자정 알람을 취소하는데, Small 위젯을 모두 지우면 Medium 위젯이 남아있어도 알람이 취소된다. 이 경우 Medium 위젯은 `updatePeriodMillis` (30분 주기)로만 업데이트된다.

### exported 속성

Android 12(API 31)부터 intent-filter가 있는 receiver는 `exported` 속성을 명시해야 한다. 현재 `android:exported="false"`로 설정되어 있는데, 시스템 브로드캐스트는 이와 무관하게 수신된다. 일부 런처(특히 EMUI, MIUI)에서 `exported="true"`가 필요할 수 있으니 이슈 발생 시 확인한다.

---

## 11. 디버깅 팁

### 위젯이 아예 안 보일 때

1. `AndroidManifest.xml`에 receiver가 등록되어 있는지 확인
2. `dayly_widget_info_*.xml`의 `android:initialLayout`이 존재하는 레이아웃 파일을 가리키는지 확인
3. `res/xml/` 폴더에 provider info XML이 있는지 확인

### 위젯이 비어있을 때 (데이터 없음)

1. Flutter에서 데이터를 저장한 후 위젯을 업데이트하는지 확인
2. SharedPreferences 키가 `"HomeWidgetPreferences"` / `"dayly_widgets_json"`으로 일치하는지 확인
3. adb로 직접 확인:
   ```bash
   adb shell run-as juny.dayly cat /data/data/juny.dayly/shared_prefs/HomeWidgetPreferences.xml
   ```

### "Couldn't add widget" 에러

1. 레이아웃 XML에 존재하지 않는 view ID를 참조하는지 확인
2. RemoteViews에서 지원하지 않는 View 타입을 사용하는지 확인
3. `DaylyWidgetRemoteViewsService`가 manifest에 `BIND_REMOTEVIEWS` permission으로 등록되어 있는지 확인
4. 로그캣에서 `AppWidgetService` 태그로 상세 에러 확인:
   ```bash
   adb logcat -s AppWidgetService:E AppWidgetProvider:E
   ```

### 위젯 클릭이 안 될 때

1. `setPendingIntentTemplate()`이 호출되었는지 확인
2. PendingIntent에 `FLAG_MUTABLE`이 있는지 확인 (fill-in intent 병합에 필수)
3. `setOnClickFillInIntent()`가 `R.id.widget_container`에 걸려있는지 확인

### 강제 업데이트 (개발 중)

```bash
# 위젯 강제 업데이트 브로드캐스트 발송
adb shell am broadcast -a android.appwidget.action.APPWIDGET_UPDATE \
  -n juny.dayly/.DaylyAppWidget
```

---

*마지막 업데이트: 2026-03-12*
