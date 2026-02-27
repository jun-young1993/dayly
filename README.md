# dayly

Showable D-Day widget + share card app (widget-first).

---

# UI 디자인 가이드

## 디자인 컨셉

**Glassmorphism + Minimalism** — Dark Mode (Deep Navy & Charcoal Grey)

| 요소 | 스펙 |
|------|------|
| 배경 | Deep Navy 그라데이션 `#0D1F3C → #0A0E1A` |
| 카드 | 반투명 유리 효과 (`BackdropFilter`, blur σ=12) |
| 테두리 | `rgba(255,255,255, 0.12)`, 1px |
| BorderRadius | 20dp (카드), 14dp (아이콘 박스) |
| 아이콘 박스 | 파스텔 그라데이션 (8종 순환) |
| 폰트 | `Montserrat` (헤더/리스트), `Roboto Mono` (D-Day 숫자) |
| D-Day 표기 | `D-n` (미래), `D-Day` (당일), `D+n` (과거) |

## 화면 구성

### 메인 대시보드 (`WidgetGridScreen`)
- 헤더: `YOUR MOMENTS` (All Caps, letterSpacing 3.5)
- 이벤트 수 서브타이틀 (`n events`)
- 글래스모피즘 리스트 카드:
  - 좌측: 파스텔 그라데이션 아이콘 박스 (52×52dp)
  - 중앙: 제목 + 날짜 (좌측 정렬)
  - 우측: D-Day 배지 (우측 정렬, Roboto Mono Bold)
- 하단 우측: 반투명 글래스 FAB (+)

### 새 D-Day 추가 (`_AddMomentScreen`)
- 슬라이드-업 전체화면 모달 (PageRouteBuilder, SlideTransition)
- `Name your moment` — 글래스 텍스트 입력 필드
- `Date Selection` — 인라인 `CalendarDatePicker` (다크 테마 적용)
- D-Day 라이브 배지: 날짜 선택 시 실시간으로 `D-n` 업데이트
- `Icon & Color` — 파스텔 그라데이션 아이콘 가로 스크롤 (8종), 선택 시 글로우 효과
  - 아이콘 선택 → `DaylyThemePreset` + `DaylyCountdownMode` 자동 매핑
- `SAVE MOMENT` 버튼 — 입력 전 비활성(어둡게), 입력 후 활성(밝게)

### 이벤트 상세 (`EventDetailScreen`) — NEW
- **진입**: 대시보드 카드 탭 → Hero 전환
- **히어로 카드**: 파스텔 그라데이션 아이콘 박스 + D-Day 숫자(52sp, Roboto Mono) + 이벤트 제목/날짜
- **실시간 카운트다운**: `Timer.periodic(1초)` → `HH : MM : SS` 타이머 (목표 날짜 자정 기준)
- **마일스톤 카드**: 진행 바(퍼센티지) + 체크리스트 (탭으로 완료 토글, `AnimatedContainer` 체크박스)
- **노트 카드**: 자유 텍스트 메모 표시
- **액션**: 뒤로가기(결과 반환), 삭제(확인 다이얼로그 → 리스트에서 제거), 편집(SharePreviewScreenV2)

### 위젯 에디터 / 공유 (`SharePreviewScreenV2`)
- 위젯 미리보기 + 테마/문구/날짜 편집
- 이미지 캡처 후 SNS 공유

## 색상 팔레트

```
배경 그라데이션  #0D1F3C → #0A0E1A
카드 배경       rgba(255,255,255, 0.07)
카드 테두리     rgba(255,255,255, 0.12)
FAB 배경        rgba(255,255,255, 0.15)
FAB 테두리      rgba(255,255,255, 0.25)

아이콘 그라데이션 팔레트
  퍼플   #6C63FF → #9B8FFF
  틸     #4ECDC4 → #44A08D
  코랄   #FF6B6B → #FF8E53
  옐로우 #FFD93D → #FFC107
  블루   #74B9FF → #0984E3
  민트   #55EFC4 → #00B894
  핑크   #FF9FF3 → #F368E0
  앰버   #FECB74 → #FFA502
```

## 글래스모피즘 구현 방법 (Flutter)

외부 패키지 없이 Flutter 내장 위젯으로 구현:

```dart
ClipRRect(
  borderRadius: BorderRadius.circular(20),
  child: BackdropFilter(
    filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
    child: Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.12),
        ),
      ),
      child: // 카드 내용
    ),
  ),
)
```

---

# 구현 가이드

## 1. 디자인 시스템

| 항목 | 적용 방식 |
|------|----------|
| 스타일 | Glassmorphism + Minimalism |
| 배경 색 | `#1A1C20 → #0F1012` (Deep Navy/Charcoal Gradient) |
| 포인트 색 | Pastel Gradients — Pink, Blue, Mint, Purple, Teal |
| 본문/제목 폰트 | `Montserrat` (`google_fonts` 패키지) |
| D-Day 숫자 폰트 | `Roboto Mono` Bold & Large |

## 2. 화면별 구현 세부 사항

### Screen 1 — 대시보드 리스트 (`WidgetGridScreen`)

- 글래스 카드: `BackdropFilter` + `LinearGradient` 조합으로 테두리에 미세 빛 반사 효과
- 아이콘 박스: 좌측 둥근 사각형, 파스텔톤 그라데이션 배경 + 라인 아이콘
- FAB: 하단 우측 반투명 화이트 플로팅 버튼 (+)

### Screen 2 — 이벤트 상세 (`EventDetailScreen`)

- **히어로 카드**: 파스텔 그라데이션 아이콘 + D-Day 숫자(대형) + 이벤트명/날짜
- **실시간 타이머**: `Timer.periodic(Duration(seconds: 1))` — 자정 기준 `HH : MM : SEC` 카운트다운
- **마일스톤 섹션**: `LinearProgressIndicator` 진행 바 + 체크리스트 (탭 토글, `AnimatedContainer`)
- **노트 섹션**: 자유 텍스트 메모
- **삭제**: 글래스 확인 다이얼로그 → `WidgetGridScreen`에서 항목 제거
- **편집**: `SharePreviewScreenV2`로 이동 후 결과 반영

### Screen 3 — 새 기념일 추가 (`_AddMomentScreen`)

- **진입**: 하단 슬라이드-업 `PageRouteBuilder` (`SlideTransition` + `FadeTransition`)
- **입력 필드**: `BackdropFilter` 적용된 투명 텍스트 필드
- **날짜 선택**: 인라인 `CalendarDatePicker` — 탭 없이 바로 노출, 다크 테마 적용
- **D-Day 미리보기**: 날짜 선택 시 우측 상단 배지 실시간 업데이트 (`D-n`)
- **아이콘 선택**: 가로 스크롤 그리드, 선택 시 `AnimatedContainer`로 글로우 + 테두리 효과
- **저장 버튼**: 전체 너비 `SAVE MOMENT`, 입력 여부에 따라 활성/비활성 애니메이션 전환

## 3. 기술 요구 사항

### 사용 패키지

| 패키지 | 용도 |
|--------|------|
| `google_fonts` | Montserrat / Roboto Mono 폰트 |
| `flutter_screenutil` | 모바일/태블릿 반응형 수치 대응 |
| `intl` | 날짜 포맷 및 계산 |
| `shared_preferences` | 기념일 로컬 저장 |
| `share_plus` | 위젯 이미지 SNS 공유 |

> 글래스모피즘은 Flutter 내장 `BackdropFilter`로 구현 — 별도 패키지 불필요

### 핵심 구현 포인트

1. **Glass Effect**: `BackdropFilter(ImageFilter.blur)` + `LinearGradient` 테두리 조합
2. **Edge Light**: 카드 외부 컨테이너에 `0.8px` 너비 그라데이션 테두리로 유리 질감 표현
3. **Animation**: `AnimatedContainer` (아이콘 선택 글로우), `SlideTransition` (화면 진입), `AnimationController` (배경 그라데이션 8초 왕복)
4. **Real-time Timer**: `Timer.periodic(Duration(seconds: 1))` → 목표 날짜 자정까지 남은 `HH:MM:SS` 실시간 카운트다운
5. **Milestone Checklist**: `AnimatedContainer` 체크박스 + `LinearProgressIndicator` 진행 바
6. **Haptic Feedback**: `HapticFeedback.lightImpact()` (카드 탭), `mediumImpact()` (FAB/저장/삭제), `selectionClick()` (마일스톤 토글/아이콘 선택)
7. **Responsiveness**: `flutter_screenutil` — 모든 `fontSize`.sp, 너비`.w`, 높이`.h`, 반지름`.r` 단위 적용
8. **Tablet Layout**: `MediaQuery.size.width >= 600` 감지 → 2열 `GridView` 자동 전환
9. **상태 관리**: 별도 라이브러리 없이 `setState()` + `SharedPreferences` 로컬 저장
10. **화면 전환 결과 반환**: `Navigator.pop<({bool deleted, DaylyWidgetModel? model})>` — 삭제/업데이트를 type-safe하게 처리

### ScreenUtil 기준 사이즈

```
기준 기기: iPhone 14 Pro (390 × 844 논리 픽셀)
태블릿 기준: 768 × 1024
splitScreenMode: true (분할 화면 지원)
```

### 컴포넌트 분리 원칙

```
WidgetGridScreen
  ├─ _AnimatedGradientBackground  ← 8초 주기 배경 색상 애니메이션
  ├─ _GlowCircle                  ← 장식용 RadialGradient 빛 효과
  ├─ _GlassmorphicCard            ← Edge Light + BackdropFilter 카드 (탭 → EventDetailScreen)
  └─ _GlassFab                    ← 반투명 글래스 + 버튼

EventDetailScreen                 ← 카드 탭 진입 (NEW)
  ├─ _TopBar             ← 뒤로가기 + 삭제 버튼
  ├─ _HeroCard           ← 아이콘 + 대형 D-Day + 실시간 타이머(_TimerDisplay)
  ├─ _MilestonesCard     ← 진행 바 + _MilestoneItem 체크리스트
  ├─ _NotesCard          ← 메모 텍스트
  ├─ _EditEventButton    ← 글래스 편집 버튼 → SharePreviewScreenV2
  └─ _DeleteDialog       ← 삭제 확인 다이얼로그

_AddMomentScreen
  ├─ _TopBar             ← 닫기 버튼 + 타이틀
  ├─ _NameField          ← 글래스 텍스트 입력
  ├─ _DateSection        ← 인라인 캘린더 + D-Day 배지
  ├─ _IconSection        ← 아이콘 & 컬러 선택 (Haptic 포함)
  └─ _SaveButton         ← 활성/비활성 AnimatedContainer 버튼
```

# Firebase Auth 에뮬레이터

## 언제 쓰나

| 상황 | 에뮬레이터 | 프로덕션 |
|------|-----------|---------|
| UI/UX 테스트 | | ✅ |
| Google OAuth 테스트 | | ✅ |
| 자동화 테스트 (CI/CD) | ✅ | |
| 보안 규칙 반복 수정 | ✅ | |
| 오프라인 개발 | ✅ | |
| 실제 이메일 발송 확인 | | ✅ |

평상시 개발은 **프로덕션 Firebase를 직접 사용**해도 충분하다.
에뮬레이터는 격리된 테스트 환경이 필요할 때 사용한다.

## 에뮬레이터 활성화 방법

### 1. Firebase CLI로 에뮬레이터 실행 (PC에서)

```bash
firebase emulators:start --only auth
```

에뮬레이터 콘솔: http://localhost:4000

### 2. main.dart에서 에뮬레이터 연결 코드 추가

```dart
import 'package:firebase_auth/firebase_auth.dart' hide EmailAuthProvider;
import 'package:flutter/foundation.dart';

// Firebase.initializeApp() 이후, FirebaseUIAuth.configureProviders() 이전에 추가
if (kDebugMode) {
  // Android 에뮬레이터에서 호스트 PC = 10.0.2.2 (localhost X)
  await FirebaseAuth.instance.useAuthEmulator('10.0.2.2', 9099);
  // iOS 시뮬레이터 / 실기기는 localhost 사용
  // await FirebaseAuth.instance.useAuthEmulator('localhost', 9099);
}
```

### 주의사항

- 에뮬레이터 데이터는 **재시작 시 초기화**됨 (영구 저장 X)
- Google OAuth는 에뮬레이터에서 동작하지 않음 (이메일 인증만 테스트 가능)
- Android 에뮬레이터에서 호스트 PC 주소는 반드시 `10.0.2.2` 사용

# 참고 문서
- firebaseUI-Flutter example
https://github.com/firebase/FirebaseUI-Flutter/blob/main/packages/firebase_ui_auth/example/lib/config.dart
