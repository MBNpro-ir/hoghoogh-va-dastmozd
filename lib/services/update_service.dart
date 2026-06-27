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

class AppUpdateRelease {
  final AppVersion version;
  final String tag;
  final String name;
  final String body;
  final Uri pageUrl;
  final GithubReleaseAsset asset;

  const AppUpdateRelease({
    required this.version,
    required this.tag,
    required this.name,
    required this.body,
    required this.pageUrl,
    required this.asset,
  });
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
  final String filePath;

  const DownloadedUpdate({required this.release, required this.filePath});
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
  static const _releasesUrl = 'https://api.github.com/repos/$_repo/releases';
  static const _autoCheckKey = 'hvm_update_auto_check_v1';
  static const _autoDownloadKey = 'hvm_update_auto_download_v1';
  static const _pendingInstalledVersionKey =
      'hvm_update_pending_installed_version_v1';

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
    if (decoded is! List) return null;
    final candidates = <AppUpdateRelease>[];
    for (final item in decoded.whereType<Map>()) {
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
            item['html_url']?.toString() ??
                'https://github.com/$_repo/releases/tag/$tag',
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
    final dir = Directory(
      p.join((await getTemporaryDirectory()).path, 'hvm_updates'),
    );
    if (!await dir.exists()) await dir.create(recursive: true);
    final filePath = p.join(dir.path, release.asset.name);
    final file = File(filePath);
    final request = http.Request('GET', release.asset.downloadUrl)
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
    await _markInstallStarted(update.release.version.toString());
    if (Platform.isWindows) {
      await _installWindowsPortable(update);
      exit(0);
    }
    if (Platform.isAndroid) {
      await OpenFilex.open(
        update.filePath,
        type: 'application/vnd.android.package-archive',
      );
      return;
    }
    await OpenFilex.open(update.filePath);
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
      builder: (context) => AlertDialog(
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
    );
    if (shouldDownload != true || !context.mounted) return;
    final downloaded = await download(available);
    if (context.mounted) await _showInstallDialog(context, downloaded);
  }

  Future<void> showInstalledMessageIfNeeded(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    final version = prefs.getString(_pendingInstalledVersionKey);
    if (version == null || version.isEmpty) return;
    await prefs.remove(_pendingInstalledVersionKey);
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
    if (rawAssets is! List) return null;
    final assets = rawAssets
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
    bool apkUniversal(GithubReleaseAsset asset) =>
        asset.name.endsWith('.apk') && asset.name.contains('universal');
    bool apk(GithubReleaseAsset asset) => asset.name.endsWith('.apk');
    bool windowsZip(GithubReleaseAsset asset) =>
        asset.name.endsWith('.zip') && asset.name.contains('windows');
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

  Future<void> _showInstallDialog(
    BuildContext context,
    DownloadedUpdate downloaded,
  ) async {
    final version = PersianNumberFormatter.toPersian(
      downloaded.release.version.toString(),
    );
    final install = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
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
    );
    if (install == true) await installUpdate(downloaded);
  }

  Future<void> installUpdate(DownloadedUpdate downloaded) =>
      install(downloaded);

  Future<void> _installWindowsPortable(DownloadedUpdate update) async {
    final exePath = Platform.resolvedExecutable;
    final appDir = p.dirname(exePath);
    final script = File(
      p.join(
        (await getTemporaryDirectory()).path,
        'hvm_update_${DateTime.now().millisecondsSinceEpoch}.ps1',
      ),
    );
    await script.writeAsString(r'''
param(
  [int]$AppPid,
  [string]$ZipPath,
  [string]$AppDir,
  [string]$ExePath
)
$ErrorActionPreference = "Stop"
Wait-Process -Id $AppPid -ErrorAction SilentlyContinue
$ExtractDir = Join-Path $env:TEMP ("hvm-update-" + [guid]::NewGuid().ToString())
New-Item -ItemType Directory -Path $ExtractDir -Force | Out-Null
Expand-Archive -LiteralPath $ZipPath -DestinationPath $ExtractDir -Force
$Bundle = Get-ChildItem -Path $ExtractDir -Directory -Recurse |
  Where-Object { Test-Path (Join-Path $_.FullName "payroll_app.exe") } |
  Select-Object -First 1
if (-not $Bundle) { throw "Update bundle was not found." }
Get-ChildItem -LiteralPath $Bundle.FullName |
  Copy-Item -Destination $AppDir -Recurse -Force
Start-Process -FilePath $ExePath -WorkingDirectory $AppDir
''');
    await Process.start('powershell', [
      '-NoProfile',
      '-ExecutionPolicy',
      'Bypass',
      '-File',
      script.path,
      pid.toString(),
      update.filePath,
      appDir,
      exePath,
    ], mode: ProcessStartMode.detached);
  }

  Future<void> _markInstallStarted(String version) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_pendingInstalledVersionKey, version);
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

class UpdateException implements Exception {
  final String message;
  const UpdateException(this.message);

  @override
  String toString() => message;
}
