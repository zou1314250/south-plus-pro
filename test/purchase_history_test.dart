import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:south_plus_rewrite/models/forum_models.dart';
import 'package:south_plus_rewrite/services/purchase_history_store.dart';

PurchasedThread _entry(String tid, String title, {int? price}) {
  return PurchasedThread(
    tid: tid,
    title: title,
    url: 'https://south-plus.net/read.php?tid-$tid.html',
    price: price,
  );
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  test('PurchaseHistoryStore records newest first and dedupes by tid',
      () async {
    final store = PurchaseHistoryStore();

    await store.record(_entry('1', '帖子一'));
    await store.record(_entry('2', '帖子二'));
    await store.record(_entry('1', '帖子一（重新购买）'));

    final entries = await store.recent();
    expect(entries.map((entry) => entry.tid), ['1', '2']);
    expect(entries.first.title, '帖子一（重新购买）');
  });

  test('PurchaseHistoryStore caps stored entries', () async {
    final store = PurchaseHistoryStore(maxEntries: 2);

    await store.record(_entry('1', '帖子一'));
    await store.record(_entry('2', '帖子二'));
    await store.record(_entry('3', '帖子三'));

    final entries = await store.recent();
    expect(entries.map((entry) => entry.tid), ['3', '2']);
  });

  test('PurchaseHistoryStore ignores malformed stored payloads', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{
      PurchaseHistoryStore.storageKey: '[{"tid":"9","title":"好的",'
          '"url":"https://south-plus.net/read.php?tid-9.html"},'
          '{"tid":"","title":"缺 id","url":"x"},{"nope":1}]',
    });

    final entries = await PurchaseHistoryStore().recent();

    expect(entries, hasLength(1));
    expect(entries.single.tid, '9');
  });

  test('PurchaseHistoryStore survives a broken json payload', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{
      PurchaseHistoryStore.storageKey: '{not json',
    });

    expect(await PurchaseHistoryStore().recent(), isEmpty);
  });

  test('PurchaseHistoryStore remove and clear', () async {
    final store = PurchaseHistoryStore();
    await store.record(_entry('1', '帖子一'));
    await store.record(_entry('2', '帖子二'));

    await store.remove('1');
    expect((await store.recent()).map((entry) => entry.tid), ['2']);

    await store.clear();
    expect(await store.recent(), isEmpty);
  });

  test('PurchasedThread.fromSaleBox extracts tid, pid and price', () {
    const saleBox = ThreadSaleBox(
      summary: '此帖售价 5 SP币,已有 8 人购买',
      buyPath: 'job.php?action=buytopic&tid=2971014&pid=37448666&verify=abc',
      price: 5,
    );

    final entry = PurchasedThread.fromSaleBox(
      saleBox: saleBox,
      title: '  测试帖  ',
      url: 'https://south-plus.net/read.php?tid-2971014.html',
    );

    expect(entry, isNotNull);
    expect(entry!.tid, '2971014');
    expect(entry.pid, '37448666');
    expect(entry.price, 5);
    expect(entry.title, '测试帖');
  });

  test('PurchasedThread.fromSaleBox accepts the tpc pseudo pid', () {
    const saleBox = ThreadSaleBox(
      summary: '此帖售价 0 SP币,已有 21 人购买',
      buyPath: 'job.php?action=buytopic&tid=2971014&pid=tpc&verify=abc',
    );

    final entry = PurchasedThread.fromSaleBox(
      saleBox: saleBox,
      title: '测试帖',
      url: 'https://south-plus.net/read.php?tid-2971014.html',
    );

    expect(entry?.pid, 'tpc');
  });

  test('PurchasedThread.fromSaleBox rejects a link without tid', () {
    const saleBox = ThreadSaleBox(summary: '无链接', buyPath: 'job.php?action=x');

    expect(
      PurchasedThread.fromSaleBox(
        saleBox: saleBox,
        title: '测试帖',
        url: 'https://south-plus.net/read.php?tid-1.html',
      ),
      isNull,
    );
  });

  test('PurchasedThread json round-trips', () {
    final entry = PurchasedThread(
      tid: '42',
      title: '标题',
      url: 'https://south-plus.net/read.php?tid-42.html',
      pid: 'tpc',
      price: 12,
      purchasedAt: DateTime.utc(2026, 10, 5, 1, 30),
    );

    final restored = PurchasedThread.fromJson(entry.toJson());

    expect(restored, isNotNull);
    expect(restored!.tid, '42');
    expect(restored.pid, 'tpc');
    expect(restored.price, 12);
    expect(restored.purchasedAt, entry.purchasedAt);
  });
}
