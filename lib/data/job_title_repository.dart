import 'dart:async';
import 'dart:convert';

import 'package:flutter/services.dart';

import '../utils/persian_number_formatter.dart';

class JobTitleEntry {
  final String code;
  final String title;

  const JobTitleEntry({required this.code, required this.title});

  factory JobTitleEntry.fromJson(Map<String, dynamic> json) => JobTitleEntry(
    code: json['code'] as String? ?? '',
    title: json['title'] as String? ?? '',
  );
}

class JobTitleRepository {
  static List<JobTitleEntry>? _cache;

  static Future<List<JobTitleEntry>> load() async {
    final cached = _cache;
    if (cached != null) return cached;
    final raw = await rootBundle.loadString('assets/data/job_titles.json');
    final decoded = jsonDecode(raw) as List<dynamic>;
    final items = decoded
        .map((item) => JobTitleEntry.fromJson(item as Map<String, dynamic>))
        .where((item) => item.code.isNotEmpty && item.title.isNotEmpty)
        .toList(growable: false);
    _cache = items;
    return items;
  }

  static List<JobTitleEntry> search(
    List<JobTitleEntry> items,
    String query, {
    int limit = 80,
  }) {
    final normalizedQuery = _normalize(query);
    if (normalizedQuery.isEmpty) return items.take(limit).toList();

    final results = <JobTitleEntry>[];
    for (final item in items) {
      if (_normalize(item.code).contains(normalizedQuery) ||
          _normalize(item.title).contains(normalizedQuery)) {
        results.add(item);
        if (results.length >= limit) break;
      }
    }
    return results;
  }

  static String _normalize(String value) {
    return PersianNumberFormatter.toEnglish(value)
        .replaceAll('ي', 'ی')
        .replaceAll('ك', 'ک')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim()
        .toLowerCase();
  }
}
