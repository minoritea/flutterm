import 'dart:convert';
import 'package:flutter/foundation.dart';

class TerminalParser extends Converter<dynamic, List<String>> {
  TerminalParser() : super();

  final List<String> _state = [];

  List<String> convert(dynamic input) {
    final List<int> data = input as List<int>;

    final regexp = RegExp(r'\x1B');
    final str = utf8.decode(data).replaceAll(regexp, '^[');

    RegExp(r'[\x00-\x1F\x7F]').allMatches(str).forEach((m) {
      debugPrint("control chars");
      debugPrint(m[0]?.codeUnits.toString());
    });

    debugPrint('"' + str + '"');

    _state.add(str);
    return _state;
  }

  @override
  Sink startChunkedConversion(Sink<List<String>> sink) {
    return TerminalParserSink(sink, this);
  }
}

class TerminalParserSink extends ChunkedConversionSink<dynamic> {
  Sink<List<String>> _innerSink;
  Converter<dynamic, List<String>> _converter;
  TerminalParserSink(this._innerSink, this._converter) : super();

  @override
  void add(chunk) {
    _innerSink.add(_converter.convert(chunk));
  }

  @override
  void close() {
    _innerSink.close();
  }
}
