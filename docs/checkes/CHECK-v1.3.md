# Dayly v1.3 기획 — 이벤트 상세 화면 개선

> 작성일: 2026-03-08
> 대상 버전: 1.3.0
> 이전 점검: CHECK-v1.1.md
> 핵심: 이벤트 상세 화면(EventDetailScreen) UX 고도화

---

## 1. 개요

레퍼런스 디자인(detail_screen.png 중앙 화면)을 기반으로 이벤트 상세 화면을 개선한다.
핵심 추가/개선 항목:

| # | 기능 | 현재 상태 | 목표 |
|---|------|-----------|------|
| 1 | D-Day 진행률 표시 | 없음 | 원형 Progress 표시 (createdAt 기반) |
| 2 | 마일스톤 CRUD | 토글만 가능 | 추가/삭제/편집 가능 |
| 3 | Share 버튼 | 상세 화면에 없음 | EDIT EVENT 옆에 SHARE 버튼 추가 |
| 4 | createdAt 필드 | 모델에 없음 | DaylyWidgetModel에 추가 |

---

## 2. 데이터 모델 변경

### 2.1 `DaylyWidgetModel`에 `createdAt` 추가

```dart
class DaylyWidgetModel {
  // ... 기존 필드 ...
  final DateTime createdAt;  // 신규

  double get progress {
    final total = targetDate.difference(createdAt).inDays;
    if (total <= 0) return 1.0;
    final elapsed = DateTime.now().difference(createdAt).inDays;
    return (elapsed / total).clamp(0.0, 1.0);
  }
}
```

- 기존 데이터 마이그레이션: `createdAt` 없으면 `DateTime.now()` fallback (진행률 0%부터 시작)
- `toJson()`/`fromJson()` 확장

---

## 3. 이벤트 상세 화면 UI 변경

### 3.1 Progress 표시 (Hero Card 내)

히어로 카드 내에 D-Day 진행률을 표시한다.

```
┌─────────────────────────────────┐
│          [아이콘 박스]           │
│                                 │
│            D-30                 │
│        EUROPE TRIP              │
│      JUN 01, 2026               │
│                                 │
│    ┌───────────────────┐        │
│    │ ██████░░░░  72%   │        │ ← 진행률 바
│    │  PROGRESS          │        │
│    └───────────────────┘        │
│                                 │
│    ┌───────────────────┐        │
│    │  COUNTDOWN         │        │
│    │  04 : 23 : 15      │        │
│    │  HRS  MIN  SEC     │        │
│    └───────────────────┘        │
└─────────────────────────────────┘
```

- `createdAt` ~ `targetDate` 기간 대비 경과 비율
- LinearProgressIndicator + 퍼센트 텍스트
- 그라데이션 색상 적용

### 3.2 마일스톤 CRUD

현재: 토글만 가능, 생성/삭제 불가
개선:

```
MILESTONES                    75%
████████████████░░░░░░░░░░░░░░

[v] Book Flights          MAR 15  [x]
[ ] Book Hotels           MAR 20  [x]
[v] Check your insurance          [x]

[+ Add milestone]
```

- 각 마일스톤 우측에 삭제(x) 버튼
- 하단에 "+ Add milestone" 버튼 → 인라인 텍스트 입력
- 마일스톤 추가 시 선택적으로 dueDate 설정 가능

### 3.3 Share 버튼 추가

```
┌──────────────────┐  ┌──────────────────┐
│   EDIT EVENT     │  │     SHARE        │
└──────────────────┘  └──────────────────┘
```

- EDIT EVENT 버튼과 나란히 배치
- 기존 SharePreviewScreenV2로 이동하여 공유 실행

---

## 4. 구현 체크리스트

- [x] `DaylyWidgetModel`에 `createdAt` 필드 추가
- [x] `toJson()`/`fromJson()` 마이그레이션
- [x] `add_widget_bottom_sheet.dart`에서 생성 시 `createdAt: DateTime.now()` 설정
- [x] Hero Card에 Progress 표시 추가
- [x] 마일스톤 추가 버튼 UI
- [x] 마일스톤 삭제 버튼 UI
- [x] SHARE 버튼 추가
- [x] CHANGELOG.md 업데이트
