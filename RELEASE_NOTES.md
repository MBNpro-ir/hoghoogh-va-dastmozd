**1405/04/06 | 2026-06-27**

## Payment Section
- Added payslip viewing and printing directly from payment cards.
- Added payment status history so unpaid/paid changes remain visible with actor, date, and unpaid reason.
- Kept both paid and unpaid actions available so a later payment can update an earlier unpaid status.
- Added copy action for the net payable amount.
- Added configurable payment-card layout with automatic/manual columns and card sizing for desktop and mobile.

## Updates
- Added GitHub release update checks in settings.
- Added automatic update check on app launch.
- Added optional automatic download of update assets.
- Added Windows portable updater flow that closes the app, replaces files, and relaunches.
- Added Android APK download and install prompt flow.

## Backend Sync
- Added synced `change_log` storage for payment statuses.
- Added server validation and backup/restore support for payment history.

## Quality
- Updated the app, server, and admin package versions for `0.9.0-alpha`.
- Release workflow continues to run on `master` and publish this version as a pre-release.
