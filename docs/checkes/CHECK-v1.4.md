# Dayly 앱 전체 점검 보고서 v1.4

> 작성일: 2026-03-13
> 대상 버전: pubspec 1.1.2+4 / CHANGELOG 1.3.8
> 이전 점검: CHECK-v1.1.md (2026-03-05), CHECK-v1.3.md (2026-03-08)
> 중점: v1.2.x ~ v1.3.x 변경사항 검증 + 수익화/안정성/출시 준비도 재평가

---

## TL;DR

**v1.1 이후 위젯·상세화면·광고 측면에서 대대적인 개선이 이루어졌다. Large 위젯, 배경사진, 진행률, 마일스톤 CRUD 등 핵심 UX가 완성 수준에 근접했다. 그러나 pubspec 버전이 1.1.2+4로 CHANGELOG(1.3.8)와 8단계 이상 괴리가 생겼고, 데이터 백업·온보딩·결제 연동·언어 통일은 여전히 미해결 상태다. 지금 출시하면 "데이터 날아갔어요" 리뷰와 "광고 많다" 리뷰가 동시에 들어올 위험이 있다.**

---

## 0. v1.1 지적사항 해소 현황

| # | v1.1 지적 | 현재 상태 | 판정 |
|---|-----------|-----------|------|
| 1 | Firebase 미사용 의존성 제거 | pubspec에서 4개 패키지 전부 제거, 관련 파일 삭제 완료 (v1.2.4) | **해결** |
| 2 | pubspec 버전 동기화 | **여전히 1.1.2+4. CHANGELOG는 1.3.8 — 8단계 괴리** | **미해결** |
| 3 | 설정 화면 1초 딜레이 제거 | `Future.delayed(1s)` 코드 사라짐, 딜레이 없음 | **해결** |
| 4 | 기본 위젯 persist 처리 | 코드 재확인 결과 기본 위젯 반복 생성 이슈 미확인 (추가 검증 필요) | **부분 해결** |
| 5 | 언어 통일 (한국어/영어 혼재) | UI 영어, 다이얼로그·위젯 안내 한국어 혼재 그대로 | **미해결** |
| 6 | 로컬 백업 내보내기/가져오기 | 구현 없음. SharedPreferences 단독 저장 유지 | **미해결** |
| 7 | iOS 위젯 D-Day 실시간 계산 | `buildCountdownText()` Swift 함수 추가로 앱 미실행 시에도 정확 (v1.2.3) | **해결** |
| 8 | CHANGELOG-코드 불일치 | Firebase 부분 해소. v1.0.1 `NotificationSettingsPanel` 코드 여전히 없음 | **부분 해결** |
| 9 | 온보딩 화면 | 미구현 | **미해결** |
| 10 | isPremium 결제 없이 자유 토글 | `share_preview_screen_v2.dart:263-264` 탭만으로 ON/OFF 가능 그대로 | **미해결** |
| 11 | iOS 공유 텍스트 App Store 링크 없음 | 확인 결과 Play Store 링크만 존재 | **미해결** |
| 12 | 마일스톤 생성 UI | 추가/삭제 가능 (v1.3.0) | **해결** |
| 13 | 단위 테스트 부재 | test/ 디렉토리 비어 있음 | **미해결** |
| 14 | enum 마이그레이션 전략 | 버전 키 없음, `firstWhere+orElse` fallback만 존재 | **미해결** |
| 15 | `pixelRatio = 3` 고정 | `dayly_share_export.dart:12` 여전히 `double pixelRatio = 3` | **미해결** |
| 16 | In-app purchase 미구현 | 미구현 | **미해결** |

**요약: 16건 중 6건 해결, 2건 부분 해결, 8건 미해결**

---

## 1. v1.2.x ~ v1.3.x 변경 요약 및 평가

### 1.1 v1.2.x (2026-03-05 ~ 2026-03-07)

| 버전 | 변경 | 평가 |
|------|------|------|
| 1.2.0 | Android StackView + iOS 인터랙티브 버튼 멀티이벤트 탐색 | 핵심 USP 완성 ✅ |
| 1.2.1 | iOS 위젯 Xcode 타겟 정식 등록 + 3분할 탭 영역 | iOS 기능 실제 출시 가능 수준 ✅ |
| 1.2.2 | DST 경계 알림 날짜 오류 수정 | 알림 신뢰성 확보 ✅ |
| 1.2.3 | iOS 위젯 D-Day 실시간 재계산 | Android/iOS 패리티 달성 ✅ |
| 1.2.4 | Firebase 의존성 전면 제거 | 앱 사이즈 축소 + 크래시 근본 해결 ✅ |

### 1.2 v1.3.x (2026-03-08 ~ 2026-03-13)

| 버전 | 변경 | 평가 |
|------|------|------|
| 1.3.0 | 상세화면 Progress Bar + 마일스톤 CRUD + SHARE 버튼 + `createdAt` 추가 | UX 대폭 향상 ✅ |
| 1.3.1 | 설정화면 테마/언어/브랜드 변경 즉시 반영 | ListenableBuilder 수정 ✅ |
| 1.3.2 | Android 위젯 "Couldn't add widget" + 클리핑 + D-0/D-Day 불일치 수정 | 핵심 버그 3개 해결 ✅ |
| 1.3.3 | Android 위젯 테마 색상 + 워터마크 + 페이지 인디케이터 적용 | iOS 수준 디자인 통일 ✅ |
| 1.3.4 | Medium 위젯 별도 등록 + Small 글씨 크기 축소 | 위젯 피커 UX 개선 ✅ |
| 1.3.5 | Medium `View` → `ImageView` 교체 (RemoteViews 크래시 수정) | 호환성 확보 ✅ |
| 1.3.6 | Large(4×4) 위젯 추가 (`WidgetSize` enum 도입) | 차별화 요소 추가 ✅ |
| 1.3.7 | 상세화면 배경 사진 기능 (`backgroundImagePath` 모델 필드) | 감성 UX 강화 ✅ |
| 1.3.8 | 태블릿 768dp 기준 그리드 전환 + Setting 아이콘 크기 조정 | 태블릿 대응 ✅ |

---

## 2. 사업적 관점

### 2.1 핵심 가치 제안 (USP) 재검증

| USP | v1.1 | v1.4 현재 | 변화 |
|-----|------|-----------|------|
| 홈화면 위젯 D-Day | Android/iOS 멀티이벤트 탐색 | Large(4×4) 추가, 테마 완전 반영, 3단계 크기 | +++ |
| 감성적 공유 카드 | 공유 텍스트 개선 | 상세화면에서 직접 SHARE 버튼 추가 | + |
| 알림으로 D-Day 챙기기 | 권한 흐름 완성 | 변화 없음 (커스텀 알림 여전히 미구현) | 0 |
| 이벤트 상세 관리 | 토글만 가능 | Progress Bar + 마일스톤 CRUD + 배경사진 | +++ |

**홈위젯 3종(Small/Medium/Large) + 감성 상세화면이 앱의 두 핵심 강점으로 자리잡았다.**

### 2.2 사용자 유지 (Retention) 위협 요소

#### [CRITICAL] 데이터 유실 — 여전히 최대 위협

- SharedPreferences + 로컬 이미지 파일 이중 저장 구조로 위험 오히려 증가
- `backgroundImagePath` 가 앱 내부 경로를 저장하나, 앱 재설치 시 파일 삭제 → 경로 무효화
- 재설치·기기 변경 시 **D-Day 데이터 + 배경사진 모두 소멸**
- 클라우드 백업, JSON 내보내기/가져오기 모두 미구현
- **이 문제가 해결되지 않으면 장기 리텐션 확보 불가**

#### [HIGH] 온보딩 부재

- 첫 실행 시 기본 "23 days" 위젯 자동 생성되지만 설명 없음
- "+" FAB, 위젯 추가 방법, 홈화면 배치 안내 없음
- 신규 유저 5분 내 이탈율 높을 것으로 예상

#### [MEDIUM] 수익화 — 광고 활성화되었으나 최적화 필요

- v1.1 지적 사항(`setAdVisibility(false)`)이 주석 처리되어 광고 활성화됨 (`main.dart:79`) ✅
- App Open 광고 쿨다운 없음 — 포그라운드 전환마다 로드 시도 (UX + 정책 이슈)
- 인터스티셜·보상형 광고 미구현으로 수익 최대화 기회 손실
- `isPremium` 탭 한 번으로 ON/OFF — 결제 없는 프리미엄 기능 전환

### 2.3 시장 포지셔닝

```
UI 메인:        영어 ("YOUR MOMENTS", "EDIT EVENT", "SHARE")
다이얼로그/알림: 한국어 ("이벤트를 삭제할까요?", "알림 한도 초과")
위젯 안내:      한국어 ("홈화면 길게 누르기...")
iOS 위젯 문구:  한국어 ("소중한 날까지", "다음 이벤트")
공유 텍스트:    영어
```

**v1.1보다 영어/한국어 혼재가 오히려 심해졌다.** (배경사진 다이얼로그 등 신규 추가 UI가 한국어)
`flutter_ui_kit_l10n` 패키지가 이미 포함되어 있어 i18n 전환 기반은 갖춰져 있다.

---

## 3. 사용자 사용성 문제

### 3.1 사용자 여정 재점검

```
설치 → [문제: 온보딩 없음]
  ↓
D-Day 추가 → [개선: 권한 흐름 OK]
  ↓
상세 화면 → [대폭 개선: Progress + 마일스톤 + 배경사진 + SHARE]
  ↓
홈화면 위젯 → [대폭 개선: Small/Medium/Large, 테마 반영, 멀티이벤트]
  ↓
공유 → [개선: 상세화면 SHARE 버튼 추가]
  ↓
재설치 → [문제: 데이터 + 배경사진 모두 소멸]
```

### 3.2 배경사진 경로 취약성

`event_detail_screen.dart:45-46`:
```dart
String? _backgroundImagePath;   // 상대 경로 (backgrounds/bg_xxx.jpg)
String? _resolvedImagePath;     // 런타임 절대 경로
```

- 런타임에 `getApplicationDocumentsDirectory()` + 상대 경로로 절대 경로 복원하는 구조
- **앱 재설치 시 iOS에서 `getApplicationDocumentsDirectory()` 하위 폴더가 초기화** → 배경사진 무효화
- 배경사진을 설정한 사용자가 재설치 후 빈 화면을 보게 될 가능성 있음
- 최소한 파일 존재 여부 확인 + null fallback 처리 필요

### 3.3 커스텀 알림 설정 — CHANGELOG vs 코드 불일치 지속

CHANGELOG 1.0.1에 기록된 `NotificationSettingsPanel`, `scheduleForSettings()` — 코드에 존재하지 않음.
`notification_scheduler.dart`는 여전히 D-7/D-3/D-1/D-Day 4개 고정 트리거.
v1.4에서 구현하거나 CHANGELOG에서 제거해야 한다.

### 3.4 App Open 광고 쿨다운 없음

`main.dart:84`: `AppOpenAdManager.instance.loadAd()` — 앱 실행마다 로드.
`AppLifecycleState.resumed` 시 재로드 여부에 따라 백그라운드→포그라운드 전환마다 광고가 반복 노출될 수 있다. Google AdMob 정책상 최소 **1시간** 쿨다운 권장.

### 3.5 공유 화면 isPremium 자유 토글

`share_preview_screen_v2.dart:263-264`:
```dart
final nextPremium = !_model.style.isPremium;
setState(() => _model = _model.copyWith(style: _model.style.copyWith(isPremium: nextPremium)));
```
탭 한 번으로 워터마크 ON/OFF. 저장 시 무료 사용자가 프리미엄 기능 무제한 사용 가능.

---

## 4. 코드 버그 및 기술 부채

### 4.1 버그 목록

| 심각도 | 위치 | 문제 | 해결 방향 |
|--------|------|------|-----------|
| 🔴 | `pubspec.yaml:19` | 버전 1.1.2+4 vs CHANGELOG 1.3.8 — 8단계 괴리 | 1.3.8+N으로 동기화 |
| 🔴 | `event_detail_screen.dart` | 재설치 시 `backgroundImagePath` 유효하지 않음 | 파일 존재 검증 + null fallback |
| 🟡 | `share_preview_screen_v2.dart:263` | isPremium 자유 토글 | 토글 숨기거나 결제 상태 확인 로직 추가 |
| 🟡 | `main.dart:84` | App Open 광고 쿨다운 없음 | 마지막 표시 시각 저장 후 1시간 쿨다운 |
| 🟡 | `dayly_share_export.dart:12` | `pixelRatio = 3` 고정 — 저사양 OOM 가능 | `MediaQuery.devicePixelRatio` 활용 |
| 🟡 | `notification_scheduler.dart` | CHANGELOG 1.0.1 기능(`NotificationSettingsPanel`) 코드 없음 | 구현 또는 CHANGELOG 정정 |
| 🟠 | `event_detail_screen.dart:60` | `Timer.periodic(1s)` — 백그라운드에서도 실행 | `AppLifecycleState` 감지 후 pause |
| 🟠 | 공유 텍스트 | iOS용 App Store 링크 없음 (Play Store만) | `Platform.isIOS` 분기 처리 |
| 🟠 | 저장소 전체 | 단위 테스트 0개 | 날짜 계산, `fromJson` 등 최소 커버리지 추가 |

### 4.2 기술 부채

```
pubspec 버전 동결
  ├─ pubspec: 1.1.2+4 / CHANGELOG: 1.3.8
  ├─ 스토어 배포 시 빌드 번호 혼선 발생
  └─ 즉시 동기화 필요 (1.3.8+N)

isPremium 결제 스텁 (v1.0부터 지적, 4차례 지속)
  ├─ 자유 토글 → 유료 기능 무료 사용 가능
  ├─ In-app purchase 미구현
  └─ RevenueCat 또는 in_app_purchase 패키지 필요

데이터 무보호 저장 구조
  ├─ SharedPreferences 단독 저장 (재설치 시 전체 소멸)
  ├─ backgroundImagePath가 로컬 경로 → 재설치 후 무효화
  └─ JSON 내보내기/가져오기 최소 구현 필요

CHANGELOG-코드 불일치 (v1.1부터 지적, 지속)
  ├─ 1.0.1: NotificationSettingsPanel, scheduleForSettings → 코드 없음
  ├─ 1.0.1: "하위 6비트 확장" → 코드는 4비트
  └─ 기능 구현 또는 CHANGELOG 정정 필요

테스트 코드 0개 (v1.1부터 지적, 지속)
  ├─ 비즈니스 로직 미검증 (날짜 계산, 알림 ID 생성 등)
  └─ 리팩터링 시 회귀 탐지 불가
```

### 4.3 Android/iOS 위젯 현황 업데이트

| 항목 | Android | iOS | 격차 |
|------|---------|-----|------|
| 크기 | Small / Medium / **Large** | Small / Medium | iOS Large 미지원 ⚠️ |
| D-Day 계산 | 렌더 시점 실시간 | 렌더 시점 실시간 (v1.2.3~) | 동등 ✅ |
| 테마 반영 | 5종 완전 반영 (v1.3.3~) | 5종 완전 반영 | 동등 ✅ |
| 워터마크 | 우측 하단 표시 | 미확인 | 검증 필요 |
| 멀티이벤트 탐색 | StackView fling | 좌우 화살표 버튼 | UX 상이하나 기능 동등 |

---

## 5. 긍정적 평가 (강점) — v1.1 대비 추가

- **3단계 홈위젯(Small/Medium/Large)** — 다양한 홈화면 레이아웃 대응, 경쟁 앱 대비 차별화
- **배경사진 기능** — 감성 앱 정체성 강화, 개인화 첫 발걸음
- **D-Day 진행률 Progress Bar** — `createdAt` 기반 정확한 계산, 시간 흐름 시각화
- **마일스톤 CRUD** — 단순 체크리스트에서 이벤트 관리 도구로 진화
- **상세화면 SHARE 버튼** — 공유 진입점 다양화
- **Firebase 완전 제거** — 앱 사이즈 감소 + iOS 크래시 근본 해결
- **태블릿 대응** — 768dp 기준 2열 그리드, 향후 iPad 출시 기반 마련
- **광고 활성화** — `setAdVisibility(false)` 주석 처리 → 실제 수익 발생 시작

---

## 6. 개선 로드맵 (우선순위순)

### Phase 1 — 출시 블로커 해소 (즉시)

1. **pubspec 버전 동기화** — `1.3.8+N`으로 수정 (스토어 배포 전 필수)
2. **isPremium 토글 차단** — 결제 미구현 상태라면 UI에서 토글 숨기기 (무료 프리미엄 방지)
3. **App Open 광고 쿨다운** — 마지막 표시 시각 저장, 1시간 이내 재노출 차단
4. **iOS 공유 텍스트 App Store 링크** — `Platform.isIOS` 분기 처리
5. **backgroundImagePath 유효성 검증** — 파일 존재 여부 확인 후 null fallback

### Phase 2 — 데이터 안전성 (1주)

1. **JSON 내보내기/가져오기** — `DaylyWidgetModel` 리스트를 JSON 파일로 내보내기 + 복원 (배경사진 미포함이라도 최소 구현)
2. **배경사진 내보내기 전략 결정** — 사진을 번들에 포함할지, 링크만 저장할지
3. **CHANGELOG-코드 불일치 정리** — 1.0.1 미구현 항목 삭제 또는 구현 일정 명시

### Phase 3 — 사용자 경험 개선 (2주)

1. **온보딩 화면** — 3~4페이지 슬라이드: ①위젯 설명 ②D-Day 추가 방법 ③홈화면 배치 안내
2. **언어 통일** — 한국어 단일 또는 `flutter_ui_kit_l10n` 기반 i18n 본격 적용
3. **iOS Large(4×4) 위젯** — Android와 동등한 크기 옵션 제공
4. **커스텀 알림 설정** — CHECK-v1.1.md §8에서 설계된 `DaylyNotificationSettings` 모델 + UI 구현 (CHANGELOG 1.0.1 약속 이행)

### Phase 4 — 수익화 (2~3주)

1. **인터스티셜 광고** — 위젯 생성/편집 완료 후 노출 (공유 흐름 제외)
2. **보상형 광고** — "프리미엄 테마 24시간 체험" + "워터마크 없는 공유 1회"
3. **RevenueCat + In-app purchase** — 월간($1.99)/연간($9.99)/평생($19.99) 구독 구현
4. **isPremium 결제 연동** — 구독 상태 기반 프리미엄 기능 잠금 해제

### Phase 5 — 품질 강화 (지속)

1. **단위 테스트** — `DaylyWidgetModel.fromJson`, `progress` 계산, 날짜 유틸 최소 커버리지
2. **`pixelRatio` 동적 조절** — `MediaQuery.of(context).devicePixelRatio` 활용
3. **`Timer.periodic` 최적화** — 상세화면 카운트다운 타이머를 백그라운드 시 pause

---

## 7. 출시 준비도 평가

| 항목 | v1.0 | v1.1 | v1.4 현재 | 변화 | 근거 |
|------|------|------|-----------|------|------|
| 기능 완성도 | 60 | 78 | **88** | +10 | 위젯 3종 + 상세화면 완성도 대폭 향상 |
| 안정성 | 50 | 68 | **76** | +8 | Firebase 제거, DST·클리핑·D-0 버그 수정. pubspec 불일치 감점 |
| 사용성 | 55 | 62 | **68** | +6 | 상세화면 개선, 태블릿 대응. 온보딩·언어 미해결 |
| 수익화 | 20 | 30 | **38** | +8 | 광고 활성화. 인터스티셜·보상형·IAP 미구현 |
| 마케팅 준비 | 30 | 32 | **35** | +3 | 변화 미미. 언어 혼재로 ASO 어려움 |
| **종합** | **43** | **54** | **61** | **+7** | **Phase 1 완료 시 70+, Phase 2까지 78+ 예상** |

---

## 8. 결론

v1.1 대비 7점 상승(54 → 61). 위젯 완성도와 상세화면 UX는 경쟁 앱 수준에 도달했다.

**지금 당장 해야 할 3가지:**

1. **pubspec 버전 1.3.8+N 동기화** — 스토어 배포 시 빌드 번호 혼선 방지 (5분 작업)
2. **App Open 광고 쿨다운** — 반복 노출로 인한 UX 훼손 + AdMob 정책 위반 방지
3. **backgroundImagePath 유효성 검증** — 재설치 후 빈 화면 방어 (null fallback)

이 3가지 이후에는 **데이터 백업 → 온보딩 → 결제 연동** 순서로 진행하면 된다.

앱의 감성 디자인과 위젯 다양성은 이미 경쟁력 있다. 남은 과제는 "믿을 수 있는 앱"으로 만드는 것 — 데이터를 지키고, 결제를 정직하게 구현하고, 신규 사용자가 길을 잃지 않도록 하는 것이다.
