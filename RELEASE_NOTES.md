**1405/04/06 | 2026-06-27**

## Windows Tables
- Rebuilt the shared desktop table view with a sticky header row.
- Kept the right-side identity columns pinned while scrolling horizontally: row number, employee code, and employee name.
- Made vertical and horizontal scrollbars permanently visible on desktop tables.
- Synchronized frozen and scrollable table bodies so vertical scrolling stays aligned.

## Employee Columns
- Split combined employee labels into separate code and employee-name columns in advances, loans, and leave tables.
- Updated the employees table to start with row number, employee code, and employee name for the same frozen-column layout used by salary records.

## Quality
- Added a widget regression test for the desktop responsive table shell.
- Updated the app version to `0.9.1`.
- Release workflow continues to run from `master` and publish this version as a pre-release.
