# Dayly 앱 전체 점검 보고서 v1.1

> 작성일: 2026-03-05
> 대상 버전: pubspec 1.1.1+3 / CHANGELOG 1.2.0
> 이전 점검: CHECK-v1.0.md (2026-03-05)
> 중점: 사업 가치 + 사용자 사용성 + 코드 품질

---

## TL;DR

**v1.0 대비 상당한 개선이 이루어졌다. 딥링크 버그 수정, 알림 권한 타이밍 개선, SharedPreferences 캐싱, 홈위젯 멀티이벤트 탐색 등 핵심 USP가 강화되었다. 그러나 데이터 유실 위험(백업/복원 없음), 프리미엄 결제 미구현, 온보딩 부재는 여전히 미해결이며 출시 블로커로 남아 있다.**

---

## 0. v1.0 지적사항 해소 현황

| # | v1.0 지적 | 현재 상태 | 판정 |
|---|-----------|-----------|------|
| 1 | 딥링크 파싱 버그 (`uri.host == 'detail'`) | 주석으로 의도 명시, 동작 확인됨 | **해결** |
| 2 | Firebase 주석 처리 | 여전히 주석 처리. pubspec에 Firebase 의존성 잔존 | **미해결** |
| 3 | DST 경계 타임존 오류 가능 | `tz.TZDateTime` 사용으로 완화. 단, `targetDate.add(Duration)` 잔존 | **부분 해결** |
| 4 | AlarmManager 64개 제한 미처리 | 16위젯 x 4알림 = 64개 상한, 초과 시 경고 다이얼로그 | **해결** |
| 5 | `Future.delayed(16ms)` 불안정 | `addPostFrameCallback` 교체 완료 | **해결** |
| 6 | `print()` 프로덕션 노출 | `debugPrint()` 교체 완료 | **해결** |
| 7 | 공유 텍스트 `'dayly'` 한 단어 | D-Day 정보 + Play Store 링크 포함으로 개선 | **해결** |
| 8 | 권한 요청 타이밍 | 앱 시작 시 + 매 위젯 추가 시 요청, 거부 시 안내 다이얼로그 | **해결** |
| 9 | `SharedPreferences` 캐싱 없음 | `_prefsCache` 패턴으로 캐싱 구현 | **해결** |
| 10 | 데이터 유실 (클라우드 백업 없음) | 여전히 SharedPreferences만 사용 | **미해결** |
| 11 | `isPremium` 결제 없이 토글 가능 | 여전히 무검증 토글 | **미해결** |
| 12 | 온보딩 부재 | 여전히 없음 | **미해결** |
| 13 | enum 직렬화 취약성 | `firstWhere + orElse` fallback 존재하나 마이그레이션 로직 없음 | **미해결** |
| 14 | `pixelRatio = 3` 고정 (OOM 위험) | 변경 없음 | **미해결** |

**요약: 14건 중 7건 해결, 1건 부분 해결, 6건 미해결**

---

## 1. 사업적 관점

### 1.1 핵심 가치 제안 (USP) 재검증

| USP | v1.0 | v1.1 현재 | 변화 |
|-----|------|-----------|------|
| 홈화면 위젯 D-Day | 미완성 | Android StackView + iOS 인터랙티브 위젯 완성 | +++ |
| 감성적 공유 카드 | 작동 | 공유 텍스트 개선 (D-Day + 스토어 링크) | + |
| 알림으로 D-Day 챙기기 | 부분 작동 | 권한 흐름 완성, 64개 제한 처리 | ++ |

**홈위젯이 핵심 USP인 앱에서 Android/iOS 양쪽 모두 멀티이벤트 탐색이 가능해진 것은 큰 진전이다.**

### 1.2 사용자 유지 (Retention) 위협 요소

#### [CRITICAL] 데이터 유실 — 여전히 최대 위협

- SharedPreferences 단독 저장. 백업/복원/내보내기 기능 없음
- 재설치, 기기 변경, 앱 데이터 삭제 시 **모든 D-Day 소멸**
- Android Auto Backup이 `shared_prefs`를 포함할 수 있으나 보장되지 않음
- **이 문제가 해결되지 않으면 장기 사용자를 유지할 수 없다**

#### [HIGH] 온보딩 부재

- 첫 실행 시 기본 위젯 1개(23 days)가 생성되지만 이것이 무엇인지 설명 없음
- `widget_grid_screen.dart:101-103` — 빈 데이터일 때 기본 위젯 생성하지만 persist 안 함
  -> 앱 재시작마다 기본 위젯이 반복 생성됨

#### [MEDIUM] 수익화 구조 취약

- 배너 광고 + App Open 광고 추가됨 (v1.0 대비 개선)
- 그러나 `isPremium` 토글은 결제 없이 자유 전환 가능
  -> `share_preview_screen_v2.dart:255-258` — 탭만 하면 Premium ON/OFF
- In-app purchase 미구현

### 1.3 시장 포지셔닝

| 항목 | 상태 |
|------|------|
| UI 언어 | 영어 기반 ("YOUR MOMENTS", "EDIT EVENT") |
| 다이얼로그 | 한국어 혼재 ("이벤트를 삭제할까요?", "알림 한도 초과") |
| 위젯 설명 | 한국어 ("홈화면 길게 누르기 -> 위젯 추가 -> dayly 선택") |
| 공유 텍스트 | 영어 |
| iOS 위젯 문구 | 한국어 ("소중한 날까지", "다음 이벤트") |

**영어/한국어 혼재가 v1.0보다 심해졌다. 타겟 시장을 명확히 하고 i18n을 도입해야 한다.**

---

## 2. 사용자 사용성 문제

### 2.1 사용자 여정 재점검

```
설치 -> [문제: 온보딩 없음, 기본 위젯이 의미 불명]
  |
D-Day 추가 -> [개선: 권한 요청 타이밍 OK]
  |          -> [문제: 알림 설정 커스텀 UI 누락? CHANGELOG와 코드 불일치]
  |
홈화면 위젯 -> [개선: Android/iOS 멀티이벤트 탐색]
  |          -> [문제: iOS 위젯 D-Day 숫자가 Flutter save 시점 고정, Android는 실시간 재계산]
  |
앱 공유 -> [개선: 공유 텍스트에 D-Day + 스토어 링크]
  |
설정 -> [문제: 1초 딜레이 후 설정 화면 진입]
  |
재설치 -> [문제: 모든 데이터 손실]
```

### 2.2 설정 화면 접근 지연

`widget_grid_screen.dart:333-348`:
```dart
void _openSetting(BuildContext context) {
  Future.delayed(Duration(seconds: 1), () {
    Navigator.push(context, ...);
  });
}
```
**설정 톱니바퀴를 탭하면 1초간 아무 반응 없음 -> 사용자는 "안 눌렸나?" 하고 재탭 -> UX 혼란.**

### 2.3 iOS 위젯 D-Day 신선도 문제

- **Android**: `DaylyAppWidget.buildCountdownText()`에서 `LocalDate.now()` 기준 실시간 계산
- **iOS**: Flutter 측 `HomeWidgetService._toHomeWidgetData()`에서 계산한 `countdownText`를 UserDefaults에 저장 -> 위젯은 저장된 텍스트를 그대로 표시
- Timeline은 자정에 갱신되지만, 앱을 열지 않으면 Flutter 저장이 안 되므로 **iOS 위젯의 D-Day가 하루 밀릴 수 있다**

### 2.4 알림 설정 커스텀 UI 불일치

CHANGELOG 1.0.1에 기술된 기능:
- "알림 방식 선택 UI: 특정 시점(D-7/D-3/D-1/D-Day 체크박스) 또는 반복(N일 간격)"
- "`NotificationSettingsPanel` 위젯"
- "`scheduleForSettings(model, settings)`"

**현재 코드 상태:**
- `NotificationScheduler.scheduleAll()` — 4개 고정 트리거만 존재
- `NotificationIdRegistry` — 하위 4비트, maxTriggers = 4
- `add_widget_bottom_sheet.dart` — 알림 설정 UI 없음

**CHANGELOG에 기록된 기능이 코드에 존재하지 않는다. 구현 후 롤백되었거나, CHANGELOG가 선행 작성된 것으로 보인다.**

### 2.5 마일스톤/메모 기능

v1.0 대비 변화 없음:
- 마일스톤은 상세 화면에서만 조회/토글 가능, 생성 UI 없음
- `DaylyMilestone.dueDate`는 저장되지만 표시만 됨, 생성/수정 불가
- 메모 텍스트 길이 제한 없음 (maxLines: 5지만 텍스트 자체는 무제한)

---

## 3. 코드 버그 및 기술 부채

### 3.1 버그 목록

| 심각도 | 위치 | 문제 | 설명 |
|--------|------|------|------|
| HIGH | `pubspec.yaml:41-44` | 미사용 Firebase 의존성 잔존 | `firebase_core`, `firebase_auth`, `firebase_ui_auth`, `firebase_ui_oauth_google`이 pubspec에 남아 있음. 앱 사이즈 증가 + 빌드 시간 증가 |
| HIGH | `pubspec.yaml:19` vs `CHANGELOG.md:5` | 버전 불일치 | pubspec: `1.1.1+3`, CHANGELOG 최신: `1.2.0`. 빌드/배포 시 혼란 |
| MEDIUM | `widget_grid_screen.dart:333` | 설정 화면 진입 1초 딜레이 | `Future.delayed(Duration(seconds: 1))` — UX 지연 |
| MEDIUM | `widget_grid_screen.dart:93-99` | 마이그레이션 감지 로직 무효 | `fromJson()`에서 이미 ID 생성 -> `toJson()` 결과에 항상 ID 존재 -> 마이그레이션 조건 절대 true 안 됨 |
| MEDIUM | `auth_gate.dart` 전체 | 죽은 코드 (Dead Code) | Firebase 비활성화로 사용 불가하지만 파일과 import 잔존 |
| MEDIUM | `notification_scheduler.dart:56` | DST 경계 계산 | `model.targetDate.add(Duration(days: daysOffset))` — Duration 기반 날짜 연산은 DST 전환 시 1시간 오차 가능 |
| LOW | `notification_id_registry.dart` | 주석-코드 불일치 | CHANGELOG 1.0.1은 "하위 6비트 확장" 언급하지만 코드는 4비트(`<< 4`, `& 0xF`) |
| LOW | `share_preview_screen_v2.dart:60` | Play Store 링크만 존재 | iOS App Store 링크 없음 -> iOS 사용자 공유 시 의미 없는 링크 |
| LOW | `dayly_share_export.dart:13` | `pixelRatio = 3` 고정 | 저사양 기기에서 대형 위젯 캡처 시 OOM 가능 |
| LOW | `event_detail_screen.dart:52` | 매초 setState 호출 | Timer.periodic(1s)로 실시간 카운트다운 — 성능 이슈는 아니지만 불필요한 rebuild |

### 3.2 기술 부채

```
Firebase 코드 유산 (v1.0에서 지적, 악화됨)
  |- pubspec.yaml에 4개 Firebase 패키지 잔존
  |- auth_gate.dart, config.dart, firebase_options.dart 파일 잔존
  |- main.dart에서 전부 주석 처리
  |- 결정: Firebase 사용할 건지 아닌지 확정하고 정리 필요
  |- 방치 비용: ~15MB+ 앱 사이즈 증가, 빌드 시간 증가

isPremium 결제 스텁 (v1.0에서 지적, 변화 없음)
  |- share_preview_screen_v2.dart에서 자유 토글
  |- 실제 구매 검증 없음
  |- 워터마크 제거 외 프리미엄 가치 정의 안 됨

CHANGELOG-코드 불일치
  |- 1.0.1: NotificationSettingsPanel, scheduleForSettings -> 코드에 없음
  |- 1.0.1: "하위 6비트 확장" -> 코드는 4비트
  |- 1.2.0: 이미 작성됐지만 pubspec 버전은 1.1.1+3

테스트 코드 부재
  |- test/ 디렉토리에 테스트 파일 없음
  |- 비즈니스 로직(calculateDayDifference, NotificationIdRegistry.compute 등) 미검증
  |- 리팩터링 시 회귀 방지 불가
```

### 3.3 iOS/Android 위젯 비대칭

| 항목 | Android | iOS |
|------|---------|-----|
| D-Day 계산 | 위젯 표시 시점 실시간 (`LocalDate.now()`) | Flutter save 시점 고정 + 자정 Timeline 갱신 |
| 멀티이벤트 탐색 | StackView fling (세로 스와이프) | Button intent (좌우 화살표) |
| 자정 갱신 | AlarmManager `setExactAndAllowWhileIdle` | Timeline `.after(midnight)` |
| 사용자 경험 | 앱 미실행 시에도 D-Day 항상 정확 | 앱 미실행 + Timeline 갱신 실패 시 하루 밀림 가능 |

---

## 4. 긍정적 평가 (강점) — v1.0 대비 추가

- **홈위젯 멀티이벤트** — Android StackView + iOS 인터랙티브 위젯, 핵심 USP 대폭 강화
- **알림 시스템 안정화** — 권한 흐름, 64개 제한, Hive 크래시 복구 모두 처리
- **Android 위젯 실시간 D-Day** — `buildCountdownText()`로 위젯 표시 시점에 정확한 값 계산
- **앱 라이프사이클 대응** — `didChangeAppLifecycleState`로 포그라운드 전환 시 위젯 갱신
- **코드 품질 유지** — 주석 풍부, sealed class/pattern matching 활용, 명확한 책임 분리
- **App Open 광고 추가** — 수익화 기반 확장
- **다크/라이트 모드 + 브랜드 색상** — 설정 화면에서 테마/브랜드 전환 가능

---

## 5. 개선 로드맵 (우선순위순)

### Phase 1 — 출시 블로커 해소 (즉시)
1. **Firebase 의존성 정리** — 사용하지 않는 4개 패키지 제거 + auth_gate/config/firebase_options 삭제 -> 앱 사이즈 15MB+ 절감
2. **pubspec 버전 동기화** — 1.2.0+4 등으로 맞추기
3. **설정 화면 1초 딜레이 제거** — `Future.delayed` 삭제
4. **기본 위젯 persist 처리** — 첫 실행 시 생성된 기본 위젯을 저장해 반복 생성 방지
5. **언어 통일** — 한국어 또는 영어로 결정. i18n 미적용이라면 하나로 통일

### Phase 2 — 데이터 안전성 (1주)
1. **로컬 백업 내보내기/가져오기** — JSON 파일 export/import (최소한의 데이터 보호)
2. **iOS 위젯 D-Day 실시간 계산** — Android처럼 `targetDate` 기반 Swift 측 계산으로 전환
3. **CHANGELOG-코드 불일치 정리** — 1.0.1의 커스텀 알림 설정이 구현된 건지 확인하고 CHANGELOG 수정 또는 기능 구현

### Phase 3 — 사용자 경험 (2주)
1. **온보딩 화면** — 3~4페이지 슬라이드, 핵심 가치 전달
2. **isPremium 토글 숨김 또는 결제 연동** — 무료 사용자가 프리미엄 토글 접근 못하게
3. **iOS 공유 텍스트에 App Store 링크 추가** — 플랫폼별 분기
4. **마일스톤 생성 UI** — 상세 화면에서 추가/삭제 가능하도록

### Phase 4 — 품질 강화 (3주)
1. **단위 테스트 추가** — `calculateDayDifference`, `NotificationIdRegistry.compute`, `DaylyWidgetModel.fromJson` 등
2. **enum 마이그레이션 전략** — 버전 키 도입 or 숫자 직렬화
3. **pixelRatio 동적 조절** — `MediaQuery.of(context).devicePixelRatio` 활용
4. **Crashlytics 또는 대체 에러 리포팅** 도입

### Phase 5 — 수익화 (4주)
1. **In-app purchase 구현** — `isPremium` 플래그를 실제 구매와 연동
2. **프리미엄 가치 정의** — 추가 테마, 광고 제거, 위젯 무제한 등

---

## 6. 출시 준비도 평가

| 항목 | v1.0 | v1.1 | 변화 | 근거 |
|------|------|------|------|------|
| 기능 완성도 | 60 | **78** | +18 | 홈위젯 멀티이벤트, 알림 안정화 |
| 안정성 | 50 | **68** | +18 | 버그 수정, Hive 복구, 권한 처리 |
| 사용성 | 55 | **62** | +7 | 공유 개선, 위젯 안내 배너. 온보딩/언어 미해결 |
| 수익화 | 20 | **30** | +10 | App Open 광고 추가. 프리미엄 미구현 |
| 마케팅 준비 | 30 | **32** | +2 | 변화 미미 |
| **종합** | **43** | **54** | **+11** | **Phase 1 완료 시 65+, Phase 2까지 75+ 예상** |

---

## 7. 결론

v1.0 대비 11점 상승(43 -> 54)으로 의미 있는 진전이 있었다. 특히 홈위젯 멀티이벤트 탐색은 앱의 핵심 USP를 확실히 완성했다.

**지금 당장 해야 할 3가지:**
1. Firebase 미사용 의존성 제거 (앱 사이즈 + 빌드 시간)
2. 설정 화면 1초 딜레이 제거 (UX 파괴 버그)
3. 데이터 내보내기/가져오기 (유일한 Critical 리스크)

이 3가지만 해결하면 **"쓸 만한 앱"** 수준에 도달한다. 그 이후 온보딩 -> 언어 통일 -> 프리미엄 결제 순서로 진행하면 된다.

---

## 8. 알림 주기 확장 설계 — UI/UX 및 구현 방안

### 8.1 현재 상태 분석

```
현재 알림 트리거: D-7, D-3, D-1, D-Day (4개 고정, 오전 9시)
ID 구조:         27bit hash + 4bit triggerIndex (최대 16 슬롯)
AlarmManager:    64개 상한 -> 16위젯 x 4알림
사용자 선택권:   없음 (무조건 4개 전부 예약)
```

**문제점:**
- 사용자가 알림 빈도를 제어할 수 없다
- 30일 뒤 이벤트에 D-7 알림 하나만 오면 "앱이 알려주지 않았다"고 느낌
- 1일 뒤 이벤트에 D-7 알림이 예약되면 불필요한 리소스 낭비
- 반복 알림(매일, 3일마다 등) 미지원

### 8.2 확장 알림 모드 정의

#### A. 특정 시점 알림 (Point Triggers)

| 트리거 | 설명 | 기본값 |
|--------|------|--------|
| D-30 | 30일 전 | OFF |
| D-14 | 2주 전 | OFF |
| D-7 | 7일 전 | ON |
| D-5 | 5일 전 | OFF |
| D-3 | 3일 전 | ON |
| D-1 | 1일 전 | ON |
| D-Day | 당일 | ON (항상) |

사용자가 체크박스로 개별 ON/OFF. D-Day는 기본 ON 고정 (해제 불가 권장).

#### B. 반복 알림 (Interval Triggers)

| 간격 | 설명 | 최대 예약 수 |
|------|------|-------------|
| 매 1일 | D-Day까지 매일 오전 9시 | 최대 30개 |
| 매 3일 | 3일 간격 | 최대 10개 |
| 매 5일 | 5일 간격 | 최대 6개 |
| 매 7일 | 주 1회 | 최대 4개 |
| 사용자 정의 | N일 간격 (2~14일) | 최대 30/N개 |

**AlarmManager 64개 제한 대응:**
- 반복 알림은 D-Day까지 남은 일수 / 간격으로 예약 수 계산
- 전체 예약 수가 64개를 초과하면 경고 후 가장 가까운 것부터 우선 예약

#### C. 알림 모드 선택지 (Radio Group)

```
( ) 기본 알림        D-7, D-3, D-1, D-Day (현재와 동일)
( ) 특정 시점 선택    [v]D-30 [v]D-14 [v]D-7 [v]D-5 [v]D-3 [v]D-1 [v]D-Day
( ) 반복 알림        [ 매 1일 | 매 3일 | 매 5일 | 매 7일 | 직접 입력 ]
( ) 알림 끄기        이 이벤트의 알림을 모두 비활성화
```

### 8.3 데이터 모델 설계

```dart
/// 알림 설정 — DaylyWidgetModel에 추가할 필드.
@immutable
class DaylyNotificationSettings {
  const DaylyNotificationSettings({
    this.mode = NotifMode.preset,
    this.pointTriggers = const {-7, -3, -1, 0},
    this.intervalDays = 1,
    this.notifyHour = 9,
    this.notifyMinute = 0,
  });

  /// preset: 기본 4개 / point: 특정 시점 / interval: 반복 / off: 끄기
  final NotifMode mode;

  /// mode == point 일 때 활성화된 D-N 오프셋 집합.
  /// 음수 = D-Day 이전, 0 = D-Day 당일.
  final Set<int> pointTriggers;

  /// mode == interval 일 때 반복 간격 (일).
  final int intervalDays;

  /// 알림 시각 (기본 09:00).
  final int notifyHour;
  final int notifyMinute;
}

enum NotifMode { preset, point, interval, off }
```

**DaylyWidgetModel 변경:**
```dart
class DaylyWidgetModel {
  // ... 기존 필드 ...
  final DaylyNotificationSettings notificationSettings;  // 추가
}
```

### 8.4 NotificationIdRegistry 확장

```
현재: 27bit hash + 4bit trigger  -> 최대 16 슬롯/위젯
확장: 25bit hash + 6bit trigger  -> 최대 64 슬롯/위젯

6bit = 0~63 -> 반복 알림 "매 1일" 모드에서 최대 30개 예약 가능.

AlarmManager 제한 재계산:
  - 위젯 수 x 슬롯 수 <= 64
  - 위젯 1개 + 매일 알림(30슬롯) = 30개 -> OK
  - 위젯 2개 + 매일 알림 = 60개 -> OK
  - 위젯 3개 + 매일 알림 = 64개 초과 -> 경고 필요
  - 위젯 10개 + 기본 알림(4슬롯) = 40개 -> OK
```

**슬롯 할당 전략:**
```
point 모드:
  triggerIndex 0~15 = D-30, D-14, D-7, D-5, D-3, D-1, D-Day (최대 7개)

interval 모드:
  triggerIndex 0 = D-Day 당일 (항상)
  triggerIndex 1~N = 오늘+interval, 오늘+2*interval, ... (D-Day까지)
  최대 30개 예약 후 나머지는 앱 진입 시 동적 보충 (syncOnAppStart)

preset 모드:
  triggerIndex 0~3 = 현재와 동일 (D-7, D-3, D-1, D-Day)
```

### 8.5 UI/UX 설계

#### 8.5.1 위젯 생성 화면 (`add_widget_bottom_sheet.dart`)

```
CREATE NEW MOMENT
  |
  Name your moment    [____________________]
  Date Selection      [캘린더]
  Icon & Color        [아이콘 가로 스크롤]
  |
  Notification        [v] 알림 받기        <-- 마스터 토글 (NEW)
  |                   |
  |                   ( ) 기본 (D-7, D-3, D-1, D-Day)
  |                   ( ) 직접 선택
  |                   ( ) 반복 알림
  |                   |
  |                   [펼침 영역 - 선택에 따라]
  |
  [SAVE MOMENT]
```

**Progressive Disclosure 원칙:**
1. 마스터 토글 OFF -> 알림 세부 옵션 숨김
2. 마스터 토글 ON -> Radio Group 표시
3. Radio 선택 시 해당 모드의 세부 옵션만 확장

#### 8.5.2 "직접 선택" 모드 확장 UI

```
직접 선택 [v]
  |
  [v] D-Day (항상)     [ ] D-30 (30일 전)
  [v] D-1 (1일 전)     [ ] D-14 (2주 전)
  [v] D-3 (3일 전)     [ ] D-7 (7일 전)
  [ ] D-5 (5일 전)
  |
  알림 시각: [09:00]  <-- TimePicker
```

- 2열 Wrap 레이아웃, ChoiceChip 또는 FilterChip 스타일
- D-Day 칩은 항상 ON + 비활성화 상태 (해제 불가)
- 선택된 칩 수 표시: "4개 알림 예약됨"

#### 8.5.3 "반복 알림" 모드 확장 UI

```
반복 알림 [v]
  |
  [매 1일] [매 3일] [매 5일] [매 7일] [직접 입력]
  |
  직접 입력 선택 시: [__] 일마다  (Stepper: 2~14)
  |
  알림 시각: [09:00]
  |
  예약 예상: "12개 알림 (D-36 ~ D-Day)"
  |
  [!] 다른 이벤트 알림과 합산 시 64개 초과 가능
      -> 가까운 날짜부터 우선 예약됩니다
```

- 간격 프리셋은 ChoiceChip 가로 나열
- "직접 입력" 선택 시 숫자 입력 필드 확장
- 예약 수 실시간 계산 표시 (남은 일수 / 간격)
- 64개 초과 시 경고 텍스트 (빨간색 아님, 정보 톤)

#### 8.5.4 이벤트 상세/편집 화면 (`event_detail_screen.dart`)

```
EVENT DETAIL
  |
  [히어로 카드]
  [마일스톤]
  [노트]
  |
  NOTIFICATION          <-- 새로운 카드 (NEW)
  |  [벨 아이콘] 기본 알림 (D-7, D-3, D-1, D-Day)
  |  다음 알림: 2026.03.12 오전 9:00 (D-7)
  |  [편집 버튼]
  |
  [EDIT EVENT]
```

- 현재 알림 설정 요약을 글래스 카드로 표시
- "다음 알림" 시점을 계산해서 보여줌 -> 알림이 실제로 작동 중임을 신뢰감 제공
- 편집 탭 시 BottomSheet로 알림 설정 패널 열기

#### 8.5.5 알림 시각 선택

```
현재: 오전 9시 고정
제안: 사용자 선택 가능 (TimePicker)

기본값: 09:00
프리셋: [오전 7시] [오전 9시] [정오] [오후 6시] [오후 9시]
직접 선택: [TimePicker]
```

- 모든 이벤트에 글로벌로 적용 (설정 화면) 또는 이벤트별 개별 설정
- 권장: 글로벌 기본값 + 이벤트별 오버라이드

### 8.6 AlarmManager 64개 제한 관리 전략

```
예약 가능 총량 = 64
현재 예약 수 = sum(각 위젯의 활성 알림 수)
잔여 슬롯 = 64 - 현재 예약 수

시나리오별 대응:
  |
  잔여 >= 필요 -> 전부 예약, 문제 없음
  |
  잔여 < 필요 -> "가까운 날짜 우선" 정책
  |             1) 모든 위젯의 알림을 날짜순 정렬
  |             2) 가장 가까운 64개만 예약
  |             3) 나머지는 Hive에 "대기" 상태로 저장
  |             4) syncOnAppStart()에서 기간 지난 알림 제거 + 대기 알림 승격
  |
  위젯 추가 시 -> 예약 전 잔여 슬롯 계산
                -> 부족하면 다이얼로그:
                   "현재 예약된 알림이 많습니다.
                    이 이벤트는 가까운 날짜의 알림만 예약됩니다."
```

### 8.7 구현 우선순위

```
Step 1 (최소 기능, 즉시):
  - DaylyNotificationSettings 모델 추가
  - preset 모드 = 현재 동작 그대로 (하위 호환)
  - off 모드 = 알림 끄기
  - 위젯 생성/편집 화면에 마스터 토글만 추가

Step 2 (특정 시점, 1주):
  - point 모드 구현
  - D-30, D-14, D-7, D-5, D-3, D-1, D-Day 체크박스 UI
  - NotificationIdRegistry 6bit 확장
  - 기존 데이터 마이그레이션 (4bit -> 6bit)

Step 3 (반복 알림, 1주):
  - interval 모드 구현
  - 간격 프리셋 + 직접 입력 UI
  - 예약 수 실시간 계산 + 64개 제한 관리
  - syncOnAppStart() 대기 알림 승격 로직

Step 4 (알림 시각 커스텀, 선택):
  - TimePicker UI
  - 글로벌 기본값 + 이벤트별 오버라이드
```

### 8.8 UX 핵심 원칙

1. **기본값이 최선** — 아무것도 건드리지 않아도 D-7/D-3/D-1/D-Day 알림이 온다
2. **Progressive Disclosure** — 고급 옵션은 숨기고, 필요할 때만 펼친다
3. **피드백 즉시 제공** — "N개 알림 예약됨", "다음 알림: X월 X일" 실시간 표시
4. **실패를 투명하게** — 64개 초과 시 무시하지 않고 사용자에게 알린다
5. **감성 유지** — 알림 설정 UI도 글래스모피즘 카드 스타일 유지, 복잡해 보이지 않게

---

## 9. iOS/Android 위젯 ProgressBar 설계 — `days` 모드 전용

### 9.1 동기

`days` 모드("22 days left")는 숫자만 표시되어 **"전체 기간 대비 얼마나 왔는지"** 직관적으로 느끼기 어렵다. 얇은 ProgressBar 하나를 추가하면 시간의 흐름을 시각적으로 전달할 수 있다.

### 9.2 적용 조건

| 조건 | 표시 여부 |
|------|-----------|
| `countdownMode == days` | **표시** |
| `countdownMode == dMinus` | 표시 안 함 (D-N은 숫자 자체가 직관적) |
| `countdownMode == weeksDays` | 선택적 (days와 유사한 맥락) |
| `countdownMode == mornings / nights` | 표시 안 함 (감성 문구와 충돌) |
| `countdownMode == hidden` | 표시 안 함 |
| D-Day 지남 (`isPast == true`) | 표시 안 함 또는 100% 채움 |

### 9.3 진행률 계산

**문제: 현재 `DaylyWidgetModel`에 `createdAt`(생성일) 필드가 없다.**

ProgressBar는 `(경과일 / 전체기간)` 비율이 필요하므로 시작 기준점이 반드시 있어야 한다.

#### 방안 A — `createdAt` 필드 추가 (권장)

```dart
class DaylyWidgetModel {
  // ... 기존 필드 ...
  final DateTime targetDate;
  final DateTime createdAt;     // 신규: 이벤트 생성 시점

  // 진행률 계산
  double get progress {
    final total = targetDate.difference(createdAt).inDays;
    if (total <= 0) return 1.0;
    final elapsed = DateTime.now().difference(createdAt).inDays;
    return (elapsed / total).clamp(0.0, 1.0);
  }
}
```

- **장점**: 정확한 진행률, 사용자 의도 반영
- **단점**: 기존 데이터 마이그레이션 필요 (`createdAt` 없으면 `DateTime.now()` fallback → 프로그레스 0%부터 시작)

#### 방안 B — 고정 구간 기반 (마이그레이션 불필요)

```
전체 구간 = max(남은 일수, 30일)
진행률 = 1.0 - (남은 일수 / 전체 구간)

예: D-Day까지 22일 남음 → 구간 30일 → 진행률 = 1 - 22/30 = 26.7%
예: D-Day까지 5일 남음 → 구간 30일 → 진행률 = 1 - 5/30 = 83.3%
```

- **장점**: 모델 변경 없음, 즉시 적용 가능
- **단점**: 실제 경과와 무관한 근사값, 30일 이상 이벤트에서 초반 진행률이 부자연스러움

#### 방안 C — 하이브리드 (권장 구현 순서)

1. **즉시**: 방안 B로 구현 (모델 변경 없이 빠르게 출시)
2. **이후**: 방안 A로 전환 (`createdAt` 추가 + 마이그레이션)

### 9.4 위젯 UI 배치

#### Small 위젯 (systemSmall)

```
┌─────────────────┐
│                  │
│   22 days left   │  ← countdownText
│  소중한 날까지    │  ← sentence
│                  │
│  ████████░░░░░░  │  ← ProgressBar (하단, 높이 3pt)
│      1/3         │  ← 페이지 인디케이터
└─────────────────┘
```

- 위치: sentence 아래, 페이지 인디케이터 위
- 높이: 3pt (얇은 라운드 바)
- 색상: `theme.text` (채움) / `theme.sub.opacity(0.2)` (트랙)
- 좌우 패딩: 콘텐츠 패딩과 동일 (12pt)

#### Medium 위젯 (systemMedium)

```
┌────────────────────────────────────┐
│ 2026.06.01                         │
│                                    │
│ 22 days left                       │
│ ████████████░░░░░░░░░░░░░░░░░░░░░  │  ← ProgressBar (카운트다운 바로 아래)
│ · · ·                              │
│ 소중한 날까지                       │
│                                    │
│ < 1 / 3 >                   dayly  │
└────────────────────────────────────┘
```

- 위치: countdownText 바로 아래, 구분점(`· · ·`) 위
- 높이: 3pt
- 너비: 콘텐츠 영역 전체
- 구분점은 ProgressBar가 있을 때 제거하거나 간격을 줄여도 됨

### 9.5 iOS (SwiftUI) 구현 스케치

```swift
// ProgressBar 컴포넌트
struct DaylyProgressBar: View {
    let progress: Double  // 0.0 ~ 1.0
    let theme: (bg: Color, text: Color, sub: Color)

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                // 트랙
                RoundedRectangle(cornerRadius: 1.5)
                    .fill(theme.sub.opacity(0.2))
                // 채움
                RoundedRectangle(cornerRadius: 1.5)
                    .fill(theme.text)
                    .frame(width: geo.size.width * CGFloat(progress))
            }
        }
        .frame(height: 3)
    }
}
```

**진행률 계산 (Swift 측, 방안 B 기준):**

```swift
func calculateProgress(daysRemaining: Int) -> Double {
    guard daysRemaining > 0 else { return 1.0 }
    let span = max(Double(daysRemaining), 30.0)
    return 1.0 - (Double(daysRemaining) / span)
}
```

### 9.6 Android (RemoteViews) 구현 고려

- `RemoteViews`에는 SwiftUI `GeometryReader` 같은 것이 없음
- `ProgressBar` 위젯을 사용하거나, 두 개의 `View`(채움/트랙)로 `LinearLayout weight` 비율 조절
- StackView 아이템 레이아웃(`dayly_widget_stack_item_small/medium`)에 `ProgressBar` 추가

### 9.7 데이터 전달

현재 Flutter → 네이티브 위젯 전달 구조(`HomeWidgetData`)에 필드 추가 필요:

```dart
class HomeWidgetData {
  // ... 기존 필드 ...
  final int daysCount;       // 이미 존재
  final String countdownMode; // 이미 존재
  // 추가:
  final double progress;     // 0.0 ~ 1.0 (Flutter 측에서 계산)
}
```

iOS Swift 측에서도 JSON 파싱 시 `progress` 필드를 읽도록 `DaylyWidgetEntry`에 추가.

### 9.8 구현 우선순위

```
Step 1 (즉시, 방안 B):
  - HomeWidgetData에 progress 필드 추가 (Flutter 측 고정 구간 계산)
  - iOS DaylyWidget.swift에 DaylyProgressBar 컴포넌트 추가
  - countdownMode == "days" 일 때만 표시
  - Android StackView 아이템 레이아웃에 ProgressBar 추가

Step 2 (이후, 방안 A):
  - DaylyWidgetModel에 createdAt 필드 추가
  - 기존 데이터 마이그레이션 (createdAt 없으면 DateTime.now() fallback)
  - progress 계산을 createdAt 기반으로 전환
```

### 9.9 UX 원칙

1. **은은하게** — 높이 3pt, 불투명도 낮은 트랙. 주인공은 카운트다운 숫자이고 ProgressBar는 보조
2. **정보 과잉 방지** — `days` 모드에서만 표시. 다른 모드는 문구 자체가 감성을 전달
3. **D-Day 도달 시 만족감** — 100% 채움 + 약간의 색상 변화(예: accent color)로 달성감 제공

---

## 10. 광고 전략 및 수익 구조 설계

> 작성일: 2026-03-08
> 핵심 질문: 위젯에 광고를 넣을 수 있는가? 앱 전체 수익 구조를 어떻게 가져갈 것인가?

### 10.1 현재 광고 구현 현황

```
현재 수익원:
  1. 배너 광고 (BannerAdWidget) — 앱 하단 고정
     - Android: ca-app-pub-4656262305566191/8847465750
     - iOS:     ca-app-pub-4656262305566191/5810238878

  2. App Open 광고 (AppOpenAdManager) — 앱 실행 시
     - Android: ca-app-pub-4656262305566191/4017810905
     - iOS:     ca-app-pub-4656262305566191/9437357221

  3. isPremium 플래그 — 워터마크 제거 (결제 연동 없음)

예상 월 수익 (MAU 1,000명 기준):
  - 배너 CPM: $0.5~1.5 → $15~45/월
  - App Open CPM: $5~15 → $5~15/월 (1일 1회 기준)
  - 합계: $20~60/월 (약 2.5~8만원)
```

**문제점:**
- 배너 + App Open만으로는 지속 가능한 수익 불가
- `isPremium` 토글이 결제 없이 자유 전환 가능 → 수익 기회 손실
- 보상형 광고, 인터스티셜, 구독 모델 모두 미구현

### 10.2 위젯 광고 — 양 플랫폼 모두 불가

#### Apple iOS: 명시적 금지

**App Store Review Guideline 2.5.18:**
> "Display advertising should be limited to your main app binary, and should not be included in extensions, App Clips, **widgets**, notifications, keyboards, watchOS apps, etc."

- iOS 홈화면 위젯에 광고를 넣으면 **심사 거절 사유**
- 위젯 내 마케팅, 광고, 인앱 구매 UI 일체 금지
- 위반 시 앱 삭제 및 개발자 계정 경고

#### Google Android: 사실상 금지

- Google Play에 iOS처럼 "위젯 광고 금지"를 명시한 단일 조항은 없음
- 그러나 **Better Ads Experiences Policy** + **Disruptive Ads Policy**로 사실상 금지:
  - "예상치 못한 위치의 광고", "기기 사용성을 방해하는 광고" 금지
  - 홈화면 위젯의 광고는 "앱 밖에서의 예상치 못한 광고"로 분류
- 과거 Google Play에서 위젯 광고 앱 대량 퇴출 사례 존재
- 위반 시 앱 삭제 + AdMob 계정 정지 위험

#### 결론

| 플랫폼 | 위젯 내 광고 | 근거 |
|--------|-------------|------|
| iOS | **명시적 금지** | Guideline 2.5.18 |
| Android | **사실상 금지** | Better Ads / Disruptive Ads Policy |

**위젯에는 어떤 형태의 광고도 넣을 수 없다. 위젯은 순수하게 사용자 가치를 전달하는 매체로만 활용해야 한다.**

### 10.3 위젯을 수익에 간접적으로 활용하는 전략

위젯에 직접 광고를 넣을 수 없지만, 위젯이 **앱 진입 트래픽의 핵심 동선**이라는 점을 활용할 수 있다.

#### 전략 A: 위젯 → 앱 진입 → 광고 노출

```
사용자가 홈화면 위젯 탭
  → 앱 실행 (딥링크로 해당 이벤트 상세)
  → App Open 광고 또는 인터스티셜 광고 노출
  → 이벤트 상세 화면 도착
```

- 위젯이 매일 수십 회 보이므로 앱 진입 빈도가 높아짐
- 진입할 때마다 광고 노출 기회 발생
- **핵심: 위젯을 잘 만들수록 앱 진입이 늘고, 앱 진입이 늘수록 광고 수익 증가**

#### 전략 B: 위젯에서 프리미엄 유도

```
무료 사용자 위젯:
  ┌─────────────────┐
  │   22 days left   │
  │  소중한 날까지    │
  │                  │
  │           dayly  │  ← 워터마크 표시
  └─────────────────┘

프리미엄 사용자 위젯:
  ┌─────────────────┐
  │   22 days left   │
  │  소중한 날까지    │
  │                  │
  │                  │  ← 워터마크 없음
  └─────────────────┘
```

- 위젯은 매일 수십~수백 회 눈에 띄는 UI
- 워터마크가 반복적으로 보이면 "제거하고 싶다"는 욕구 자연 발생
- **위젯 워터마크 = 가장 강력한 프리미엄 전환 동기**

#### 전략 C: 위젯 테마/스타일 잠금

```
무료: night, paper, fog (3개)
프리미엄: + lavender, blush, 시즌 한정 테마 (구독 시 모두 해금)

무료 위젯 개수: 3개
프리미엄 위젯 개수: 무제한
```

- 무료로도 충분히 사용 가능하지만, 더 많은 테마와 위젯을 원하면 프리미엄
- 홈화면에 4~6개 위젯을 놓고 싶은 파워유저에게 특히 매력적

### 10.4 권장 수익 모델: 하이브리드 (광고 + 프리미엄)

#### 계층 구조

| 구분 | 무료 | 프리미엄 (구독) |
|------|------|----------------|
| 가격 | $0 | $1.99/월 또는 $9.99/년 |
| 위젯 개수 | 3개 | 무제한 |
| 테마 | 3종 (night, paper, fog) | 전체 (5종 + 시즌 한정) |
| 워터마크 | 표시 | 제거 |
| 배너 광고 | 표시 | 제거 |
| App Open 광고 | 표시 | 제거 |
| 공유 카드 | 워터마크 포함 | 워터마크 없음 |
| 알림 커스텀 | 기본 (D-7/3/1/Day) | 전체 모드 (반복, 시점 선택, 시각 선택) |
| 카운트다운 모드 | days, dMinus | 전체 (+ weeksDays, mornings, nights) |
| 배경 이미지 | 미지원 | 사용자 사진 배경 (향후) |

#### 예상 수익 시뮬레이션 (MAU 10,000 기준)

```
무료 사용자 (90% = 9,000명):
  - 배너 광고:    9,000 × 30일 × 3회/일 × $1.0 CPM = $810/월
  - App Open:     9,000 × 30일 × 1회/일 × $10 CPM = $2,700/월
  - 보상형 광고:  9,000 × 10% × 30일 × $15 CPM = $405/월
  - 인터스티셜:   9,000 × 30일 × 0.5회/일 × $8 CPM = $1,080/월
  소계: ~$4,995/월

프리미엄 사용자 (5% = 500명, 전환율 5%):
  - 월 구독:     500 × $1.99 × 0.7 (스토어 수수료 후) = $697/월
  - 연 구독:     (별도 계산, 월평균 유사)
  소계: ~$697/월

합계: ~$5,692/월 (약 760만원)
```

**참고: 실제 수치는 리텐션, 지역, 사용자 행동에 따라 크게 달라질 수 있음**

### 10.5 광고 유형별 구현 전략

#### (1) 배너 광고 — 현재 구현됨, 최적화 필요

```
현재: 앱 하단 고정 배너 1개
개선:
  - 위치: 홈 그리드 하단 유지 (현재대로)
  - 이벤트 상세 화면에는 배너 미표시 (감성 화면 보호)
  - 공유 프리뷰 화면에도 미표시 (캡처 품질 보호)
  - 프리미엄 시 제거
```

#### (2) App Open 광고 — 현재 구현됨, 빈도 조절 필요

```
현재: 앱 실행마다 노출 시도
개선:
  - 쿨다운: 최소 30분 간격 (같은 세션에서 백그라운드→포그라운드 반복 시 과다 노출 방지)
  - 첫 실행 제외: 온보딩 흐름에서는 광고 미노출
  - 위젯 탭 진입 시: 인터스티셜 대신 App Open 노출 (자연스러운 전환)
```

#### (3) 인터스티셜 광고 — 신규 추가 권장

```
노출 시점:
  - 위젯 생성 완료 후 (저장 확인 → 광고 → 홈 복귀)
  - 위젯 편집 완료 후
  - 3번째 이벤트 조회마다 (frequency cap)

절대 금지 시점:
  - 공유 프로세스 중 (공유 완료 전 광고 = 이탈 유발)
  - 온보딩 중
  - 알림 탭 → 앱 진입 시 (긴급한 D-Day 확인 방해)
```

#### (4) 보상형 광고 — 신규 추가 권장 (핵심)

```
보상형 광고 시나리오:

A. "프리미엄 테마 1일 체험"
   - 잠긴 테마 선택 시: "광고 시청하면 24시간 무료 체험"
   - 체험 후 마음에 들면 구독 전환 유도
   - 가장 자연스러운 프리미엄 퍼널

B. "추가 위젯 슬롯 해금"
   - 무료 3개 → "광고 시청하면 1개 추가 (24시간)"
   - 매일 반복 → 귀찮으면 구독 전환

C. "워터마크 없는 공유 1회"
   - 공유 시 워터마크 포함 카드 생성
   - "광고 시청하면 워터마크 없이 공유"
   - 감성 공유 앱 특성상 매우 높은 전환율 예상

보상형 광고 CPM: $15~50 (일반 광고 대비 10~30x)
사용자 만족도: 높음 (자발적 선택)
```

**보상형 광고는 "감성 앱" 특성과 가장 잘 맞는 광고 유형이다.** 사용자가 자발적으로 시청하고, 보상이 명확하며, 프리미엄 전환의 "맛보기" 역할을 한다.

#### (5) 네이티브 광고 — 선택적

```
홈 그리드에 "추천 이벤트" 카드로 삽입:
  ┌─────────┐ ┌─────────┐
  │ D-22    │ │ D-15    │
  │ 생일    │ │ 기념일  │
  └─────────┘ └─────────┘
  ┌─────────┐ ┌─────────┐
  │ D-100   │ │ AD 광고  │  ← 네이티브 광고 (위젯 카드 스타일)
  │ 졸업    │ │ 스타일  │
  └─────────┘ └─────────┘

주의:
  - "Ad" 라벨 필수 (Google/Apple 정책)
  - 위젯 3개 이하일 때는 미표시 (빈 화면에 광고 = 최악)
  - 위젯 4개 이상일 때 그리드 마지막에 1개만
```

### 10.6 프리미엄(구독) 구현 설계

#### 기술 스택

```
패키지: revenue_cat (RevenueCat)
이유:
  - iOS App Store + Google Play 결제를 단일 API로 통합
  - 구독 상태 관리, 복원, 영수증 검증 자동화
  - Flutter SDK 지원 (purchases_flutter)
  - 무료 tier: MAU 2,500까지 무료 → 초기에 비용 부담 없음

대안: in_app_purchase (공식 패키지) — 직접 구현 필요, 복잡도 높음
```

#### 구독 상품 구성

```
1. 월간 구독: $1.99/월
   - 진입 장벽 낮음
   - 이탈률 높을 수 있음

2. 연간 구독: $9.99/년 ($0.83/월)
   - 월간 대비 58% 할인
   - LTV 높음, 추천 기본 옵션

3. 평생 구매: $19.99 (일회성)
   - 구독 피로도 높은 사용자 대상
   - 장기적으로 수익이 낮지만 전환율 보완
```

#### Paywall UI 설계

```
위치: 설정 > "Dayly Premium" 배너 / 잠긴 기능 탭 시

┌─────────────────────────────────┐
│        Dayly Premium            │
│                                 │
│  [v] 워터마크 없는 깔끔한 위젯  │
│  [v] 모든 테마 해금             │
│  [v] 위젯 무제한               │
│  [v] 광고 제거                 │
│  [v] 알림 커스텀               │
│  [v] 프리미엄 카운트다운 모드   │
│                                 │
│  ┌──────────┐ ┌──────────┐     │
│  │ $9.99/년 │ │$1.99/월  │     │
│  │  추천!   │ │          │     │
│  └──────────┘ └──────────┘     │
│                                 │
│  [3일 무료 체험 시작]           │
│                                 │
│  또는 $19.99 평생 이용          │
│                                 │
└─────────────────────────────────┘

핵심 UX:
  - 3일 무료 체험으로 진입 장벽 제거
  - 연간 구독을 기본 선택으로 하이라이트
  - "워터마크 없는 위젯" 비주얼 비교를 상단에 배치
```

### 10.7 수익 극대화를 위한 위젯 활용 전략

위젯 자체에 광고를 넣을 수 없지만, **위젯이 수익의 핵심 엔진**이 되는 구조:

```
위젯 노출 (매일 수십 회)
  │
  ├─ 워터마크 반복 노출 → 프리미엄 전환 욕구 자극
  │
  ├─ 위젯 탭 → 앱 진입 → 광고 노출 기회
  │
  ├─ D-Day 알림 → 앱 진입 → 광고 노출 기회
  │
  ├─ 공유 → 바이럴 → 신규 사용자 유입
  │   └─ 공유 카드 워터마크 = 무료 브랜드 노출
  │
  └─ "더 예쁜 위젯" 욕구 → 프리미엄 테마/스타일 구매
```

**위젯은 광고 매체가 아니라, 광고와 프리미엄 전환을 유도하는 "트래픽 엔진"이다.**

### 10.8 구현 로드맵

#### Phase 1 — 즉시 (광고 최적화)

| 항목 | 내용 | 예상 효과 |
|------|------|-----------|
| App Open 쿨다운 | 30분 간격 제한 추가 | UX 개선, 정책 준수 |
| 인터스티셜 추가 | 위젯 생성/편집 완료 후 | +30~50% 광고 수익 |
| `isPremium` 토글 숨김 | 결제 없이 전환 불가하도록 | 수익 기반 보호 |
| 광고 비표시 설정 수정 | `setAdVisibility(false)` → `true` | 현재 광고가 꺼져 있음! |

**긴급 발견:** `main.dart:73`에서 `GlobalAdConfig().setAdVisibility(false)` — **현재 광고가 비활성화 상태다.** 이것부터 수정해야 한다.

#### Phase 2 — 1~2주 (보상형 광고)

| 항목 | 내용 | 예상 효과 |
|------|------|-----------|
| 보상형 광고 SDK 통합 | `google_mobile_ads` RewardedAd | 높은 CPM ($15~50) |
| "테마 체험" 시나리오 | 잠긴 테마 선택 → 광고 → 24시간 해금 | 프리미엄 맛보기 |
| "워터마크 없는 공유" | 공유 시 광고 → 워터마크 제거 1회 | 자연스러운 전환 유도 |

#### Phase 3 — 2~3주 (프리미엄 구독)

| 항목 | 내용 | 예상 효과 |
|------|------|-----------|
| RevenueCat 통합 | `purchases_flutter` 패키지 | 결제 인프라 |
| Paywall UI | 프리미엄 혜택 + 가격 표시 | 전환 시작 |
| 기능 잠금 적용 | 테마, 위젯 수, 카운트다운 모드 | 프리미엄 가치 체감 |
| 3일 무료 체험 | Trial period 설정 | 진입 장벽 제거 |

#### Phase 4 — 4주+ (최적화)

| 항목 | 내용 | 예상 효과 |
|------|------|-----------|
| A/B 테스트 | 가격, Paywall 위치, 광고 빈도 | 데이터 기반 최적화 |
| 시즌 테마 | 크리스마스, 벚꽃, 할로윈 등 | 한정 콘텐츠로 구독 유지 |
| 네이티브 광고 | 홈 그리드 내 카드형 | 추가 수익원 |
| 연간 리포트 | "올해 당신의 D-Day" 리캡 | 프리미엄 전용 감성 기능 |

### 10.9 핵심 원칙

1. **위젯에 광고 절대 금지** — iOS/Android 모두 정책 위반. 위젯은 사용자 가치에만 집중
2. **위젯 = 트래픽 엔진** — 위젯이 예쁠수록 앱 진입이 늘고, 수익 기회 증가
3. **보상형 광고 우선** — 감성 앱에서 강제 광고는 브랜드 훼손. 자발적 시청이 핵심
4. **프리미엄은 "있으면 좋은 것"** — 무료로도 충분히 사용 가능, 프리미엄은 "더 예쁜" 경험
5. **광고 vs 감성 균형** — 공유 프리뷰, 이벤트 상세 등 감성 화면에서는 광고 최소화
6. **`setAdVisibility(false)` 즉시 수정** — 현재 광고 수익이 $0인 상태

### 10.10 경쟁 앱 수익 모델 참고

```
TheDayBefore (D-Day 카운터):
  - 무료 + 광고 / 프리미엄 $2.99 (광고 제거 + 테마)
  - 위젯: 광고 없음, 프리미엄 테마만 잠금

Countdown Star:
  - 무료 + 광고 / 프로 $4.99/년
  - 위젯: 무료 1개, 프로 무제한

TimeUntil:
  - 무료 + 제한된 기능 / 프로 $1.99
  - 위젯: 프로에서만 커스텀 스타일

공통점:
  → 위젯에 광고를 넣는 앱 = 0개
  → 프리미엄 전환의 핵심 = "더 많은 위젯" + "더 예쁜 테마"
  → Dayly의 감성 디자인은 프리미엄 전환에 유리한 자산
```

---

## 11. 요약 — 수익 구조 한눈에 보기

```
┌─────────────────────────────────────────────────────────┐
│                    Dayly 수익 구조                       │
│                                                         │
│  [무료 사용자 90%]              [프리미엄 5~10%]        │
│   │                              │                      │
│   ├─ 배너 광고 (홈 하단)         ├─ 월 $1.99            │
│   ├─ App Open (앱 진입 시)       ├─ 년 $9.99            │
│   ├─ 인터스티셜 (생성/편집 후)   └─ 평생 $19.99         │
│   └─ 보상형 (테마 체험/공유)                             │
│                                                         │
│  [위젯 = 트래픽 엔진]                                   │
│   │                                                     │
│   ├─ 워터마크 → 프리미엄 전환 유도                      │
│   ├─ 탭 → 앱 진입 → 광고 노출                          │
│   ├─ 알림 → 앱 진입 → 광고 노출                        │
│   └─ 공유 → 바이럴 → 신규 유입 → 광고/프리미엄         │
│                                                         │
│  [위젯 내 광고: iOS/Android 모두 정책상 불가]            │
└─────────────────────────────────────────────────────────┘
```
