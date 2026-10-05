import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:south_plus_rewrite/services/forum_body_decoder.dart';

void main() {
  group('decodeForumBody', () {
    test('decodes plain UTF-8 without a declared charset', () {
      final bytes = utf8.encode('南+ 论坛');
      expect(decodeForumBody(bytes), '南+ 论坛');
    });

    test('decodes UTF-8 when the server declares it', () {
      final bytes = utf8.encode('回复成功');
      expect(
        decodeForumBody(
          bytes,
          contentType: ContentType('text', 'html', charset: 'utf-8'),
        ),
        '回复成功',
      );
    });

    test('decodes latin1 when the server declares it', () {
      final bytes = latin1.encode('café');
      expect(
        decodeForumBody(
          bytes,
          contentType: ContentType('text', 'html', charset: 'iso-8859-1'),
        ),
        'café',
      );
    });

    test('never throws on malformed UTF-8 bytes', () {
      // 0xFF is not a valid UTF-8 leading byte.
      final bytes = <int>[0xE5, 0x9B, 0x9E, 0xFF, 0xE5, 0xA4, 0xB4];
      late String decoded;
      expect(() => decoded = decodeForumBody(bytes), returnsNormally);
      expect(decoded, contains('回'));
      expect(decoded, contains('\uFFFD'));
    });

    test('falls back to lenient UTF-8 for unsupported charsets', () {
      final bytes = utf8.encode('任务');
      expect(
        decodeForumBody(
          bytes,
          contentType: ContentType('text', 'html', charset: 'gbk'),
        ),
        '任务',
      );
    });
  });
}
