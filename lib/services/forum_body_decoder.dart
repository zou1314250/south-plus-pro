import 'dart:convert';
import 'dart:io';

/// Decodes a forum HTTP body using the charset declared by the server.
///
/// `HttpClient` hands us raw bytes. The forum declares UTF-8 today, but a
/// mis-declared or partially corrupted response used to throw a
/// [FormatException] and take the whole request down. Decode leniently so a
/// single bad byte degrades into a replacement character instead of an error.
///
/// This lives in its own file (no Flutter imports) so it can be unit tested
/// with a plain Dart VM.
String decodeForumBody(List<int> bytes, {ContentType? contentType}) {
  final charset = contentType?.charset?.trim().toLowerCase();
  if (charset == null ||
      charset.isEmpty ||
      charset == 'utf-8' ||
      charset == 'utf8') {
    return _lenientUtf8(bytes);
  }
  if (charset == 'latin1' || charset == 'latin-1' || charset == 'iso-8859-1') {
    return latin1.decode(bytes, allowInvalid: true);
  }
  // GBK / GB2312 / GB18030 and friends are not provided by dart:convert.
  // Fall back to lenient UTF-8 so the caller still gets a usable string
  // instead of an exception; the text may be mojibake but parsing and error
  // reporting keep working.
  return _lenientUtf8(bytes);
}

String _lenientUtf8(List<int> bytes) {
  try {
    return utf8.decode(bytes);
  } on FormatException {
    return utf8.decode(bytes, allowMalformed: true);
  }
}
