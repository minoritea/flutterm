import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:rxdart/rxdart.dart';

import 'parser.dart';

class Home extends StatelessWidget {
  const Home({Key? key}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Terminal(),
    );
  }
}

class Terminal extends StatefulWidget {
  const Terminal({Key? key}) : super(key: key);

  @override
  _TerminalState createState() => _TerminalState();
}

class _TerminalState extends State<Terminal> {
  final _channel = WebSocketChannel.connect(
    Uri.parse('ws://127.0.0.1:50505'),
  );

  final _textController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      Expanded(
        child: SizedBox.expand(
          child: Container(
            // constraints: BoxConstraints.tightForFinite(),
            color: Colors.blueGrey,
            child: StreamBuilder<List<String>>(
              stream: _channel.stream.transform(
                /*
                ScanStreamTransformer<dynamic, List<List<int>>>((acc, curr, i) {
                  acc.add(curr as List<int>);
                  return acc;
                }, []),*/
                TerminalParser(),
              ),
              builder: (context, snapshot) {
                final List<String>? data = snapshot.data;
                if (data == null) {
                  return Text("");
                }

                final str = data.join("\n");
                return Text(str);
              },
            ),
          ),
        ),
      ),
      TextField(
        controller: _textController,
        onSubmitted: (text) {
          debugPrint(text);
          _textController.clear();
          _channel.sink.add(utf8.encode(text + "\n"));
        },
        decoration: InputDecoration(
          border: OutlineInputBorder(),
        ),
      ),
    ]);
  }

  @override
  void dispose() {
    _channel.sink.close();
    super.dispose();
  }
}
