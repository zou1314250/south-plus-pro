import 'package:flutter_test/flutter_test.dart';
import 'package:html/parser.dart' as html_parser;
import 'package:south_plus_rewrite/services/parsers/search_result_parser.dart';

void main() {
  final parser = SearchResultParser();

  test('SearchResultParser.parsePage reads pagination links and Pages text',
      () {
    final document = html_parser.parse('''
      <html>
        <body>
          <div class="pages">
            Pages: 2/39
            <a href="search.php?searchid=abc&amp;page=1">1</a>
            <a href="search.php?searchid=abc&amp;page=3">3</a>
            <a href="search.php?searchid=abc&amp;page=39">39</a>
          </div>
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
    expect(page.totalPages, 39);
    // Page hrefs are followed verbatim because they carry phpwind's searchid.
    expect(page.pageHrefs[1], 'search.php?searchid=abc&page=1');
    expect(page.pageHrefs[39], 'search.php?searchid=abc&page=39');
    expect(page.threads.map((thread) => thread.title), ['搜索结果一']);
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

  test('SearchResultParser.parsePage ignores non search.php page links', () {
    final document = html_parser.parse('''
      <html>
        <body>
          <a href="thread.php?fid-128-page-5.html">版块翻页</a>
          <a href="search.php?searchid=zz&amp;page=4">4</a>
        </body>
      </html>
    ''');

    final page = parser.parsePage(document);

    expect(page.pageHrefs.keys, [4]);
    expect(page.totalPages, 4);
  });

  test('SearchResultParser.parsePage accepts relative search paging links', () {
    // Regression: phpwind does not always prefix the page links with
    // `search.php`; the old parser required that prefix, so the page bar showed
    // up (total came from `Pages: x/y`) but every tap failed to resolve an href.
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
    expect(page.pageHrefs[6], '?searchid=778899&page=6');
    expect(page.searchId, '778899');
  });

  test('SearchResultParser.parsePage reads the search session id', () {
    final document = html_parser.parse('''
      <html>
        <body>
          <a href="search.php?searchid=4242&amp;page=3">3</a>
        </body>
      </html>
    ''');

    expect(parser.parsePage(document).searchId, '4242');
  });
}
