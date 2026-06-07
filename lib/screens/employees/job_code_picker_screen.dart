import 'dart:async';

import 'package:flutter/material.dart';

import '../../data/job_title_repository.dart';
import '../../utils/persian_number_formatter.dart';

class JobCodePickerScreen extends StatefulWidget {
  final String? initialCode;
  final String? initialTitle;

  const JobCodePickerScreen({super.key, this.initialCode, this.initialTitle});

  @override
  State<JobCodePickerScreen> createState() => _JobCodePickerScreenState();
}

class _JobCodePickerScreenState extends State<JobCodePickerScreen> {
  final _searchCtrl = TextEditingController();
  List<JobTitleEntry> _allItems = const [];
  List<JobTitleEntry> _visibleItems = const [];
  Timer? _debounce;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    final initial = [
      widget.initialCode?.trim(),
      widget.initialTitle?.trim(),
    ].whereType<String>().where((item) => item.isNotEmpty).join(' ');
    _searchCtrl.text = initial;
    _load();
  }

  Future<void> _load() async {
    final items = await JobTitleRepository.load();
    if (!mounted) return;
    setState(() {
      _allItems = items;
      _visibleItems = JobTitleRepository.search(items, _searchCtrl.text);
      _loading = false;
    });
  }

  void _onSearchChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 220), () {
      if (!mounted) return;
      setState(() {
        _visibleItems = JobTitleRepository.search(_allItems, value);
      });
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: const Text('انتخاب کد شغل بیمه')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              controller: _searchCtrl,
              autofocus: true,
              onChanged: _onSearchChanged,
              decoration: const InputDecoration(
                labelText: 'جستجو بر اساس عنوان یا کد شغل',
                prefixIcon: Icon(Icons.search_rounded),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Icon(Icons.dataset_rounded, size: 18, color: scheme.primary),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'بانک عناوین: ${PersianNumberFormatter.toPersian(_allItems.length.toString())} ردیف',
                    style: TextStyle(
                      color: scheme.onSurfaceVariant,
                      fontSize: 12,
                    ),
                  ),
                ),
                Text(
                  'نمایش ${PersianNumberFormatter.toPersian(_visibleItems.length.toString())}',
                  style: TextStyle(color: scheme.primary, fontSize: 12),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : ListView.builder(
                    itemCount: _visibleItems.length,
                    itemBuilder: (context, index) {
                      final item = _visibleItems[index];
                      return ListTile(
                        leading: CircleAvatar(
                          child: Text(
                            PersianNumberFormatter.toPersian(
                              item.code.length > 4
                                  ? item.code.substring(item.code.length - 4)
                                  : item.code,
                            ),
                            style: const TextStyle(fontSize: 11),
                          ),
                        ),
                        title: Text(item.title),
                        subtitle: Text(
                          PersianNumberFormatter.toPersian(item.code),
                        ),
                        onTap: () => Navigator.pop(context, item),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
