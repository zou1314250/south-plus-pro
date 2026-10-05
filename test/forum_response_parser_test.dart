import 'package:flutter_test/flutter_test.dart';
import 'package:south_plus_rewrite/services/parsers/forum_response_parser.dart';

void main() {
  const parser = ForumResponseParser();

  group('ForumResponseParser.pageMessage', () {
    test('keeps the specific part of a branded title', () {
      final html = '<html><head><title>'
          '登录 - 南+ South Plus - powered by Pu!mdHd'
          '</title></head><body></body></html>';
      expect(parser.pageMessage(html), '登录');
    });

    test('does not return an empty message for a generic title', () {
      final html = '<html><head><title>'
          '南+ South Plus - powered by Pu!mdHd'
          '</title></head><body>用户名或密码错误</body></html>';
      final message = parser.pageMessage(html);
      expect(message, isNotEmpty);
      expect(message, contains('密码'));
    });

    test('handles a rebranded site suffix', () {
      final html = '<html><head><title>'
          '提示 - South Plus Forum'
          '</title></head><body></body></html>';
      expect(parser.pageMessage(html), '提示');
    });

    test('handles a missing title by reading the body', () {
      final html = '<html><body>非法请求，请返回重试</body></html>';
      final message = parser.pageMessage(html);
      expect(message, isNotEmpty);
      expect(message, contains('非法'));
    });
  });
}
