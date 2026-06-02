# Changelog

## 0.0.3-alpha+3 - 2026-06-02

### 🐛 Bug Fixes
- 🔧 Fixed swapped 1405 marriage and child allowance defaults in salary settings.
- 🧮 Aligned salary calculations with Excel formulas: benefits cap, insurance cap, two-sevenths tax exemption, progressive tax, shift work, hourly benefits, and rounding.

### ✨ New Features
- 📊 Added responsive, sortable tables with mobile card views for employees, payroll records, and loans.
- 📱 New `ResponsiveDataView` widget with `MobileDataCard` and `MobileMetric` components.
- ❓ Added Help & Support screen and wired the "View guide" action.
- 💾 Added database backup and restore actions in settings.
- ♿ Accessibility toggles now affect theme contrast, control sizing, spacing, and reduced motion.

### 🧪 Testing
- ✅ Added Excel parity test for payroll calculations (`salary_calculator_excel_test.dart`).
- 📁 Extracted Excel workbook into raw and semantic reference files for dev verification only.

### 🔨 Infrastructure & CI/CD
- 🚀 Updated release workflow to build both Windows and Android artifacts.
- 🔄 Added `quality`, `build_android`, `build_windows`, and `github_release` CI jobs.
- 📦 Added `CHANGELOG.md` for automated release notes.
- ⬆️ Updated `file_picker` to `8.3.7` and bumped version to `0.0.3-alpha+3`.

### 🎨 UI & Theme
- 📐 Reduced dashboard card height and removed the quick-start button.
- 🎨 Enhanced theme contrast and spacing for accessibility mode.
