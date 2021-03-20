import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:riverpod/riverpod.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final counterProvider = StateProvider((ref) => 1);

final otherProvider = Provider((ref) {
  ref.read(counterProvider);
  ref.read(counterProvider).state;
  return ref.watch(counterProvider).state;
});

class ConsumerWatch extends ConsumerWidget {
  const ConsumerWatch({Key key}) : super(key: key);

  @override
  Widget build(BuildContext context, ScopedReader watch) {
    final countNotifier = watch(counterProvider);
    final count = watch(counterProvider).state;
    return Center(
      child: Text('$count'),
    );
  }
}

class HooksWatch extends HookWidget {
  const HooksWatch({Key key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final countNotifier = useProvider(counterProvider);
    final count = useProvider(counterProvider).state;
    return Center(
      child: ElevatedButton(
        onPressed: () {
          context.read(counterProvider);
          context.read(counterProvider).state;
        },
        child: const Text('Press Me'),
      ),
    );
  }
}
