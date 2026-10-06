import 'package:html/dom.dart' as dom;

import '../../models/forum_models.dart';
import '../forum_url_resolver.dart';

/// A parsed search result page: the visible threads plus its pagination.
class SearchResultPage {
  const SearchResultPage({
    required this.threads,
    required this.currentPage,
    required this.totalPages,
    this.pageHrefs = const {},
  });

  final List<ForumThread> threads;
  final int currentPage;
  final int totalPages;

  /// Page number -> href, taken straight from the page markup.
  ///
  /// phpwind search paging carries a session bound `searchid`, so the only
  /// reliable way to reach page N is to follow the link the result page itself
  /// printed rather than guessing the query shape.
  final Map<int, String> pageHrefs;
}

class SearchResultParser {
  SearchResultParser({ForumUrlResolver? urls})
      : urls = urls ?? ForumUrlResolver();

  final ForumUrlResolver urls;

  /// Parses threads together with the pagination projection.
  SearchResultPage parsePage(dom.Document document) {
    final hrefs = <int, String>{};
    for (final link in document.querySelectorAll('a[href]')) {
      final href = link.attributes['href'] ?? '';
      if (!href.contains('search.php')) continue;
      final match = RegExp(r'[?&]page=(\d+)').firstMatch(href);
      if (match == null) continue;
      final page = int.tryParse(match.group(1)!);
      if (page == null || page < 1) continue;
      hrefs.putIfAbsent(page, () => href);
    }

    var current = 1;
    var total = hrefs.isEmpty ? 1 : hrefs.keys.reduce((a, b) => a > b ? a : b);
    final pageText = _cleanText(document.body?.text ?? '');
    final pages = RegExp(r'Pages:\s*(\d+)\s*/\s*(\d+)').firstMatch(pageText);
    if (pages != null) {
      current = int.tryParse(pages.group(1)!) ?? current;
      total = int.tryParse(pages.group(2)!) ?? total;
    } else {
      final active = _cleanText(
        document.querySelector('.pages b')?.text ??
            document.querySelector('.pages .current')?.text ??
            document.querySelector('.pagination .active')?.text ??
            '',
      );
      current = int.tryParse(active) ?? current;
    }
    if (total < current) total = current;

    return SearchResultPage(
      threads: parse(document),
      currentPage: current,
      totalPages: total,
      pageHrefs: hrefs,
    );
  }

  List<ForumThread> parse(dom.Document document) {
    final threads = <ForumThread>[];
    final seen = <String>{};
    for (final row in document.querySelectorAll('tr')) {
      final threadLink = row.querySelector('a[href*="read.php?tid-"]');
      if (threadLink == null) continue;

      final href = threadLink.attributes['href'] ?? '';
      final title = _cleanText(threadLink.text);
      if (href.isEmpty || title.isEmpty || !seen.add(href)) continue;

      final cells = row.children
          .where((child) => child.localName == 'td' || child.localName == 'th')
          .toList();
      final sectionCell = cells.length > 2 ? cells[2] : row;
      final authorCell = cells.length > 3 ? cells[3] : row;
      final repliesCell = cells.length > 4 ? cells[4] : null;

      final section = _cleanText(
        sectionCell.querySelector('a[href*="thread.php"]')?.text ?? '',
      );
      final authorLink = authorCell.querySelector('a[href*="uid"]');
      final author = _cleanText(authorLink?.text ?? '');
      final authorHref = authorLink?.attributes['href'] ?? '';
      final date = RegExp(r'\d{4}-\d{2}-\d{2}')
          .firstMatch(_cleanText(authorCell.text))
          ?.group(0);

      threads.add(
        ForumThread(
          title: title,
          url: urls.absoluteUrl(href),
          replies: _firstInt(_cleanText(repliesCell?.text ?? '')) ?? 0,
          section: section.isEmpty ? '搜索结果' : section,
          author: author.isEmpty ? null : author,
          authorUrl: authorHref.isEmpty ? null : urls.absoluteUrl(authorHref),
          lastPost: date,
        ),
      );
      if (threads.length >= 60) break;
    }
    return threads;
  }

  int? _firstInt(String input) {
    final match = RegExp(r'\d+').firstMatch(input);
    return match == null ? null : int.tryParse(match.group(0)!);
  }

  String _cleanText(String input) {
    return input.replaceAll(RegExp(r'\s+'), ' ').trim();
  }
}
