**1405/04/06 | 2026-06-27**

## Windows Updater
- Fixed the Windows portable updater so it can install release ZIP files that contain app files directly at the archive root.
- Kept support for nested portable bundles as a fallback.
- Added a visible "installing" dialog before the app closes for update installation.
- Relaunch now targets the updated executable from the app directory after files are replaced.
- Added updater logging and a Windows error message if installation fails instead of silently closing the app.

## Quality
- Added regression tests for the Windows updater script and version comparison.
- Updated the app version to `0.9.2`.
- Release workflow continues to run from `master` and publish this version as a pre-release.
