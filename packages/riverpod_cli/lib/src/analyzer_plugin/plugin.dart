import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/file_system/file_system.dart';
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

class RiverpodAnalysisPlugin extends ServerPlugin {
  RiverpodAnalysisPlugin(ResourceProvider? provider) : super(provider);

  final Checker checker = Checker();
  @override
  AnalysisDriverGeneric createAnalysisDriver(plugin.ContextRoot contextRoot) {
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
    dartDriver.results.listen(_processResult);
    return dartDriver;
  }

  @override
  List<String> get fileGlobsToAnalyze => <String>['**/*.dart'];

  @override
  String get name => 'riverpod analyzer';

  @override
  String get version => '0.0.1';

  /// Computes errors based on an analysis result and notifies the analyzer.
  // ignore: deprecated_member_use
  void _processResult(ResolvedUnitResult analysisResult) {
    // If there is no relevant analysis result, notify the analyzer of no errors.
    if (analysisResult.unit != null) {
      final checkResult = checker.check(analysisResult.libraryElement, channel);
      channel.sendNotification(plugin.AnalysisErrorsParams(
              analysisResult.path!, checkResult.keys.toList())
          .toNotification());
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
        final lineEndInfo = compilationUnit.lineInfo?.getLocation(error.uriEnd);

        final err = plugin.AnalysisError(
            plugin.AnalysisErrorSeverity.ERROR,
            plugin.AnalysisErrorType.LINT,
            plugin.Location(
              compilationUnit.source.fullName,
              error.uriOffset,
              error.uri!.length,
              lineInfo!.lineNumber,
              lineInfo.columnNumber,
              lineEndInfo!.lineNumber,
              lineEndInfo.columnNumber,
            ),
            'Fix this',
            'RIVERPOD_IMPORT_NEEDS_FIXES');
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
