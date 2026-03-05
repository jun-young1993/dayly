# CHANGELOG

# 1.0.1

## [Unreleased] — 2026-03-05

### 사용자 정의 알림 옵션 (Create/Edit 화면에서 알림 방식 선택)

---

### Added

#### 신규 파일

| 파일 | 설명 |
|------|------|
| `lib/models/notification_settings.dart` | 알림 방식(특정 시점/반복)을 캡슐화한 불변 모델. `NotificationMode` enum + `fixedDaysBefore` + `repeatIntervalDays` 필드. `toJson/fromJson` 포함 |
| `lib/widgets/notification_settings_panel.dart` | 마스터 토글 → Radio Group → 조건부 확장 패널 UX. Progressive Disclosure 패턴. 특정 시점 체크박스 / 반복 Chip Group + 숫자 입력 포함 |

#### UX 구조 (설계 사양)

```
[알림 ON/OFF 마스터 토글]
  ↓ ON 시 확장
[알림 방식 Radio Group]
  ◉ 특정 시점  ○ 반복

[특정 시점 선택 시]
  ☑ D-7   ☑ D-3   ☑ D-1   ☑ D-Day

[반복 알림 선택 시]
  [매일]  [2일]  [3일]  [직접 입력 → n일]
  ⚠ 예약 가능한 알림: N건
```

---

### Changed

#### `lib/models/dayly_widget_model.dart`
- `notificationSettings: NotificationSettings` 필드 추가
  - 기본값: `enabled=false`, `mode=specificPoints`, `fixedDaysBefore=[1,0]`
  - `fromJson`: `notificationSettings` 없는 구버전 → `NotificationSettings()` 기본값으로 자동 마이그레이션
  - `copyWith`, `toJson` 반영

#### `lib/services/notification_id_registry.dart`
- ID 비트 구조 변경: 하위 4비트 → **하위 6비트** (최대 63개 트리거)
  - 기존: `(hash & 0x0FFFFFFF) << 4 | triggerIndex` (triggerIndex 0~15)
  - 변경: `(hash & 0x03FFFFFF) << 6 | triggerIndex` (triggerIndex 0~63)
  - triggerIndex 0~3: 특정 시점 전용 (기존 호환)
  - triggerIndex 4~33: 반복 알림 전용 (최대 30회)
- `maxTriggers = 64`, `maxRepeatSlots = 30` 상수 추가

#### `lib/services/notification_scheduler.dart`
- `scheduleAll()` → `scheduleForSettings(model, settings)` 시그니처 변경
  - **특정 시점 모드**: `settings.fixedDaysBefore` 목록 기준으로 예약 (기존 D-7/D-3/D-1/D-Day 하드코딩 제거)
  - **반복 모드**: `settings.repeatIntervalDays` 간격으로 오늘 다음날부터 D-Day까지 최대 30회 예약
  - 두 모드 모두 이미 지난 트리거 자동 스킵 유지
- 64개 AlarmManager 제한 방어: 예약 전 전체 pending 수 확인 → 초과 시 가장 이른 트리거부터 제외

#### `lib/repositories/notification_repository.dart`
- `schedule(model)` 내부: `scheduleAll()` → `scheduleForSettings(model, model.notificationSettings)` 호출로 변경
- Hive value 구조 변경: `List<int>` → `{'ids': List<int>, 'settingsJson': String}` (설정 영속화, 동기화 복원 시 재사용)
- `syncOnAppStart()`: 저장된 `settingsJson` 기반으로 재예약 (기존: 하드코딩된 4개 트리거)

#### `lib/screens/add_widget_bottom_sheet.dart`
- `NotificationSettingsPanel` 위젯 추가 (기본 접힘, 마스터 토글 ON 시 확장)
- 저장(`_submit`) 시 `model.notificationSettings` 반영 후 `notifRepo.schedule(model)` 호출
- 저장 완료 후 스낵바: `"알림 N건이 예약되었습니다"` (예약된 ID 수 표시)

#### `lib/screens/share_preview_screen_v2.dart` (Edit 화면)
- `NotificationSettingsPanel` 추가 — 기존 `model.notificationSettings` 로드해 UI 상태 복원
- 저장 시 변경 감지: `settings`가 동일하면 재예약 생략 (불필요한 cancel-reschedule 방지)
- 변경 시: `notifRepo.schedule(updatedModel)` → cancel-first → 재예약

---

### 알림 동작 사양 (확장)

#### 특정 시점 알림

| 트리거 | 발송 시각 | 메시지 |
|--------|-----------|--------|
| D-7 | 오전 9:00 | `7일 후 {제목}입니다` |
| D-3 | 오전 9:00 | `3일 후 {제목}입니다` |
| D-1 | 오전 9:00 | `내일이 {제목}입니다` |
| D-Day | 오전 9:00 | `오늘이 바로 {제목}입니다 ✨` |

- 기본 선택: D-1 + D-Day (체크박스 중복 선택 가능)
- 이미 지난 트리거 자동 스킵

#### 반복 알림

| 주기 | 최대 예약 수 | 메시지 |
|------|------------|--------|
| 매일 (1일) | 30회 | `D-{N} {제목}` |
| 2일마다 | 15회 | `D-{N} {제목}` |
| 3일마다 | 10회 | `D-{N} {제목}` |
| N일마다 (직접 입력) | ⌊30/N⌋회 | `D-{N} {제목}` |

- 오늘 다음날 오전 9시부터 D-Day까지 계산
- 전체 예약 합산 64개 초과 시 초과분 자동 제외 (경고 표시)

---

### 기술 결정 근거

- **특정 시점 + 반복 상호 배타**: 두 모드 동시 활성화 시 64개 제한 초과 위험 + UX 혼란 → Radio Group으로 단일 선택 강제
- **Progressive Disclosure**: 알림을 원하지 않는 사용자(다수)는 토글 OFF로 끝. 원하는 사용자만 2단계 진입
- **기존 cancel-first 패턴 유지**: Edit 시 좀비 알림 방지. `notifRepo.schedule()` 단일 진입점 원칙 유지
- **하위 6비트 확장**: 반복 30회 수용을 위한 최소 변경. 기존 특정 시점 ID(0~3)와 충돌 없음. Hive 마이그레이션 필요 (boxName 버전 업 불필요, value 스키마만 변경)
- **최대 30회 반복 제한**: Android AlarmManager 64개 총량에서 위젯 2개 혼용 시 안전 상한. 30일 이상 반복은 장기 D-Day 시나리오에서도 충분

---

# 1.0.0

## [Unreleased] — 2026-03-04

### 로컬 알림 시스템 도입 (서버/FCM 없이 동작)

---

### Added

#### 패키지 (pubspec.yaml)
- `flutter_local_notifications: ^17.2.4` — 로컬 알림 예약/취소
- `hive_flutter: ^1.1.0` — 알림 메타데이터 로컬 저장 (TypeAdapter 없음)
- `timezone: ^0.9.4` — DST 정확 처리를 위한 TZDateTime
- `flutter_timezone: ^5.0.1` — 디바이스 로컬 타임존(IANA) 획득

#### 신규 파일

| 파일 | 설명 |
|------|------|
| `lib/services/notification_id_registry.dart` | `widgetId × triggerIndex → int` 결정론적 ID 생성. 재설치 후에도 동일 ID 보장 |
| `lib/services/notification_scheduler.dart` | D-7 / D-3 / D-1 / D-Day 알림을 `zonedSchedule`로 예약. `exactAllowWhileIdle` 모드로 Doze 관통 |
| `lib/services/notification_permission_service.dart` | Android 13+(POST_NOTIFICATIONS, SCHEDULE_EXACT_ALARM) / iOS 권한 요청 |
| `lib/repositories/notification_repository.dart` | Hive 기반 알림 CRUD 싱글턴. 앱 시작 시 pending 비교 후 자동 복원 |

---

### Changed

#### `lib/models/dayly_widget_model.dart`
- `DaylyWidgetModel`에 `id` 필드 추가
  - SharedPreferences에 영속 저장 → 재설치 후에도 알림 ID 매핑 유지
  - `fromJson`: 구버전 데이터(id 없음) → `generateWidgetId()`로 자동 마이그레이션
  - `copyWith`, `toJson`, `defaults()` 모두 id 반영
- `generateWidgetId()` 함수 추가 (타임스탬프 + 랜덤 16진수, 외부 패키지 불필요)

#### `lib/main.dart`
- 초기화 순서 확립 (runApp 이전 완료)
  1. `tz.initializeTimeZones()` + `FlutterTimezone.getLocalTimezone()` → DST 정확 처리
  2. `Hive.initFlutter()` → Hive 박스 열기
  3. `FlutterLocalNotificationsPlugin.initialize()` → 알림 채널 생성
  4. `NotificationRepository.instance.init(plugin)` → Hive 박스 연결
- `flutter_timezone` 5.x `TimezoneInfo.identifier`로 IANA 타임존 이름 추출

#### `lib/screens/widget_grid_screen.dart`
- `NotificationPermissionService`, `NotificationRepository` 필드 추가
- `_load()`: 구버전 위젯 id 마이그레이션 감지 후 즉시 재저장. `syncOnAppStart()` 호출로 재부팅 후 알림 복원
- `_openAddWidgetSheet()`: 첫 위젯 추가 시 알림 권한 요청 → `notifRepo.schedule(created)`
- `_openDetail()`: 삭제 → `notifRepo.cancel(id)`, 수정 → `notifRepo.schedule(updated)`

#### `lib/screens/add_widget_bottom_sheet.dart`
- `DaylyWidgetModel` 생성 시 `id: generateWidgetId()` 추가

#### `android/app/src/main/AndroidManifest.xml`
- `POST_NOTIFICATIONS` — Android 13+ 알림 표시 런타임 권한
- `SCHEDULE_EXACT_ALARM` — 정확한 시각 알람 (미설정 시 `zonedSchedule` silently fail)
- `RECEIVE_BOOT_COMPLETED` — 재부팅 후 AlarmManager 복원

#### `android/app/build.gradle.kts`
- `isCoreLibraryDesugaringEnabled = true` — `flutter_local_notifications`가 `java.time` API 사용. 미설정 시 빌드 오류
- `coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")` 의존성 추가

---

### 알림 동작 사양

| 트리거 | 발송 시각 | 메시지 |
|--------|-----------|--------|
| D-7 | 오전 9:00 | `7일 후 {제목}입니다` |
| D-3 | 오전 9:00 | `3일 후 {제목}입니다` |
| D-1 | 오전 9:00 | `내일이 {제목}입니다` |
| D-Day | 오전 9:00 | `오늘이 바로 {제목}입니다 ✨` |

- 이미 지난 시각의 트리거는 자동 스킵
- Android AlarmManager 64개 제한 대응: 위젯 1개당 최대 4개 예약 → 최대 16개 위젯 동시 알림 가능
- 알림 ID 생성: `(widgetId.hashCode.abs() & 0x0FFFFFFF) << 4 | triggerIndex`

---

### 기술 결정 근거

- **Hive (TypeAdapter 없음)**: `List<int>` 원시 타입 저장으로 code generation 불필요. 알림 ID만 저장하므로 모델 복잡도 최소화
- **결정론적 ID**: 랜덤 ID는 재설치 후 cancel 불가. widgetId 해시로 항상 같은 ID 보장
- **exactAllowWhileIdle**: Doze 모드에서도 정확한 시각 발송. 일반 `setExact`는 배치 처리로 수 시간 지연 가능
- **SCHEDULE_EXACT_ALARM 필수**: 미설정 시 `zonedSchedule` 예외 없이 무시됨 — "알림이 안 와요" 리뷰의 1위 원인
