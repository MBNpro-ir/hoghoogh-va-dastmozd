import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:path/path.dart' as p;

import '../database/database_helper.dart';

class BackupService {
  final _db = DatabaseHelper.instance;

  Future<String?> backupDatabase() async {
    final sourcePath = await _db.databasePath;
    final source = File(sourcePath);
    if (!await source.exists()) {
      throw StateError('فایل دیتابیس پیدا نشد');
    }

    final now = DateTime.now();
    final fileName =
        'payroll-backup-${now.year}${_two(now.month)}${_two(now.day)}-${_two(now.hour)}${_two(now.minute)}.db';
    await _db.close();
    final bytes = await source.readAsBytes();
    final targetPath = await FilePicker.platform.saveFile(
      dialogTitle: 'ذخیره بکاپ حقوق و دستمزد',
      fileName: fileName,
      type: FileType.custom,
      allowedExtensions: ['db'],
      bytes: bytes,
    );
    await _db.database;
    if (targetPath == null) return null;

    return targetPath;
  }

  Future<String?> restoreDatabase() async {
    final picked = await FilePicker.platform.pickFiles(
      dialogTitle: 'انتخاب فایل بکاپ',
      type: FileType.custom,
      allowedExtensions: ['db'],
      allowMultiple: false,
    );
    final pickedPath = picked?.files.single.path;
    if (pickedPath == null) return null;

    final targetPath = await _db.databasePath;
    final targetDir = Directory(p.dirname(targetPath));
    if (!await targetDir.exists()) {
      await targetDir.create(recursive: true);
    }

    await _db.close();
    await File(pickedPath).copy(targetPath);
    await _db.database;
    return pickedPath;
  }

  Future<String?> saveServerBackup(String backupFile) async {
    final now = DateTime.now();
    final fileName =
        'payroll-server-backup-${now.year}${_two(now.month)}${_two(now.day)}-${_two(now.hour)}${_two(now.minute)}.hvm.sql';
    return FilePicker.platform.saveFile(
      dialogTitle: 'ذخیره بکاپ سرور',
      fileName: fileName,
      type: FileType.custom,
      allowedExtensions: ['sql'],
      bytes: utf8.encode(backupFile),
    );
  }

  Future<String?> pickServerBackupFile() async {
    final picked = await FilePicker.platform.pickFiles(
      dialogTitle: 'انتخاب فایل بکاپ سرور',
      type: FileType.custom,
      allowedExtensions: ['sql'],
      allowMultiple: false,
      withData: true,
    );
    final file = picked?.files.single;
    if (file == null) return null;
    final bytes = file.bytes;
    if (bytes != null) return utf8.decode(bytes);
    final path = file.path;
    if (path == null) return null;
    return File(path).readAsString();
  }

  static String _two(int value) => value.toString().padLeft(2, '0');
}
