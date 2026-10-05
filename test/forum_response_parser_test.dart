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

  group('ForumResponseParser.taskActionReply', () {
    test('unwraps one CDATA holding a tab separated pair', () {
      // Real reply shape: the tab lives inside the CDATA, so splitting the raw
      // response glued `<ajax><![CDATA[` onto the status and every task action
      // looked like a failure.
      const response =
          '<ajax><![CDATA[fail\t您申请过[日常]还未完成,不需要重新申请!]]></ajax>';

      final reply = parser.taskActionReply(response);

      expect(reply.status, 'fail');
      expect(reply.message, contains('您申请过'));
      expect(reply.message, isNot(contains('ajax')));
      expect(reply.message, isNot(contains('CDATA')));
    });

    test('reads a success pair', () {
      const response = '<ajax><![CDATA[success\t任务领取完成]]></ajax>';

      final reply = parser.taskActionReply(response);

      expect(reply.status, 'success');
      expect(reply.message, '任务领取完成');
    });

    test('reads one CDATA per field', () {
      const response =
          '<ajax><![CDATA[success]]><![CDATA[奖励领取完成]]></ajax>';

      final reply = parser.taskActionReply(response);

      expect(reply.status, 'success');
      expect(reply.message, '奖励领取完成');
    });

    test('reads a plain tab separated reply', () {
      final reply = parser.taskActionReply('fail\t任务操作失败');

      expect(reply.status, 'fail');
      expect(reply.message, '任务操作失败');
    });

    test('keeps a bare status with an empty message', () {
      final reply = parser.taskActionReply('success');

      expect(reply.status, 'success');
      expect(reply.message, isEmpty);
    });
  });
}
