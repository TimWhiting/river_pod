import 'dart:isolate';

import 'package:analyzer/file_system/physical_file_system.dart';
import 'package:analyzer_plugin/starter.dart';
import 'package:riverpod_cli/src/analyzer_plugin/plugin.dart';

void start(List<String> args, SendPort sendPort) {
  ServerPluginStarter(RiverpodAnalysisPlugin(PhysicalResourceProvider.INSTANCE))
      .start(sendPort);
}
