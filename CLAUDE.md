# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Commands

```bash
# 의존성 설치
flutter pub get

# 실행 (핫 리로드 포함)
flutter run

# 빌드
flutter build apk        # Android APK
flutter build aab        # Android App Bundle

# 코드 품질
flutter analyze          # 린터 실행
flutter test             # 테스트 실행
flutter test test/path/to/test_file.dart  # 단일 테스트 실행

# Firebase 재설정 (필요 시)
flutterfire configure
```

디버그 빌드에서는 Firebase Auth 에뮬레이터(localhost:9099)가 자동으로 활성화된다.

## 아키텍처

### 앱 개요

`dayly`는 "위젯 우선 D-Day 카드 + SNS 공유 앱"이다. 홈 위젯이 핵심 제품이며, UI는 위젯을 설정하기 위해 존재한다. **"위젯을 더 감성적으로, 공유를 더 매력적으로, 정보를 더 명확하게" 만들지 않는 기능은 구현하지 않는다.**

### 인증 흐름

```
main() → Firebase.initializeApp()
       → runApp(buildDaylyApp())
       → MaterialApp → AuthGate
           ├─ 미로그인 → SignInScreen (이메일 + Google OAuth)
           └─ 로그인됨 → WidgetGridScreen (홈)
```

`lib/config.dart`에 플랫폼별 Google OAuth Client ID가 정의되어 있다.

### 핵심 데이터 모델 (`lib/models/dayly_widget_model.dart`)

`DaylyWidgetModel`이 단일 진실 공급원이다:
- `primarySentence` - 날짜의 의미 (최대 2줄)
- `targetDate` - D-Day 날짜
- `style: DaylyWidgetStyle` - 테마, 카운트다운 방식, 워터마크 등

`DaylyWidgetStyle`의 주요 필드:
- `themePreset: DaylyThemePreset` - night / paper / fog / lavender / blush
- `countdownMode: DaylyCountdownMode` - days("23일") / dMinus("D-23") / weeksDays("3주 2일") / mornings / nights / hidden

### 저장소

`SharedPreferences`로 기기에 로컬 저장 (`lib/storage/dayly_widget_storage.dart`).
키: `dayly.widgets.v1` — JSON 배열로 직렬화.

### 상태 관리

별도 상태 관리 라이브러리 없음. `setState()` + 로컬 스토리지를 사용한다.

### 화면 구성

| 화면 | 파일 | 역할 |
|------|------|------|
| 홈 | `lib/screens/widget_grid_screen.dart` | 2×2 위젯 그리드, FAB으로 추가 |
| 에디터/공유 | `lib/screens/share_preview_screen_v2.dart` | 위젯 미리보기 + 테마/문구/날짜 편집 + 공유 |
| 새 위젯 추가 | `lib/screens/add_widget_bottom_sheet.dart` | 날짜/문구/테마 입력 시트 |

### 위젯 렌더링 (`lib/widgets/dayly_widget_card.dart`)

Small / Medium / Large 3가지 크기를 지원하며, Large가 정규 레이아웃이다. 위젯 캡처 및 공유는 `lib/utils/dayly_share_export.dart`의 `captureBoundaryPng()`와 `sharePngBytes()`를 사용한다.

### 폰트 및 테마

- 문구(sentence): Gowun Dodum (light, 감성적)
- 숫자(D-Day number): Roboto Mono (bold, 모노스페이스) — 문구 크기의 1.6×–2.0×
- 팔레트 상수: `lib/theme/dayly_palette.dart`
- 테마 프리셋 정의: `lib/theme/dayly_theme_presets.dart`

### 문구 생성 (`lib/utils/dayly_sentence_templates.dart`)

LLM 없이 순수 함수로 오프라인 동작. Relationship × Tone × Event 조합으로 결정론적 문구를 생성한다.

### Android 설정

- 패키지명: `com.example.dayly`
- Firebase 프로젝트: `dayly-6329b`
- 릴리즈 서명: `android/key.properties` (git에 포함되지 않음)
- 디버그 빌드: `android/app/src/debug/AndroidManifest.xml`에서 localhost cleartext 허용
