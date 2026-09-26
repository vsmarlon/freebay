# Cupertino UI Migration Plan

## Overview
This document outlines the migration plan to adopt Cupertino (iOS) style widgets across the FreeBay application while maintaining our strict Digital Brutalist design constraints (0px radius, no blur shadows, tonal layering).

## Widget Inventory & Migration Strategy

### 1. Switches
- **Current State:** Material `Switch`
- **Target State:** `CupertinoSwitch` wrapped in `BrutalistSwitch`
- **Design:** Override thumb and track colors with `AppColors`.
- **Files to check:** Settings pages, preferences, filters.

### 2. Dialogs
- **Current State:** Material `AlertDialog`, `showDialog`
- **Target State:** `CupertinoAlertDialog` wrapped in `BrutalistCupertinoDialog` or `showBrutalistCupertinoDialog`
- **Design:** Digital Brutalist styling. Zero radius, hard borders. Action buttons styled with brutalist typography and colors.
- **Files to check:** `frontend/lib/core/components/app_dialog.dart`, destructive actions, confirmations.

### 3. Bottom Sheets / Action Sheets
- **Current State:** Material BottomSheet (`brutalist_bottom_sheet.dart`)
- **Target State:** `CupertinoActionSheet` wrapped in `BrutalistActionSheet`
- **Design:** Keep the `AppBackground` aurora integration. Use tonal layering, square corners, and hard borders for the sheet and its actions. No blurred shadows.

### 4. Sliders
- **Current State:** Material `Slider`
- **Target State:** `CupertinoSlider` wrapped in `BrutalistSlider`
- **Design:** Track and thumb use `context.borderColor` and `AppColors.primaryContainer`. No thumb shadow/glow.
- **Files to check:** Forms, settings.

### 5. Context Menus & Pickers
- **Current State:** Material Menus / Dropdowns
- **Target State:** `CupertinoContextMenu` or `CupertinoPicker`
- **Design:** Square borders, tonal steps, `AppTypography`.
- **Files to check:** Form dropdowns, date/time pickers.

### 6. Segmented Controls
- **Current State:** Material ToggleButtons / TabBars
- **Target State:** `CupertinoSlidingSegmentedControl` wrapped in `BrutalistSegmentedControl`
- **Design:** 0px radius, active state uses `AppColors.primaryContainer`, text uses `AppTypography.labelLarge`.

## Priority Order (Most Visible First)

1. **Switches & Segmented Controls:** Highly visible in forms and settings.
2. **Action Sheets & Context Menus:** Used frequently for post actions, profile menus.
3. **Dialogs:** Used for critical actions (deletions, confirmations).
4. **Pickers & Sliders:** Used in specific form inputs.

## Implementation Notes
- **Digital Brutalist Constraints:** We must ensure all Cupertino widgets respect `AppTheme` (0px radius, no blur shadows, use `AppDepth` and `AppTypography`).
- **Aurora Background:** Action sheets and dialogs should continue to support or overlay the aurora background properly without introducing flat opaque scaffolds where they shouldn't.
- **Real Wrappers:** We will create real wrappers in `frontend/libs/freebay_design_system/lib/components/` and export them.
