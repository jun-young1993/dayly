# 💎 Project: Ultimate Emotion D-Day App (Universal Design)

이 문서는 모바일과 테블릿을 모두 지원하며, 글래스모피즘과 실시간 카운트다운 기능이 포함된 프리미엄 D-Day 앱 구현을 위한 최종 가이드라인입니다.

---

## 1. Design System & Visuals
- **Style:** Glassmorphism + Minimalist Premium
- **Background:** - 기본: Deep Navy & Charcoal (#1A1C20 to #0F1012) 애니메이션 그라데이션.
  - 상세보기: 고해상도 배경 이미지 + BackdropFilter(Sigma 20) + Dark Overlay.
- **Typography:** - Numbers: 'Montserrat' 또는 'Inter' (Extra Bold)
  - Korean: 'Pretendard' (Variable Weight)

---

## 2. Screen Specifications & Features

### 📱 Screen 1: Dashboard (List)
- **Responsive Layout:** `flutter_screenutil`을 사용하여 모바일(1열), 테블릿(2열 Grid) 대응.
- **Glass Cards:** 테두리에 0.5px 화이트 라인(Edge Light)을 추가한 투명 카드.
- **Progress:** 마일스톤(25%, 50%, 75%)이 표시된 슬림한 진행바.

### 📱 Screen 2: Event Detail (New!)
- **Immersive View:** 배경 이미지가 전체를 차지하는 몰입형 레이아웃.
- **Real-time Counter:** 초(seconds) 단위까지 실시간으로 줄어드는 애니메이션 카운트다운 타이머 구현.
- **Note System:** 하단 Glass Card 내부에 멀티라인 메모 및 체크리스트 기능.
- **Actions:** 공유하기(Share), 삭제(Delete), 편집(Edit) 버튼을 세련된 라인 아이콘으로 배치.

### 📱 Screen 3: Add/Edit Moment
- **Input UX:** 유리 카드 형태의 입력 폼. 텍스트 필드 포커스 시 테두리에 은은한 네온 글로우 효과.
- **Theme Picker:** 파스텔톤 그라데이션 아이콘 팩 선택 기능.

---

## 3. Technical Implementation (Flutter)

### ✅ Essential Packages
- `flutter_screenutil`: 전 기기 반응형 레이아웃 (`.w`, `.h`, `.sp` 필수 사용)
- `glassmorphism`: UI 질감 구현
- `google_fonts`: 프리미엄 폰트 적용
- `intl` & `async`: 날짜 계산 및 실시간 타이머(Timer.periodic)

### ✅ Optimization Points
- **Tablet Strategy:** `MediaQuery`를 사용하여 화면 너비 600dp 이상일 때 리스트의 `crossAxisCount`를 2로 자동 전환.
- **Micro-interaction:** - 카드 클릭 시 `Hero` 애니메이션을 사용하여 리스트에서 상세 화면으로 자연스럽게 전환.
  - 모든 액션에 `HapticFeedback.mediumImpact()` 적용.

---

## 4. Final Prompt for AI (Instructions)

> "첨부된 3장의 디자인 시안(리스트, 추가, 상세)을 분석하여 Flutter 코드를 작성해줘.
> 
> **명령어:**
> 1. `flutter_screenutil`을 적용하여 모바일과 테블릿에서 완벽하게 작동하는 반응형 UI를 짜줘.
> 2. 상세 화면에서는 초 단위로 변하는 실시간 카운트다운 위젯을 포함해줘.
> 3. 글래스모피즘 패키지를 활용해 투명도가 살아있는 고급스러운 질감을 구현해줘.
> 4. 리스트에서 상세 화면으로 넘어갈 때 `Hero` 위젯을 사용하여 시각적 연속성을 줘.
> 5. 테블릿 화면에서는 2열 그리드 레이아웃이 되도록 작성해줘.
> 
> 전체 앱의 구조와 각 화면의 위젯 코드를 Clean Architecture 스타일로 구분해서 작성해줄래?"