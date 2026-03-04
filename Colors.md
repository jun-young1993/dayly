# Flutter UI Kit Theme — 색상 가이드

다른 프로젝트에서 이 테마 패키지를 사용할 때 Claude Code에게 전달하기 위한 색상 레퍼런스 문서입니다.

---

## 1. 패키지 개요

`flutter_ui_kit_theme` 패키지는 Material 3 기반의 멀티 테마 시스템입니다.

- **기본 테마 (App)**: Violet 계열
- **Brand A 테마**: Violet 계열 (App과 동일 구조, 독립 커스터마이징 가능)
- **Brand B 테마**: Emerald 계열 (둥근 컴포넌트 모서리 포함)

각 테마는 `light` / `dark` 두 가지 밝기 모드를 지원합니다.

---

## 2. 색상 토큰 (AppColors)

> ⚠️ 색상 토큰은 직접 사용하지 말고 항상 `ColorScheme`을 통해 사용하세요.

### Violet 팔레트 (Primary — Brand A/App)

| 토큰 | Hex | 설명 |
|------|-----|------|
| `violet50` | `#F0EFFE` | 가장 옅음 |
| `violet100` | `#E4E1FD` | |
| `violet200` | `#CCC6FB` | |
| `violet300` | `#ADA4F8` | |
| `violet400` | `#8E84F5` | |
| `violet500` | `#6C63FF` | ★ 브랜드 Primary (시드 색상) |
| `violet600` | `#5A52D5` | |
| `violet700` | `#4840AB` | |
| `violet800` | `#362F82` | |
| `violet900` | `#241E58` | |
| `violet950` | `#120F30` | 가장 진함 |

### Emerald 팔레트 (Primary — Brand B)

| 토큰 | Hex | 설명 |
|------|-----|------|
| `emerald50` | `#E8FFF2` | 가장 옅음 |
| `emerald100` | `#B3F5D3` | |
| `emerald200` | `#80EBB5` | |
| `emerald300` | `#4DD898` | |
| `emerald400` | `#26C97E` | |
| `emerald500` | `#00C853` | ★ Brand B Primary (시드 색상) |
| `emerald600` | `#00A843` | |
| `emerald700` | `#008833` | |
| `emerald800` | `#006824` | |
| `emerald900` | `#004815` | 가장 진함 |

### Ink (Neutral) 팔레트 — 배경/텍스트/테두리

| 토큰 | Hex | 설명 |
|------|-----|------|
| `ink0` | `#FFFFFF` | 흰색 (Light 배경) |
| `ink50` | `#F8F9FB` | Light surfaceContainerLow |
| `ink100` | `#EEF0F4` | Light surfaceContainer |
| `ink200` | `#D8DCE6` | Light surfaceContainerHigh |
| `ink300` | `#B4BAC8` | Light surfaceContainerHighest / Dark onSurfaceVariant |
| `ink400` | `#8A93A8` | |
| `ink500` | `#606B84` | Light outline |
| `ink600` | `#3E4860` | Light onSurfaceVariant / Dark outline |
| `ink700` | `#1E2740` | Dark outlineVariant |
| `ink800` | `#0D1F3C` | Dark surfaceContainerHigh |
| `ink900` | `#0A0E1A` | ★ Dark 메인 배경 (surface) |
| `ink950` | `#070B14` | Dark surfaceContainerLowest |

### 시맨틱 유틸리티 색상

| 토큰 | Hex | 용도 |
|------|-----|------|
| `red300` | `#FF8A80` | 에러 (Dark) |
| `red400` | `#FF5252` | 에러 강조 |
| `red500` | `#E53935` | 에러 (Light) |
| `red700` | `#B71C1C` | 에러 컨테이너 |
| `red900` | `#4E0000` | 에러 배경 (Dark) |
| `amber300` | `#FFD54F` | 경고 (Dark) |
| `amber500` | `#FFC107` | 경고 (Light) |
| `green300` | `#69F0AE` | 성공 (Dark) |
| `green500` | `#00C853` | 성공 (Light) |
| `scrim` | `#000000` | 모달 스크림 |
| `transparent` | `#00000000` | 투명 |

---

## 3. ColorScheme 역할별 색상

Material 3 `ColorScheme`의 각 역할에 매핑되는 실제 색상입니다.

### 서피스 스택 (Light vs Dark 공통 구조)

| ColorScheme 역할 | 사용처 | Light Hex | Dark Hex |
|------------------|--------|-----------|----------|
| `surface` | 메인 배경 | `#FFFFFF` (ink0) | `#0A0E1A` (ink900) |
| `surfaceContainerLowest` | 가장 낮은 레이어 | `#FFFFFF` (ink0) | `#070B14` (ink950) |
| `surfaceContainerLow` | 카드 배경 | `#F8F9FB` (ink50) | `#090D18` |
| `surfaceContainer` | 네비게이션 바 | `#EEF0F4` (ink100) | `#0B1220` |
| `surfaceContainerHigh` | 다이얼로그 | `#D8DCE6` (ink200) | `#0D1F3C` (ink800) |
| `surfaceContainerHighest` | 입력 필드 배경 | `#B4BAC8` (ink300) | `#162540` |
| `onSurface` | 기본 텍스트 | `#0A0E1A` (ink900) | `#EEF0F4` (ink100) |
| `onSurfaceVariant` | 보조 텍스트/아이콘 | `#3E4860` (ink600) | `#B4BAC8` (ink300) |
| `outline` | 테두리 | `#606B84` (ink500) | `#3E4860` (ink600) |
| `outlineVariant` | 보조 테두리, Divider | `#B4BAC8` (ink300) | `#1E2740` (ink700) |
| `scrim` | 모달 배경 | `#000000` | `#000000` |

### Primary 계열 (Material 3 자동 생성)

| ColorScheme 역할 | Light | Dark |
|------------------|-------|------|
| `primary` | `#6C63FF` | `#6C63FF` |
| `onPrimary` | `#FFFFFF` (자동) | `#FFFFFF` (자동) |
| `primaryContainer` | violet200~300 계열 (자동) | violet800~900 계열 (자동) |
| `onPrimaryContainer` | violet900 계열 (자동) | violet100 계열 (자동) |

> `primary` 외 나머지는 `ColorScheme.fromSeed(seedColor: violet500)`이 Material 3 알고리즘으로 자동 계산합니다.

### Brand B의 Primary 차이점

Brand B는 시드 색상만 다릅니다:

| 역할 | Brand A / App | Brand B |
|------|--------------|---------|
| `primary` | `#6C63FF` (violet500) | `#00C853` (emerald500) |
| `primaryContainer` | violet 계열 (자동) | emerald 계열 (자동) |

---

## 4. 테마별 전체 색상 요약

### AppTheme / BrandATheme (Violet)

```
Light:
  seed:                    #6C63FF
  surface:                 #FFFFFF
  surfaceContainerLow:     #F8F9FB
  surfaceContainer:        #EEF0F4
  surfaceContainerHigh:    #D8DCE6
  surfaceContainerHighest: #B4BAC8
  onSurface:               #0A0E1A
  onSurfaceVariant:        #3E4860
  outline:                 #606B84
  outlineVariant:          #B4BAC8

Dark:
  seed:                    #6C63FF
  surface:                 #0A0E1A
  surfaceContainerLowest:  #070B14
  surfaceContainerLow:     #090D18
  surfaceContainer:        #0B1220
  surfaceContainerHigh:    #0D1F3C
  surfaceContainerHighest: #162540
  onSurface:               #EEF0F4
  onSurfaceVariant:        #B4BAC8
  outline:                 #3E4860
  outlineVariant:          #1E2740
```

### BrandBTheme (Emerald)

```
Light:
  seed:                    #00C853  ← 유일한 차이점
  surface:                 #FFFFFF
  surfaceContainerLow:     #F8F9FB
  surfaceContainer:        #EEF0F4
  surfaceContainerHigh:    #D8DCE6
  surfaceContainerHighest: #B4BAC8
  onSurface:               #0A0E1A
  onSurfaceVariant:        #3E4860
  outline:                 #606B84
  outlineVariant:          #B4BAC8

Dark:
  seed:                    #00C853  ← 유일한 차이점
  surface:                 #0A0E1A
  surfaceContainerLowest:  #070B14
  surfaceContainerLow:     #090D18
  surfaceContainer:        #0B1220
  surfaceContainerHigh:    #0D1F3C
  surfaceContainerHighest: #162540
  onSurface:               #EEF0F4
  onSurfaceVariant:        #B4BAC8
  outline:                 #3E4860
  outlineVariant:          #1E2740
```

---

## 5. 컴포넌트별 색상 사용

각 컴포넌트가 `ColorScheme`의 어느 역할을 사용하는지 정리합니다.

| 컴포넌트 | 배경 색상 | 텍스트/아이콘 색상 | 기타 |
|---------|-----------|-------------------|------|
| `AppBar` | `surface` | `onSurface` (제목), `onSurfaceVariant` (아이콘) | |
| `Card` | `surfaceContainerLow` | — | shadow 포함 |
| `FilledButton` | `primary` | `onPrimary` | |
| `ElevatedButton` | `surfaceContainerLow` | `primary` | |
| `OutlinedButton` | 투명 | `primary` | `outline` 테두리 |
| `TextField` | `surfaceContainerHighest` | `onSurface` | `outline` 테두리, `primary` 포커스 |
| `Dialog` | `surfaceContainerHigh` | `onSurface` (제목), `onSurfaceVariant` (내용) | |
| `BottomSheet` | `surfaceContainerLow` | — | |
| `NavigationBar` | `surfaceContainer` | `onSurfaceVariant` (미선택), `onSecondaryContainer` (선택) | `secondaryContainer` 인디케이터 |
| `NavigationRail` | `surfaceContainerLow` | `onSurfaceVariant` (미선택) | |
| `Divider` | — | — | `outlineVariant` 색상 |
| `ListTile` | 투명 | `onSurface` (제목), `onSurfaceVariant` (아이콘/보조) | |
| `SnackBar` | `inverseSurface` | `onInverseSurface` | `primary` (액션 버튼) |
| `Switch` | `primary` (활성), `surfaceContainerHighest` (비활성) | — | |
| `Checkbox` | `primary` (체크), 투명 (미체크) | — | `outline` 테두리 |
| `Tooltip` | `inverseSurface` | `onInverseSurface` | |

---

## 6. 위젯별 색상 사용

패키지에 포함된 커스텀 위젯들의 색상 사용 정보입니다.

### `DsThemeToggle` (테마 토글 버튼)

```
배경:  cs.surfaceContainerHigh
아이콘: cs.primary
```

### `DsSurface` / `DsCard` (서피스 컴포넌트)

`SurfaceLevel` enum에 따라 배경색이 자동 매핑됩니다:

```
SurfaceLevel.lowest  → cs.surfaceContainerLowest
SurfaceLevel.low     → cs.surfaceContainerLow
SurfaceLevel.base    → cs.surfaceContainer
SurfaceLevel.high    → cs.surfaceContainerHigh
SurfaceLevel.highest → cs.surfaceContainerHighest
```

### `DsButton` (버튼 위젯)

```
FilledButton 로딩 스피너:  cs.onPrimary
기타 버튼 로딩 스피너:     cs.primary
```

---

## 7. Brand B 컴포넌트 오버라이드 (색상 외 차이점)

Brand B는 색상 외에 컴포넌트 모양도 다릅니다:

| 항목 | App / Brand A | Brand B |
|------|--------------|---------|
| 버튼 모서리 | 12px (md) | 24px (xl) — 더 둥글게 |
| 카드 모서리 | 12px (md) | 24px (xl) — 더 둥글게 |
| 버튼 최소 높이 | 48px | 52px — 더 큰 탭 영역 |

---

## 8. ThemeData 빌더 사용법

```dart
// App / Brand A
MaterialApp(
  theme: LightTheme.build(),       // 또는 BrandATheme.light()
  darkTheme: DarkTheme.build(),    // 또는 BrandATheme.dark()
)

// Brand B
MaterialApp(
  theme: BrandBTheme.light(),
  darkTheme: BrandBTheme.dark(),
)
```

---

## 9. 설계 원칙 요약

1. **색상 토큰 직접 사용 금지** — `AppColors`는 정의만, 실제 사용은 항상 `ColorScheme`을 통해
2. **Material 3 기반** — `ColorScheme.fromSeed()` 자동 tonal 팔레트 활용
3. **Light/Dark 대칭** — 서피스 스택은 동일 구조, ink 팔레트 방향만 반전
4. **브랜드 확장** — 시드 색상만 교체하면 새 브랜드 테마 생성 가능
5. **프리미엄 다크 배경** — Navy 계열(`#0A0E1A`)을 기본 다크 배경으로 사용
