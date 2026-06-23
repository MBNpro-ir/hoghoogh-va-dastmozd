import 'dart:async';
import 'dart:convert';
import 'dart:io';

class SingleInstanceGuard {
  static const activationMessage = 'hvm:activate-window';
  static const defaultPort = 62050;

  final RandomAccessFile? _lockFile;
  final ServerSocket? _server;
  final Future<void> Function()? _onActivate;

  const SingleInstanceGuard._secondary()
    : _lockFile = null,
      _server = null,
      _onActivate = null;

  SingleInstanceGuard._primary({
    required this._lockFile,
    required this._server,
    required this._onActivate,
  }) {
    _server?.listen((socket) => unawaited(_handleSocket(socket)));
  }

  bool get isPrimary => _lockFile != null;

  static Future<SingleInstanceGuard> acquire({
    int port = defaultPort,
    String? lockPath,
    Future<void> Function()? onActivate,
  }) async {
    final file = File(lockPath ?? _defaultLockPath());
    await file.parent.create(recursive: true);
    late final RandomAccessFile lockFile;
    try {
      lockFile = await file.open(mode: FileMode.write);
      await lockFile.lock(FileLock.exclusive);
    } catch (_) {
      await notifyExistingInstance(port: port);
      return const SingleInstanceGuard._secondary();
    }

    ServerSocket? server;
    try {
      server = await ServerSocket.bind(
        InternetAddress.loopbackIPv4,
        port,
        shared: false,
      );
    } catch (_) {
      server = null;
    }

    return SingleInstanceGuard._primary(
      lockFile: lockFile,
      server: server,
      onActivate: onActivate,
    );
  }

  static Future<void> notifyExistingInstance({int port = defaultPort}) async {
    try {
      final socket = await Socket.connect(
        InternetAddress.loopbackIPv4,
        port,
        timeout: const Duration(milliseconds: 400),
      );
      socket.write(activationMessage);
      await socket.flush();
      await socket.close();
    } catch (_) {}
  }

  Future<void> dispose() async {
    await _server?.close();
    await _lockFile?.unlock();
    await _lockFile?.close();
  }

  Future<void> _handleSocket(Socket socket) async {
    try {
      final message = await utf8.decoder
          .bind(socket)
          .join()
          .timeout(const Duration(seconds: 1));
      if (message.trim() == activationMessage) {
        await _onActivate?.call();
      }
    } catch (_) {
      // Activation is best-effort; the guard still prevents duplicate runs.
    } finally {
      socket.destroy();
    }
  }

  static String _defaultLockPath() {
    final root =
        Platform.environment['LOCALAPPDATA'] ?? Directory.systemTemp.path;
    return [
      root,
      'HvM',
      'payroll_app_single_instance.lock',
    ].join(Platform.pathSeparator);
  }
}
