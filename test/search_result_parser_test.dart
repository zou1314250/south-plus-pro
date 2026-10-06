import 'package:flutter_test/flutter_test.dart';
import 'package:html/parser.dart' as html_parser;
import 'package:south_plus_rewrite/services/parsers/search_result_parser.dart';

/// Pagination exactly as the forum prints it: phpwind rewrite links carrying
/// the search session id, with the current page rendered as `<b>` (no link).
const _realPagination = '''
  <div class="pages">
    <ul>
      <li><a href="https://www.blue-plus.net/search.php?step-2-keyword-%E9%9F%B3%E5%A3%B0%E6%BC%AB%E7%94%BB-sid-259906137-seekfid-all-page-1.html" style="font-weight:bold">«</a></li>
      <li><a href="https://www.blue-plus.net/search.php?step-2-keyword-%E9%9F%B3%E5%A3%B0%E6%BC%AB%E7%94%BB-sid-259906137-seekfid-all-page-1.html">1</a></li>
      <li><b> 2 </b></li>
      <li><a href="https://www.blue-plus.net/search.php?step-2-keyword-%E9%9F%B3%E5%A3%B0%E6%BC%AB%E7%94%BB-sid-259906137-seekfid-all-page-3.html">3</a></li>
      <li><a href="https://www.blue-plus.net/search.php?step-2-keyword-%E9%9F%B3%E5%A3%B0%E6%BC%AB%E7%94%BB-sid-259906137-seekfid-all-page-4.html">4</a></li>
    </ul>
  </div>
''';

void main() {
  final parser = SearchResultParser();

  test('SearchResultParser.parsePage reads phpwind rewrite paging links', () {
    // Regression: the links use `page-3.html` (rewrite) and `sid-…` (not
    // `page=3` / `searchid=`), so the old parser found no hrefs at all and
    // every page tap failed even though the page bar was rendered.
    final document = html_parser.parse('''
      <html>
        <body>
          <div class="pages">Pages: 2/4</div>
          $_realPagination
          <table>
            <tr class="tr3">
              <td><a href="read.php?tid-1.html">搜索结果一</a></td>
            </tr>
          </table>
        </body>
      </html>
    ''');

    final page = parser.parsePage(document);

    expect(page.currentPage, 2);
    expect(page.totalPages, 4);
    expect(page.searchId, '259906137');
    expect(page.pageHrefs.keys.toSet(), {1, 3, 4});
    expect(page.pageHrefs[3], contains('page-3.html'));
    expect(page.threads.map((thread) => thread.title), ['搜索结果一']);
  });

  test('SearchResultPage.hrefFor prefers the printed link', () {
    final document =
        html_parser.parse('<html><body>$_realPagination</body></html>');

    final page = parser.parsePage(document);

    expect(page.hrefFor(3), page.pageHrefs[3]);
  });

  test('SearchResultPage.hrefFor rewrites a sibling when the page has no link',
      () {
    // Page 2 is the current page and is printed as `<b>2</b>`, so there is no
    // link for it; it has to be derived from a sibling.
    final document =
        html_parser.parse('<html><body>$_realPagination</body></html>');

    final page = parser.parsePage(document);
    final href = page.hrefFor(2);

    expect(href, isNotNull);
    expect(href, contains('page-2.html'));
    expect(href, contains('sid-259906137'));
  });

  test('SearchResultPage.hrefFor falls back to the legacy query shape', () {
    final document = html_parser.parse('''
      <html><body><a href="search.php?searchid=4242&amp;page=3">3</a></body></html>
    ''');

    final page = parser.parsePage(document);

    expect(page.searchId, '4242');
    expect(page.hrefFor(9), 'search.php?searchid=4242&page=9');
  });

  test('SearchResultParser.parsePage accepts plain page= links', () {
    final document = html_parser.parse('''
      <html>
        <body>
          <div class="pages">
            Pages: 1/6
            <a href="?searchid=778899&amp;page=2">2</a>
            <a href="?searchid=778899&amp;page=6">6</a>
          </div>
        </body>
      </html>
    ''');

    final page = parser.parsePage(document);

    expect(page.totalPages, 6);
    expect(page.pageHrefs[2], '?searchid=778899&page=2');
  });

  test('SearchResultParser.parsePage ignores other listings paging', () {
    final document = html_parser.parse('''
      <html>
        <body>
          <a href="thread.php?fid-128-page-5.html">版块翻页</a>
          <a href="thread_new.php?fid-128-page-7.html">版块新帖翻页</a>
          <a href="read.php?tid-1-fpage-9.html">帖子分页</a>
          <a href="search.php?step-2-keyword-x-sid-1-seekfid-all-page-4.html">4</a>
        </body>
      </html>
    ''');

    final page = parser.parsePage(document);

    expect(page.pageHrefs.keys, [4]);
    expect(page.totalPages, 4);
  });

  test('SearchResultParser.parsePage falls back to a single page', () {
    final document = html_parser.parse('''
      <html>
        <body>
          <table>
            <tr class="tr3">
              <td><a href="read.php?tid-7.html">唯一结果</a></td>
            </tr>
          </table>
        </body>
      </html>
    ''');

    final page = parser.parsePage(document);

    expect(page.currentPage, 1);
    expect(page.totalPages, 1);
    expect(page.pageHrefs, isEmpty);
    expect(page.threads, hasLength(1));
  });
}
