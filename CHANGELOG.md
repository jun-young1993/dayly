# CHANGELOG

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
