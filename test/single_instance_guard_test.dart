import 'dart:async';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:payroll_app/services/single_instance_guard.dart';

void main() {
  test(
    'single instance guard activates the primary instance when notified',
    () async {
      final temp = await Directory.systemTemp.createTemp(
        'hvm_single_instance_test_',
      );
      addTearDown(() => temp.delete(recursive: true));

      final port = await _freePort();
      final activated = Completer<void>();
      final guard = await SingleInstanceGuard.acquire(
        lockPath: '${temp.path}${Platform.pathSeparator}guard.lock',
        port: port,
        onActivate: () async {
          if (!activated.isCompleted) activated.complete();
        },
      );
      addTearDown(guard.dispose);

      expect(guard.isPrimary, isTrue);
      await SingleInstanceGuard.notifyExistingInstance(port: port);
      await activated.future.timeout(const Duration(seconds: 2));
    },
  );
}

Future<int> _freePort() async {
  final socket = await ServerSocket.bind(InternetAddress.loopbackIPv4, 0);
  final port = socket.port;
  await socket.close();
  return port;
}
