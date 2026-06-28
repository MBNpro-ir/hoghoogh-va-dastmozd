import 'package:flutter_test/flutter_test.dart';
import 'package:payroll_app/services/update_service.dart';

void main() {
  test('windows portable updater handles root and nested release bundles', () {
    final script = buildWindowsPortableUpdaterScript();

    expect(script, contains(r'Join-Path $ExtractDir "payroll_app.exe"'));
    expect(script, contains(r'$BundlePath = $ExtractDir'));
    expect(
      script,
      contains(r'Get-ChildItem -LiteralPath $ExtractDir -Directory -Recurse'),
    );
    expect(script, contains(r'[string]$MarkerPath'));
    expect(script, contains(r'Wait-ExecutableUnlocked $ExePath'));
    expect(script, contains(r'Copy-WithRetry $_.FullName $AppDir'));
    expect(script, contains(r'Set-Content -LiteralPath $MarkerPath'));
    expect(script, contains(r'Get-ChildItem -LiteralPath $BundlePath -Force'));
    expect(script, contains(r'Start-Process -FilePath $LaunchPath'));
  });

  test('version parser compares stable versions above alpha releases', () {
    final alpha = AppVersion.parse('v0.9.1-alpha+25');
    final stable = AppVersion.parse('0.9.1+26');

    expect(stable.compareTo(alpha), greaterThan(0));
  });

  test('builds GitHub release download base URL for Velopack feeds', () {
    expect(
      buildGithubReleaseDownloadBaseUrl(
        'MBNpro-ir/hoghoogh-va-dastmozd',
        'v0.9.10-alpha',
      ),
      'https://github.com/MBNpro-ir/hoghoogh-va-dastmozd/releases/download/v0.9.10-alpha/',
    );
  });
}
