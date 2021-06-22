import 'dart:convert';
import 'package:flutter/foundation.dart';

enum VTState {
  Ground,
  Escape,
  EscapeIntermediate,
  CSIEntry,
  CSIParam,
  CSIIntermediate,
  CSIIgnore
}

/*
extension TypeExtension on VTState {
  static final typenames = {
    VTState.Ground: "ground",
    VTState.Escape: "escape"
  };

  String? get name => typenames[this];
}
*/

List<int> range(int start, end) {
  return List.generate(end - start, (i) => i + start);
}

class TerminalParser extends Converter<dynamic, List<String>> {
  TerminalParser() : super();

  final List<String> _view = [];
  List<int> _line = [];
  VTState _current = VTState.Ground;

  consume(int input) {
    // from anywhere
    if (input == 0x1B) {
      _current = VTState.Ground;
      return;
    }

    if (input == 0x9B) {
      _current = VTState.CSIEntry;
      return;
    }

    switch (_current) {
      case VTState.Ground:
        if (Set.of(range(0x20, 0x7F)).contains(input)) {
          _line.add(input);
          break;
        }

        if (input == 0x1B) {
          _current = VTState.Escape;
          break;
        }
        break;

      case VTState.Escape:
        if (Set.of(range(0x20, 0x2F)).contains(input)) {
          _current = VTState.EscapeIntermediate;
          break;
        }

        if (Set.of(range(0x30, 0x4F) +
                range(0x51, 0x57) +
                [0x59, 0x5A, 0x5C] +
                range(0x60, 0x7E))
            .contains(input)) {
          _current = VTState.Ground;
          break;
        }
        break;

      case VTState.EscapeIntermediate:
        if (Set.of(range(0x30, 0x7E)).contains(input)) {
          _current = VTState.Ground;
          break;
        }
        break;
      case VTState.CSIEntry:
        if (input == 0x3A) {
          _current = VTState.CSIIgnore;
          break;
        }
        break;

      case VTState.CSIIgnore:
      case VTState.CSIIntermediate:
      case VTState.CSIParam:
    }
  }

  List<String> convert(dynamic input) {
    final List<int> data = input as List<int>;
    _line = [];
    data.forEach(consume);

    //final regexp = RegExp(r'\x1B');
    final str = utf8.decode(_line); //.replaceAll(regexp, '^[');
    RegExp(r'[\x00-\x1F\x7F]').allMatches(str).forEach((m) {
      debugPrint("control chars");
      debugPrint(m[0]?.codeUnits.toString());
    });

    debugPrint('"' + str + '"');

    _view.add(str);
    return _view;
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
