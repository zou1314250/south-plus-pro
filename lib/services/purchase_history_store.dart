import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/forum_models.dart';

/// Local record of threads whose paid content the user unlocked in the app.
///
/// The forum exposes no "bought topics" page, so the app remembers every
/// successful `buySaleBox` call itself. Records are keyed by topic id, newest
/// first, and capped at [maxEntries].
class PurchaseHistoryStore {
  PurchaseHistoryStore({this.maxEntries = 200});

  static const storageKey = 'purchases.threads.v1';

  final int maxEntries;

  Future<List<PurchasedThread>> recent({int limit = 100}) async {
    final entries = await _read();
    if (limit <= 0 || entries.length <= limit) return entries;
    return entries.sublist(0, limit);
  }

  Future<void> record(PurchasedThread entry) async {
    if (entry.tid.isEmpty || entry.title.isEmpty || entry.url.isEmpty) return;
    final entries = await _read();
    final next = <PurchasedThread>[
      entry,
      ...entries.where((item) => item.tid != entry.tid),
    ];
    final capped = maxEntries > 0 && next.length > maxEntries
        ? next.sublist(0, maxEntries)
        : next;
    await _write(capped);
  }

  Future<void> remove(String tid) async {
    final entries = await _read();
    await _write(
      entries.where((item) => item.tid != tid).toList(growable: false),
    );
  }

  Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(storageKey);
  }

  Future<List<PurchasedThread>> _read() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(storageKey);
    if (raw == null || raw.isEmpty) return const [];
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) return const [];
      return decoded
          .map(PurchasedThread.fromJson)
          .nonNulls
          .toList(growable: false);
    } on FormatException {
      return const [];
    }
  }

  Future<void> _write(List<PurchasedThread> entries) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      storageKey,
      jsonEncode(entries.map((entry) => entry.toJson()).toList()),
    );
  }
}
