import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/material.dart';

class A extends StateNotifier<int> {
  A() : super(0);
}

final a = StateNotifierProvider((ref) => A());

class ConsumerExample extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetReference ref) {
    final A value = ref.watch(a);
    return Column(
      children: [
        Text('$value'),
        ElevatedButton(
          onPressed: () {
            ref.read(a);
            ref.refresh(a);
          },
          child: const Text('Button'),
        )
      ],
    );
  }
}

class StatelessExample extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetReference ref) {
    return Column(
      children: [
        ElevatedButton(
          onPressed: () {
            context.read(a);
            context.refresh(a);
          },
          child: const Text('Button'),
        )
      ],
    );
  }
}

class StatefulExample extends StatefulWidget {
  StatefulExample({Key key}) : super(key: key);

  @override
  _StatefulExampleState createState() => _StatefulExampleState();
}

class _StatefulExampleState extends State<StatefulExample> {
  @override
  Widget build(BuildContext context) {
    return Consumer(
      builder: (context, ref, child) => Text('${ref.watch(a)}'),
    );
  }
}
