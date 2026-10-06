import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

/// Local list of past search keywords, newest first.
///
/// Kept on the device only: the forum has no search-history API, and the list
/// is short lived convenience data.
class SearchHistoryStore {
  SearchHistoryStore({this.maxEntries = 30});

  static const storageKey = 'search.history.v1';

  final int maxEntries;

  Future<List<String>> recent({int limit = 20}) async {
    final entries = await _read();
    if (limit <= 0 || entries.length <= limit) return entries;
    return entries.sublist(0, limit);
  }

  Future<void> record(String keyword) async {
    final value = keyword.trim();
    if (value.isEmpty) return;
    final entries = await _read();
    final next = <String>[
      value,
      ...entries.where((item) => item != value),
    ];
    final capped =
        maxEntries > 0 && next.length > maxEntries ? next.sublist(0, maxEntries) : next;
    await _write(capped);
  }

  Future<void> remove(String keyword) async {
    final entries = await _read();
    await _write(
      entries.where((item) => item != keyword).toList(growable: false),
    );
  }

  Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(storageKey);
  }

  Future<List<String>> _read() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(storageKey);
    if (raw == null || raw.isEmpty) return const [];
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) return const [];
      return decoded
          .map((item) => '$item'.trim())
          .where((item) => item.isNotEmpty)
          .toList(growable: false);
    } on FormatException {
      return const [];
    }
  }

  Future<void> _write(List<String> entries) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(storageKey, jsonEncode(entries));
  }
}
