// ignore: deprecated_member_use
import 'package:analyzer/analyzer.dart';
import 'package:codemod/codemod.dart';

class RiverpodImportAllMigrationSuggestor extends GeneralizingAstVisitor
    with AstVisitingSuggestorMixin {
  @override
  void visitImportDirective(ImportDirective node) async {
    final imports = {
      'package:riverpod/all.dart': 'package:riverpod/riverpod.dart',
      'package:flutter_riverpod/all.dart':
          'package:flutter_riverpod/flutter_riverpod.dart',
      'package:hooks_riverpod/all.dart':
          'package:hooks_riverpod/hooks_riverpod.dart'
    };
    for (final entry in imports.entries) {
      if (entry.key == node.uri.stringValue) {
        yieldPatch(node.uri.offset + 1, node.uri.end - 1, entry.value);
      }
    }
  }
}