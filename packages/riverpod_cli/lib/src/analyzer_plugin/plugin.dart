import 'dart:async';
import 'dart:isolate';

import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/file_system/file_system.dart';
import 'package:analyzer/file_system/physical_file_system.dart';
// ignore: implementation_imports
import 'package:analyzer/src/context/builder.dart';
// ignore: implementation_imports
import 'package:analyzer/src/context/context_root.dart';
// ignore: implementation_imports
import 'package:analyzer/src/dart/analysis/driver.dart';
// ignore: implementation_imports
import 'package:analyzer/src/dart/analysis/file_state.dart';
import 'package:analyzer_plugin/channel/channel.dart';
import 'package:analyzer_plugin/plugin/plugin.dart';
import 'package:analyzer_plugin/protocol/protocol_common.dart' as plugin;
import 'package:analyzer_plugin/protocol/protocol_generated.dart' as plugin;
import 'package:analyzer_plugin/starter.dart';

void start(List<String> args, SendPort sendPort) {
  ServerPluginStarter(RiverpodAnalysisPlugin(PhysicalResourceProvider.INSTANCE))
      .start(sendPort);
}

class RiverpodAnalysisPlugin extends ServerPlugin {
  RiverpodAnalysisPlugin(ResourceProvider? provider) : super(provider);

  final Checker checker = Checker();
  @override
  AnalysisDriverGeneric createAnalysisDriver(plugin.ContextRoot contextRoot) {
    print('Hi');
    final rootPath = contextRoot.root;
    final root = ContextRoot(
      rootPath,
      contextRoot.exclude,
      pathContext: resourceProvider.pathContext,
    )..optionsFilePath = contextRoot.optionsFile;

    final contextBuilder = ContextBuilder(resourceProvider, sdkManager, null)
      ..analysisDriverScheduler = analysisDriverScheduler
      ..byteStore = byteStore
      ..performanceLog = performanceLog
      ..fileContentOverlay = FileContentOverlay();

    final workspace = ContextBuilder.createWorkspace(
      resourceProvider: resourceProvider,
      options: ContextBuilderOptions(),
      rootPath: rootPath,
    );

    final dartDriver = contextBuilder.buildDriver(root, workspace);
    runZonedGuarded(
      () {
        dartDriver.results.listen(_processResult);
      },
      (e, stackTrace) {
        channel.sendNotification(
          plugin.PluginErrorParams(false, e.toString(), stackTrace.toString())
              .toNotification(),
        );
      },
    );
    return dartDriver;
  }

  @override
  List<String> get fileGlobsToAnalyze => const ['*.dart'];

  @override
  String get name => 'riverpod analyzer';

  @override
  String get version => '1.0.0-alpha.0';

  /// Computes errors based on an analysis result and notifies the analyzer.
  // ignore: deprecated_member_use
  void _processResult(ResolvedUnitResult analysisResult) {
    // If there is no relevant analysis result, notify the analyzer of no errors.
    try {
      if (analysisResult.unit != null) {
        final checkResult =
            checker.check(analysisResult.libraryElement, channel);
        channel.sendNotification(plugin.AnalysisErrorsParams(
                analysisResult.path!, checkResult.keys.toList())
            .toNotification());
      } else {
        channel.sendNotification(
          plugin.AnalysisErrorsParams(analysisResult.path!, [])
              .toNotification(),
        );
      }
    } on Exception catch (e, stackTrace) {
      channel.sendNotification(
        plugin.PluginErrorParams(false, e.toString(), stackTrace.toString())
            .toNotification(),
      );
    }
  }

  @override
  void contentChanged(String path) {
    super.driverForPath(path)?.addFile(path);
  }
}

class Checker {
  Map<plugin.AnalysisError, plugin.PrioritizedSourceChange> check(
      LibraryElement libraryElement, PluginCommunicationChannel channel) {
    final result = <plugin.AnalysisError, plugin.PrioritizedSourceChange>{};
    for (final compilationUnit in libraryElement.units) {
      try {
        final error = compilationUnit.library.imports.firstWhere(
            (element) => element.uri?.contains('riverpod') ?? false);
        final lineInfo = compilationUnit.lineInfo?.getLocation(error.uriOffset);
        final lineEndInfo =
            compilationUnit.lineInfo?.getLocation(error.uriOffset + 5);

        final err = plugin.AnalysisError(
          plugin.AnalysisErrorSeverity.INFO,
          plugin.AnalysisErrorType.LINT,
          plugin.Location(
            compilationUnit.source.fullName,
            error.uriOffset + 1,
            error.uri!.length,
            lineInfo!.lineNumber,
            lineInfo.columnNumber,
            lineEndInfo!.lineNumber,
            lineEndInfo.columnNumber,
          ),
          'Fix this',
          'riverpod_imports',
          hasFix: false,
          url: compilationUnit.uri,
        );
        final fix = plugin.PrioritizedSourceChange(
            1000000,
            plugin.SourceChange(
              'Apply fixes for riverpod.',
              edits: [],
            ));
        result[err] = fix;
      } catch (e, st) {
        channel.sendNotification(
          plugin.PluginErrorParams(false, e.toString(), st.toString())
              .toNotification(),
        );
      }
    }
    return result;
  }
}
