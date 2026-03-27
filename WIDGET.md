# Android 홈 위젯 커스터마이징 가이드

Android 홈 위젯의 배경 이미지 투명도 및 오버레이를 자유롭게 수정하기 위한 가이드.

---

## 핵심 파일

| 역할 | 파일 |
|------|------|
| **투명도 로직 (수정 핵심)** | `android/app/src/main/kotlin/juny/dayly/DaylyWidgetRemoteViewsService.kt` |
| 레이아웃 (Medium 4×2) | `android/app/src/main/res/layout/dayly_widget_stack_item_medium.xml` |
| 레이아웃 (Large 4×4) | `android/app/src/main/res/layout/dayly_widget_stack_item_large.xml` |

---

## 배경 이미지 투명도 구조

배경 이미지가 있을 때 **두 개의 레이어**가 겹쳐 최종 시각 결과를 만든다.

```
┌──────────────────────────────┐
│  텍스트 (문구, D-Day 숫자)     │  ← 최상단
├──────────────────────────────┤
│  검은 오버레이 (widget_bg_overlay)  │  ← 가독성 보호
├──────────────────────────────┤
│  배경 이미지 (widget_bg_image) │  ← 알파 적용된 사진
├──────────────────────────────┤
│  테마 배경 (widget_container) │  ← 가장 하단
└──────────────────────────────┘
```

---

## 투명도 설정 위치 (수정할 코드)

**파일:** `DaylyWidgetRemoteViewsService.kt` — 라인 142~161

```kotlin
// 배경 이미지 처리 (Medium/Large only)
if (size != WidgetSize.SMALL) {
    val absPath = resolveImagePath(context, data.backgroundImagePath)
    val bitmap = absPath?.let { loadScaledBitmap(it) }
    if (bitmap != null) {
        setImageViewBitmap(R.id.widget_bg_image, bitmap)

        // ★ [수정 포인트 1] 배경 이미지 알파값
        // 범위: 0.0f (완전 투명) ~ 1.0f (완전 불투명)
        // 현재값: 0.65f → 사진이 65% 불투명하게 표시됨
        setFloat(R.id.widget_bg_image, "setAlpha", 0.65f)

        setViewVisibility(R.id.widget_bg_image, View.VISIBLE)
        setViewVisibility(R.id.widget_bg_overlay, View.VISIBLE)

        // ★ [수정 포인트 2] 검은 오버레이 알파값
        // Color.argb(alpha, red, green, blue)
        // alpha 범위: 0 (완전 투명) ~ 255 (완전 불투명)
        // 현재값: 70 → 약 27.5% 불투명한 검은 필터
        setInt(R.id.widget_bg_overlay, "setBackgroundColor",
            Color.argb(70, 0, 0, 0))
    } else {
        // 배경 이미지 없을 때 초기화
        setImageViewBitmap(R.id.widget_bg_image, null)
        setViewVisibility(R.id.widget_bg_image, View.GONE)
        setViewVisibility(R.id.widget_bg_overlay, View.GONE)
        setInt(R.id.widget_container, "setBackgroundResource", theme.bgDrawable)
    }
}
```

---

## 수정 예시

### 배경 이미지를 더 진하게 (사진이 잘 보이게)
```kotlin
setFloat(R.id.widget_bg_image, "setAlpha", 0.85f)   // 0.65 → 0.85
setInt(R.id.widget_bg_overlay, "setBackgroundColor",
    Color.argb(40, 0, 0, 0))                         // 70 → 40 (오버레이 줄이기)
```

### 배경 이미지를 더 흐리게 (텍스트 가독성 우선)
```kotlin
setFloat(R.id.widget_bg_image, "setAlpha", 0.45f)   // 0.65 → 0.45
setInt(R.id.widget_bg_overlay, "setBackgroundColor",
    Color.argb(100, 0, 0, 0))                        // 70 → 100 (오버레이 강화)
```

### 오버레이 색상 변경 (흰색 오버레이로 밝은 느낌)
```kotlin
setFloat(R.id.widget_bg_image, "setAlpha", 0.6f)
setInt(R.id.widget_bg_overlay, "setBackgroundColor",
    Color.argb(50, 255, 255, 255))                   // 흰색 오버레이
```

### 오버레이 제거 (이미지만)
```kotlin
setFloat(R.id.widget_bg_image, "setAlpha", 0.75f)
setViewVisibility(R.id.widget_bg_overlay, View.GONE) // 오버레이 비활성화
```

---

## 참고: 알파값 빠른 변환표

| `setAlpha` 값 | 불투명도 | 체감 |
|--------------|---------|------|
| `0.30f` | 30% | 매우 흐림 |
| `0.50f` | 50% | 절반 |
| `0.65f` | 65% | **현재값** |
| `0.80f` | 80% | 선명함 |
| `1.00f` | 100% | 원본 그대로 |

| `Color.argb(alpha, ...)` alpha 값 | 오버레이 강도 |
|----------------------------------|-------------|
| `0` | 오버레이 없음 |
| `40` | 약한 필터 |
| `70` | **현재값** |
| `120` | 중간 필터 |
| `180` | 강한 필터 |

---

## 제약 사항

- **Small 위젯 (2×2)** 은 배경 이미지를 지원하지 않는다. (`size != WidgetSize.SMALL` 조건으로 제외)
- 비트맵은 메모리 효율을 위해 최대 **400×400px** 로 자동 축소된다. (`loadScaledBitmap()` 함수, 라인 58-69)
- 수정 후에는 **기기에서 위젯을 제거 후 재추가**해야 변경사항이 반영된다. (RemoteViews 캐싱 이슈)
