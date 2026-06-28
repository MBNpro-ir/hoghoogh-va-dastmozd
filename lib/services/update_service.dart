import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:open_filex/open_filex.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../utils/persian_number_formatter.dart';

class UpdatePreferences {
  final bool autoCheck;
  final bool autoDownload;

  const UpdatePreferences({this.autoCheck = true, this.autoDownload = true});

  UpdatePreferences copyWith({bool? autoCheck, bool? autoDownload}) {
    return UpdatePreferences(
      autoCheck: autoCheck ?? this.autoCheck,
      autoDownload: autoDownload ?? this.autoDownload,
    );
  }
}

enum AppUpdateInstaller { githubAsset, velopack }

class AppUpdateRelease {
  final AppVersion version;
  final String tag;
  final String name;
  final String body;
  final Uri pageUrl;
  final GithubReleaseAsset? asset;
  final AppUpdateInstaller installer;

  const AppUpdateRelease({
    required this.version,
    required this.tag,
    required this.name,
    required this.body,
    required this.pageUrl,
    this.asset,
    this.installer = AppUpdateInstaller.githubAsset,
  }) : assert(installer == AppUpdateInstaller.velopack || asset != null);

  bool get usesVelopack => installer == AppUpdateInstaller.velopack;
}

class GithubReleaseAsset {
  final String name;
  final Uri downloadUrl;
  final int size;

  const GithubReleaseAsset({
    required this.name,
    required this.downloadUrl,
    required this.size,
  });
}

class DownloadedUpdate {
  final AppUpdateRelease release;
  final String? filePath;

  const DownloadedUpdate({required this.release, this.filePath});
}

class AppVersion implements Comparable<AppVersion> {
  final int major;
  final int minor;
  final int patch;
  final String preRelease;

  const AppVersion({
    required this.major,
    required this.minor,
    required this.patch,
    this.preRelease = '',
  });

  factory AppVersion.parse(String raw) {
    final clean = raw.trim().replaceFirst(RegExp(r'^v'), '').split('+').first;
    final parts = clean.split('-');
    final numbers = parts.first.split('.');
    int read(int index) =>
        index < numbers.length ? int.tryParse(numbers[index]) ?? 0 : 0;
    return AppVersion(
      major: read(0),
      minor: read(1),
      patch: read(2),
      preRelease: parts.length > 1 ? parts.sublist(1).join('-') : '',
    );
  }

  bool get isPreRelease => preRelease.trim().isNotEmpty;

  @override
  int compareTo(AppVersion other) {
    final numeric = [
      major - other.major,
      minor - other.minor,
      patch - other.patch,
    ].firstWhere((value) => value != 0, orElse: () => 0);
    if (numeric != 0) return numeric.sign;
    if (preRelease == other.preRelease) return 0;
    if (preRelease.isEmpty) return 1;
    if (other.preRelease.isEmpty) return -1;
    return preRelease.compareTo(other.preRelease).sign;
  }

  @override
  String toString() {
    final base = '$major.$minor.$patch';
    return preRelease.isEmpty ? base : '$base-$preRelease';
  }
}

class UpdateService {
  static const _repo = 'MBNpro-ir/hoghoogh-va-dastmozd';
  static const _repoUrl = 'https://github.com/$_repo';
  static const _releasesUrl = 'https://api.github.com/repos/$_repo/releases';
  static const _windowsVelopackChannel = 'win';
  static const _windowsVelopackHelperExe = 'hvm_updater.exe';
  static const _autoCheckKey = 'hvm_update_auto_check_v1';
  static const _autoDownloadKey = 'hvm_update_auto_download_v1';
  static const _pendingInstalledVersionKey =
      'hvm_update_pending_installed_version_v1';
  static const _pendingInstallMarkerPathKey =
      'hvm_update_pending_install_marker_path_v1';
  static const _velopackHookCommands = {
    '--veloapp-install',
    '--veloapp-updated',
    '--veloapp-obsolete',
    '--veloapp-uninstall',
  };

  static Future<void> initializeWindowsVelopackHooks(List<String> args) async {
    if (!Platform.isWindows) return;
    if (args.any(_velopackHookCommands.contains)) exit(0);
  }

  Future<UpdatePreferences> loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    return UpdatePreferences(
      autoCheck: prefs.getBool(_autoCheckKey) ?? true,
      autoDownload: prefs.getBool(_autoDownloadKey) ?? true,
    );
  }

  Future<UpdatePreferences> savePreferences(
    UpdatePreferences preferences,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_autoCheckKey, preferences.autoCheck);
    await prefs.setBool(_autoDownloadKey, preferences.autoDownload);
    return preferences;
  }

  Future<AppUpdateRelease?> checkLatest() async {
    final current = await _currentVersion();
    final releases = await _loadGithubReleases();
    if (Platform.isWindows) {
      final velopackRelease = await _selectWindowsVelopackRelease(
        releases,
        current,
      );
      if (velopackRelease != null) return velopackRelease;
    }
    return _selectGithubAssetRelease(releases, current);
  }

  Future<List<Map>> _loadGithubReleases() async {
    final response = await http
        .get(
          Uri.parse(_releasesUrl),
          headers: const {
            'accept': 'application/vnd.github+json',
            'user-agent': 'HvM updater',
          },
        )
        .timeout(const Duration(seconds: 20));
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw UpdateException('خطا در بررسی آپدیت از GitHub');
    }
    final decoded = jsonDecode(response.body);
    if (decoded is! List) return const [];
    return decoded.whereType<Map>().toList();
  }

  Future<AppUpdateRelease?> _selectWindowsVelopackRelease(
    List<Map> releases,
    AppVersion current,
  ) async {
    if (!_isWindowsVelopackManaged()) return null;
    final candidates = <AppUpdateRelease>[];
    for (final item in releases) {
      if (item['draft'] == true) continue;
      final tag = item['tag_name']?.toString() ?? '';
      if (tag.isEmpty) continue;
      final version = AppVersion.parse(tag);
      if (version.compareTo(current) <= 0) continue;
      final assets = _releaseAssets(item['assets']);
      if (!_hasWindowsVelopackAssets(assets)) continue;
      candidates.add(
        AppUpdateRelease(
          version: version,
          tag: tag,
          name: item['name']?.toString() ?? tag,
          body: item['body']?.toString() ?? '',
          pageUrl: Uri.parse(
            item['html_url']?.toString() ?? '$_repoUrl/releases/tag/$tag',
          ),
          installer: AppUpdateInstaller.velopack,
        ),
      );
    }
    if (candidates.isEmpty) return null;
    candidates.sort((a, b) => b.version.compareTo(a.version));
    return candidates.first;
  }

  AppUpdateRelease? _selectGithubAssetRelease(
    List<Map> releases,
    AppVersion current,
  ) {
    final candidates = <AppUpdateRelease>[];
    for (final item in releases) {
      if (item['draft'] == true) continue;
      final tag = item['tag_name']?.toString() ?? '';
      if (tag.isEmpty) continue;
      final version = AppVersion.parse(tag);
      if (version.compareTo(current) <= 0) continue;
      final asset = _selectAsset(item['assets']);
      if (asset == null) continue;
      candidates.add(
        AppUpdateRelease(
          version: version,
          tag: tag,
          name: item['name']?.toString() ?? tag,
          body: item['body']?.toString() ?? '',
          pageUrl: Uri.parse(
            item['html_url']?.toString() ?? '$_repoUrl/releases/tag/$tag',
          ),
          asset: asset,
        ),
      );
    }
    if (candidates.isEmpty) return null;
    candidates.sort((a, b) => b.version.compareTo(a.version));
    return candidates.first;
  }

  Future<DownloadedUpdate> download(AppUpdateRelease release) async {
    if (release.usesVelopack) {
      return DownloadedUpdate(release: release);
    }
    final asset = release.asset;
    if (asset == null) {
      throw const UpdateException('فایل آپدیت پیدا نشد');
    }
    final dir = Directory(
      p.join((await getTemporaryDirectory()).path, 'hvm_updates'),
    );
    if (!await dir.exists()) await dir.create(recursive: true);
    final filePath = p.join(dir.path, asset.name);
    final file = File(filePath);
    final request = http.Request('GET', asset.downloadUrl)
      ..headers['user-agent'] = 'HvM updater';
    final response = await http.Client()
        .send(request)
        .timeout(const Duration(seconds: 30));
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw UpdateException('دانلود آپدیت انجام نشد');
    }
    final sink = file.openWrite();
    await response.stream.pipe(sink);
    await sink.close();
    return DownloadedUpdate(release: release, filePath: filePath);
  }

  Future<void> install(DownloadedUpdate update) async {
    if (Platform.isWindows) {
      if (update.release.usesVelopack) {
        await _installWindowsVelopack(update.release);
        return;
      }
      final markerPath = await _markWindowsInstallPending(
        update.release.version.toString(),
      );
      await _installWindowsPortable(update, markerPath: markerPath);
      await Future<void>.delayed(const Duration(milliseconds: 250));
      exit(0);
    }
    if (Platform.isAndroid) {
      await _markInstallStarted(update.release.version.toString());
      final filePath = update.filePath;
      if (filePath == null) {
        throw const UpdateException('فایل آپدیت پیدا نشد');
      }
      await OpenFilex.open(
        filePath,
        type: 'application/vnd.android.package-archive',
      );
      return;
    }
    final filePath = update.filePath;
    if (filePath == null) {
      throw const UpdateException('فایل آپدیت پیدا نشد');
    }
    await OpenFilex.open(filePath);
  }

  Future<void> checkAndPrompt(
    BuildContext context, {
    bool automatic = false,
  }) async {
    final preferences = await loadPreferences();
    if (automatic && !preferences.autoCheck) return;
    AppUpdateRelease? release;
    try {
      release = await checkLatest();
    } catch (e) {
      if (!automatic && context.mounted) {
        _snack(context, e.toString().replaceAll('Exception: ', ''));
      }
      return;
    }
    if (!context.mounted) return;
    if (release == null) {
      if (!automatic) _snack(context, 'برنامه به‌روز است');
      return;
    }
    final available = release;
    if (preferences.autoDownload) {
      _snack(
        context,
        'در حال دانلود نسخه ${PersianNumberFormatter.toPersian(available.version.toString())}',
      );
      try {
        final downloaded = await download(available);
        if (!context.mounted) return;
        await _showInstallDialog(context, downloaded);
      } catch (e) {
        if (context.mounted) {
          _snack(context, e.toString().replaceAll('Exception: ', ''));
        }
      }
      return;
    }
    final shouldDownload = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => PopScope(
        canPop: false,
        child: AlertDialog(
          title: Text(
            'آپدیت ${PersianNumberFormatter.toPersian(available.version.toString())}',
          ),
          content: Text(
            'نسخه جدید آماده دانلود است.\n${_trimBody(available.body)}',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('بعدا'),
            ),
            FilledButton.icon(
              onPressed: () => Navigator.pop(context, true),
              icon: const Icon(Icons.download_rounded),
              label: const Text('دانلود'),
            ),
          ],
        ),
      ),
    );
    if (shouldDownload != true || !context.mounted) return;
    final downloaded = await download(available);
    if (context.mounted) await _showInstallDialog(context, downloaded);
  }

  Future<void> showInstalledMessageIfNeeded(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    final version = prefs.getString(_pendingInstalledVersionKey);
    if (version == null || version.isEmpty) return;
    final installed = await _currentVersion();
    if (installed.compareTo(AppVersion.parse(version)) < 0) {
      await prefs.remove(_pendingInstalledVersionKey);
      await prefs.remove(_pendingInstallMarkerPathKey);
      return;
    }
    final markerPath = prefs.getString(_pendingInstallMarkerPathKey);
    if (Platform.isWindows && markerPath != null && markerPath.isNotEmpty) {
      final marker = File(markerPath);
      if (!await marker.exists()) {
        await prefs.remove(_pendingInstalledVersionKey);
        await prefs.remove(_pendingInstallMarkerPathKey);
        return;
      }
      try {
        await marker.delete();
      } catch (_) {}
    }
    await prefs.remove(_pendingInstalledVersionKey);
    await prefs.remove(_pendingInstallMarkerPathKey);
    if (!context.mounted) return;
    _snack(
      context,
      'برنامه به نسخه ${PersianNumberFormatter.toPersian(version)} آپدیت شد',
    );
  }

  Future<AppVersion> _currentVersion() async {
    final info = await PackageInfo.fromPlatform();
    return AppVersion.parse(info.version);
  }

  GithubReleaseAsset? _selectAsset(Object? rawAssets) {
    final assets = _releaseAssets(rawAssets);
    bool apkUniversal(GithubReleaseAsset asset) =>
        asset.name.endsWith('.apk') && asset.name.contains('universal');
    bool apk(GithubReleaseAsset asset) => asset.name.endsWith('.apk');
    bool windowsZip(GithubReleaseAsset asset) =>
        asset.name.endsWith('.zip') &&
        asset.name.startsWith('payroll-app-') &&
        asset.name.contains('windows-x64-portable');
    if (Platform.isAndroid) {
      return assets.where(apkUniversal).firstOrNull ??
          assets.where(apk).firstOrNull;
    }
    if (Platform.isWindows) {
      return assets.where(windowsZip).firstOrNull ??
          assets.where((asset) => asset.name.endsWith('.zip')).firstOrNull;
    }
    return null;
  }

  List<GithubReleaseAsset> _releaseAssets(Object? rawAssets) {
    if (rawAssets is! List) return const [];
    return rawAssets
        .whereType<Map>()
        .map((item) {
          final name = item['name']?.toString() ?? '';
          final url = item['browser_download_url']?.toString() ?? '';
          if (name.isEmpty || url.isEmpty) return null;
          return GithubReleaseAsset(
            name: name,
            downloadUrl: Uri.parse(url),
            size: item['size'] is num ? (item['size'] as num).toInt() : 0,
          );
        })
        .whereType<GithubReleaseAsset>()
        .toList();
  }

  bool _hasWindowsVelopackAssets(List<GithubReleaseAsset> assets) {
    final names = assets.map((asset) => asset.name.toLowerCase()).toList();
    final hasReleaseFeed = names.any(
      (name) => name == 'releases.win.json' || name == 'releases',
    );
    final hasPackage = names.any((name) => name.endsWith('.nupkg'));
    return hasReleaseFeed && hasPackage;
  }

  Future<void> _showInstallDialog(
    BuildContext context,
    DownloadedUpdate downloaded,
  ) async {
    final version = PersianNumberFormatter.toPersian(
      downloaded.release.version.toString(),
    );
    final install = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => PopScope(
        canPop: false,
        child: AlertDialog(
          title: Text('نصب نسخه $version'),
          content: Text(
            Platform.isWindows
                ? 'آپدیت دانلود شد. با تایید شما برنامه بسته می‌شود، فایل‌های نسخه جدید جایگزین می‌شوند و برنامه دوباره اجرا می‌شود.'
                : 'آپدیت دانلود شد. با تایید شما نصب‌کننده اندروید باز می‌شود.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('بعدا'),
            ),
            FilledButton.icon(
              onPressed: () => Navigator.pop(context, true),
              icon: const Icon(Icons.system_update_alt_rounded),
              label: const Text('نصب'),
            ),
          ],
        ),
      ),
    );
    if (install == true) {
      if (Platform.isWindows && context.mounted) {
        _showWindowsInstallingDialog(context, version);
        await Future<void>.delayed(const Duration(milliseconds: 900));
      }
      await installUpdate(downloaded);
    }
  }

  Future<void> installUpdate(DownloadedUpdate downloaded) =>
      install(downloaded);

  Future<void> _installWindowsVelopack(AppUpdateRelease release) async {
    final helper = _findWindowsVelopackHelper();
    if (helper == null) {
      throw const UpdateException('نصب خودکار ویندوز آماده نیست');
    }
    final sourceUrl = buildGithubReleaseDownloadBaseUrl(_repo, release.tag);
    await _markInstallStarted(release.version.toString());
    await Process.start(
      helper.path,
      [
        'apply',
        '--source',
        sourceUrl,
        '--channel',
        _windowsVelopackChannel,
        '--wait-pid',
        pid.toString(),
        '--restart',
        '--silent',
      ],
      workingDirectory: helper.parent.path,
      mode: ProcessStartMode.detached,
    );
    await Future<void>.delayed(const Duration(milliseconds: 250));
    exit(0);
  }

  bool _isWindowsVelopackManaged() =>
      Platform.isWindows &&
      _findWindowsVelopackHelper() != null &&
      _findWindowsVelopackUpdateExe() != null;

  File? _findWindowsVelopackHelper() =>
      _firstExistingWindowsFile(_windowsVelopackHelperExe);

  File? _findWindowsVelopackUpdateExe() =>
      _firstExistingWindowsFile('Update.exe');

  File? _firstExistingWindowsFile(String fileName) {
    if (!Platform.isWindows) return null;
    final appDir = p.dirname(Platform.resolvedExecutable);
    final parentDir = p.dirname(appDir);
    final candidates = [
      p.join(appDir, fileName),
      p.join(appDir, 'updater', fileName),
      p.join(parentDir, fileName),
      p.join(parentDir, 'updater', fileName),
    ];
    for (final candidate in candidates) {
      final file = File(candidate);
      if (file.existsSync()) return file;
    }
    return null;
  }

  Future<void> _installWindowsPortable(
    DownloadedUpdate update, {
    required String markerPath,
  }) async {
    final filePath = update.filePath;
    if (filePath == null) {
      throw const UpdateException('فایل آپدیت پیدا نشد');
    }
    final exePath = Platform.resolvedExecutable;
    final appDir = p.dirname(exePath);
    final script = File(
      p.join(
        (await getTemporaryDirectory()).path,
        'hvm_update_${DateTime.now().millisecondsSinceEpoch}.ps1',
      ),
    );
    await script.writeAsString(buildWindowsPortableUpdaterScript());
    await Process.start('powershell', [
      '-NoProfile',
      '-ExecutionPolicy',
      'Bypass',
      '-File',
      script.path,
      pid.toString(),
      filePath,
      appDir,
      exePath,
      markerPath,
    ], mode: ProcessStartMode.detached);
  }

  void _showWindowsInstallingDialog(BuildContext context, String version) {
    unawaited(
      showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (context) => PopScope(
          canPop: false,
          child: AlertDialog(
            title: Text('در حال نصب نسخه $version'),
            content: const Row(
              children: [
                SizedBox.square(
                  dimension: 24,
                  child: CircularProgressIndicator(strokeWidth: 3),
                ),
                SizedBox(width: 14),
                Expanded(
                  child: Text(
                    'برنامه در حال آماده‌سازی نصب است. پنجره بسته می‌شود، فایل‌ها جایگزین می‌شوند و برنامه به صورت خودکار اجرا می‌شود.',
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _markInstallStarted(String version) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_pendingInstalledVersionKey, version);
  }

  Future<String> _markWindowsInstallPending(String version) async {
    final dir = await getTemporaryDirectory();
    final markerPath = p.join(
      dir.path,
      'hvm-update-installed-$version-${DateTime.now().millisecondsSinceEpoch}.marker',
    );
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_pendingInstalledVersionKey, version);
    await prefs.setString(_pendingInstallMarkerPathKey, markerPath);
    return markerPath;
  }

  void _snack(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(PersianNumberFormatter.toPersian(message))),
    );
  }

  String _trimBody(String body) {
    final clean = body.trim();
    if (clean.isEmpty) {
      return 'فهرست تغییرات در صفحه Release گیت‌هاب ثبت شده است.';
    }
    return clean.length > 600 ? '${clean.substring(0, 600)}...' : clean;
  }
}

String buildWindowsPortableUpdaterScript() => r'''
param(
  [int]$AppPid,
  [string]$ZipPath,
  [string]$AppDir,
  [string]$ExePath,
  [string]$MarkerPath
)
$ErrorActionPreference = "Stop"
$ProgressPreference = "SilentlyContinue"
$LogPath = Join-Path $env:TEMP ("hvm-update-" + $AppPid + ".log")

function Write-UpdateLog([string]$Message) {
  $Stamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
  Add-Content -LiteralPath $LogPath -Value ("[$Stamp] " + $Message)
}

function Test-FileUnlocked([string]$Path) {
  if (-not (Test-Path -LiteralPath $Path)) { return $true }
  try {
    $Stream = [System.IO.File]::Open(
      $Path,
      [System.IO.FileMode]::Open,
      [System.IO.FileAccess]::ReadWrite,
      [System.IO.FileShare]::None
    )
    $Stream.Close()
    return $true
  } catch {
    return $false
  }
}

function Wait-ExecutableUnlocked([string]$Path) {
  for ($Index = 0; $Index -lt 80; $Index++) {
    if (Test-FileUnlocked $Path) { return }
    Start-Sleep -Milliseconds 250
  }
  throw "Application executable is still locked: $Path"
}

function Copy-WithRetry([string]$Source, [string]$Destination) {
  for ($Index = 0; $Index -lt 50; $Index++) {
    try {
      Copy-Item -LiteralPath $Source -Destination $Destination -Recurse -Force
      return
    } catch {
      if ($Index -eq 49) { throw }
      Start-Sleep -Milliseconds 300
    }
  }
}

try {
  Write-UpdateLog "Updater started."
  Wait-Process -Id $AppPid -ErrorAction SilentlyContinue
  Start-Sleep -Milliseconds 700
  Wait-ExecutableUnlocked $ExePath

  if (-not (Test-Path -LiteralPath $ZipPath)) {
    throw "Update zip was not found: $ZipPath"
  }
  if (-not (Test-Path -LiteralPath $AppDir)) {
    throw "Application directory was not found: $AppDir"
  }

  $ExtractDir = Join-Path $env:TEMP ("hvm-update-" + [guid]::NewGuid().ToString())
  New-Item -ItemType Directory -Path $ExtractDir -Force | Out-Null
  Write-UpdateLog "Extracting $ZipPath to $ExtractDir"
  Expand-Archive -LiteralPath $ZipPath -DestinationPath $ExtractDir -Force

  $RootExe = Join-Path $ExtractDir "payroll_app.exe"
  if (Test-Path -LiteralPath $RootExe) {
    $BundlePath = $ExtractDir
  } else {
    $Bundle = Get-ChildItem -LiteralPath $ExtractDir -Directory -Recurse |
      Where-Object { Test-Path -LiteralPath (Join-Path $_.FullName "payroll_app.exe") } |
      Select-Object -First 1
    if (-not $Bundle) { throw "Update bundle was not found inside extracted zip." }
    $BundlePath = $Bundle.FullName
  }

  Write-UpdateLog "Copying files from $BundlePath to $AppDir"
  Get-ChildItem -LiteralPath $BundlePath -Force |
    ForEach-Object {
      Copy-WithRetry $_.FullName $AppDir
    }

  $LaunchPath = Join-Path $AppDir (Split-Path -Path $ExePath -Leaf)
  if (-not (Test-Path -LiteralPath $LaunchPath)) {
    $LaunchPath = Join-Path $AppDir "payroll_app.exe"
  }
  if (-not (Test-Path -LiteralPath $LaunchPath)) {
    throw "Updated executable was not found: $LaunchPath"
  }

  if ($MarkerPath -and $MarkerPath.Trim().Length -gt 0) {
    Set-Content -LiteralPath $MarkerPath -Value ("installed " + (Get-Date -Format "o")) -Force
  }
  Write-UpdateLog "Launching $LaunchPath"
  Start-Process -FilePath $LaunchPath -WorkingDirectory $AppDir
  Remove-Item -LiteralPath $ExtractDir -Recurse -Force -ErrorAction SilentlyContinue
  Write-UpdateLog "Updater finished."
} catch {
  Write-UpdateLog ("ERROR: " + $_.Exception.Message)
  try {
    Add-Type -AssemblyName PresentationFramework
    [System.Windows.MessageBox]::Show(
      "HvM update failed. Please check this log:`n$LogPath",
      "HvM Updater"
    ) | Out-Null
  } catch {}
}
''';

String buildGithubReleaseDownloadBaseUrl(String repo, String tag) =>
    'https://github.com/$repo/releases/download/$tag/';

class UpdateException implements Exception {
  final String message;
  const UpdateException(this.message);

  @override
  String toString() => message;
}
