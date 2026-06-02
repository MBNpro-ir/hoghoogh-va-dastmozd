# Changelog

## 0.0.4-alpha+4 - 2026-06-02

### 🐛 Bug Fixes
- 📱 Fixed employee form screen layout for mobile — fields no longer overflow or get clipped on narrow screens.
- 📱 Fixed salary records summary cards for mobile — cards now wrap into a grid instead of horizontal scroll.
- 📱 Fixed salary records filter row for mobile — stacked vertically for better usability.
- 📱 Fixed loan form installment fields for mobile — stacked vertically.
- 📱 Fixed salary calculation form fields (month/year, work days, overtime, deductions) for mobile.
- 🔄 Replaced hardcoded `Row` layouts with responsive `_responsiveRow()` that stacks on screens < 600px.

### ✨ New Features
- 📐 Added `_responsiveRow()` and `_responsiveField()` helpers for adaptive form layouts.
- 👶 Children counter widget redesigned for mobile with tighter spacing.

### 🔨 Infrastructure & CI/CD
- 🚀 Updated release workflow to build for multiple platforms: Windows x64, Android ARM64, Android x86_64, and Linux x64.
- 📦 Added Linux build job to CI pipeline.
- ⬆️ Bumped version to `0.0.4-alpha+4`.
