---
name: freebay-design-system
description: Authoritative guide and token reference for the FreeBay "Digital Brutalist" Flutter design system — 0px radius, tonal layering without shadows, no divider lines, Space Grotesk / Inter typography, and curated brutalist component primitives.
---

# FreeBay Design System: "The Digital Brutalist"

## Core Philosophy & Design Axioms

FreeBay employs a **Digital Brutalist** design aesthetic engineered for high utilitarian clarity, crisp typographic hierarchy, tactile feedback, and extreme visual distinction.

### The 7 Golden Rules

1. **0px Border Radius Everywhere**: No exceptions. Never use `BorderRadius.circular()`, `RoundedRectangleBorder()`, or `StadiumBorder()`. All containers, chips, dialogs, bottom sheets, avatars, and buttons must have razor-sharp $90^\circ$ rectangular corners.
2. **Zero Default Shadows**: Never use standard blurred drop shadows (`BoxShadow` with blur radius). Depth and hierarchy are achieved exclusively through **Tonal Layering** (step-wise shifts in background surface lightness).
3. **No Divider Lines**: Never use `Divider()` or horizontal thin gray separator borders. Visual separation between content blocks is created via **tonal surface blocking** (placing adjacent surfaces of slightly different tonal steps).
4. **Typographic Pair**:
   - **Space Grotesk** (`SpaceGrotesk` font family): For all headings, display titles, numeral metrics, and price tags.
   - **Inter** (`Inter` font family): For all body copy, forms, inputs, metadata, captions, and microcopy.
5. **Primary Accent as a Laser**: `#8A1083` (Signature Magenta) is used with restraint for primary actions, badges, active tabs, and key focus states — never as vast flooded backgrounds.
6. **Ultra-Snappy Micro-Animations**: Maximum duration **150ms** with `Curves.linear` or `Curves.easeOutQuad`. Avoid slow bouncy easings.
7. **Flawless Dark Mode Support**: Every component must adapt dynamically using `context.colors` (or `AppColors`) and `context.isDark`.

---

## 1. Color Tokens & Tonal Hierarchy

### 1.1 Surface Tonal Palette (Light Theme)
```
Surface Level 0 (Base Canvas):    #F9F9F9  (AppColors.surface)
Surface Level 1 (Card / Tile):     #F3F3F3  (AppColors.surfaceContainerLow)
Surface Level 2 (Elevated Card):   #EEEEEE  (AppColors.surfaceContainer)
Surface Level 3 (High Elevation):  #E2E2E2  (AppColors.surfaceContainerHigh)
Surface Level 4 (Highest Accent):  #D6D6D6  (AppColors.surfaceContainerHighest)
```

### 1.2 Surface Tonal Palette (Dark Theme)
```
Surface Level 0 (Base Canvas):    #121212  (AppColorsDark.surface)
Surface Level 1 (Card / Tile):     #1E1E1E  (AppColorsDark.surfaceContainerLow)
Surface Level 2 (Elevated Card):   #252525  (AppColorsDark.surfaceContainer)
Surface Level 3 (High Elevation):  #2E2E2E  (AppColorsDark.surfaceContainerHigh)
Surface Level 4 (Highest Accent):  #383838  (AppColorsDark.surfaceContainerHighest)
```

### 1.3 Brand & Status Accents
- **Primary Magenta**: `#8A1083` (`AppColors.primary`)
- **Primary Dark Variant**: `#660062` (`AppColors.primaryDark`)
- **Secondary Accent**: `#2A0845`
- **Text Main**: `#111111` (Light) / `#F5F5F5` (Dark)
- **Text Muted / Subtitle**: `#666666` (Light) / `#AAAAAA` (Dark)
- **Success / Escrow Released**: `#00875A`
- **Warning / Escrow Held**: `#FFAB00`
- **Error / Dispute**: `#DE350B`

---

## 2. Typography Reference

```dart
// Space Grotesk Display Headings
AppTypography.displayLarge  // 32sp, FontWeight.w700, letterSpacing: -0.5
AppTypography.displayMedium // 24sp, FontWeight.w700, letterSpacing: -0.3
AppTypography.displaySmall  // 20sp, FontWeight.w600, letterSpacing: -0.2

// Inter Body & UI
AppTypography.bodyLarge     // 16sp, FontWeight.w400, height: 1.5
AppTypography.bodyMedium    // 14sp, FontWeight.w400, height: 1.4
AppTypography.bodySmall     // 12sp, FontWeight.w400, height: 1.3
AppTypography.labelLarge    // 14sp, FontWeight.w600 (Buttons / Chips)
AppTypography.labelSmall    // 10sp, FontWeight.w700, uppercase (Badges / Eyebrows)
```

---

## 3. Standard Component Inventory

Always import design system components from `package:freebay/core/components/` or `package:freebay_design_system/components/`.

### 3.1 `AppButton`
Signature button with primary gradient (`#660062` -> `#8A1083`) or flat brutalist outline.
```dart
AppButton(
  text: 'CONFIRMAR ENTREGA',
  onPressed: () => confirmDelivery(),
  isLoading: isProcessing,
  variant: AppButtonVariant.primary, // primary, secondary, outline, danger
)
```

### 3.2 `BrutalistBox`
Rectangular card container utilizing tonal surface background without border radius or drop shadows.
```dart
BrutalistBox(
  color: context.colors.surfaceContainerLow,
  padding: const EdgeInsets.all(16),
  child: Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text('Detalhes do Pedido', style: AppTypography.displaySmall),
      const SizedBox(height: 8),
      Text('Status: Escrow Retido', style: AppTypography.bodyMedium),
    ],
  ),
)
```

### 3.3 `AppTextField`
High-contrast rectangular input with sharp borders and explicit focus state.
```dart
AppTextField(
  controller: _textController,
  label: 'PREÇO (R$)',
  hintText: '0,00',
  keyboardType: TextInputType.number,
  prefixIcon: const Icon(Icons.attach_money),
)
```

### 3.4 `BrutalistFilterChip`
Categorical filter toggle chip with sharp corners and distinct active/inactive surface fills.

### 3.5 `BrutalistDialog` & `BrutalistBottomSheet`
Modal dialogs and bottom sheets with zero radius and hard tonal backdrop.

### 3.6 `ShimmerSkeleton`
Sharp-edged skeleton placeholder using linear gradient animation for loading states.

---

## 4. Layout & Spacing Rules

- **Grid Unit**: 8px grid system (`4px`, `8px`, `16px`, `24px`, `32px`, `48px`).
- **Screen Margins**: Default horizontal padding is `16px`.
- **Card Spacing**: Separation between vertical list items is `12px` or `16px`.
- **Tonal Contrast**: Place child content on `surfaceContainerLow` (#F3F3F3) when the root background is `surface` (#F9F9F9).

---
