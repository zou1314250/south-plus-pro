import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:south_plus_rewrite/services/search_history_store.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  test('SearchHistoryStore records newest first and dedupes', () async {
    final store = SearchHistoryStore();

    await store.record('音声漫画');
    await store.record('同人音声');
    await store.record('音声漫画');

    expect(await store.recent(), ['音声漫画', '同人音声']);
  });

  test('SearchHistoryStore trims and ignores empty keywords', () async {
    final store = SearchHistoryStore();

    await store.record('  中文音声  ');
    await store.record('   ');
    await store.record('');

    expect(await store.recent(), ['中文音声']);
  });

  test('SearchHistoryStore caps stored entries', () async {
    final store = SearchHistoryStore(maxEntries: 2);

    await store.record('a');
    await store.record('b');
    await store.record('c');

    expect(await store.recent(), ['c', 'b']);
  });

  test('SearchHistoryStore remove and clear', () async {
    final store = SearchHistoryStore();
    await store.record('a');
    await store.record('b');

    await store.remove('a');
    expect(await store.recent(), ['b']);

    await store.clear();
    expect(await store.recent(), isEmpty);
  });

  test('SearchHistoryStore survives a broken payload', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{
      SearchHistoryStore.storageKey: '{not json',
    });

    expect(await SearchHistoryStore().recent(), isEmpty);
  });

  test('SearchHistoryStore drops non string and empty entries', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{
      SearchHistoryStore.storageKey: '["ok", "", "   ", 42]',
    });

    expect(await SearchHistoryStore().recent(), ['ok', '42']);
  });
}
