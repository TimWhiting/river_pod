import 'dart:isolate';

import 'package:riverpod_cli/src/analyzer_plugin/plugin_starter.dart';

void main(List<String> args, SendPort sendPort) {
  start(args, sendPort);
}
