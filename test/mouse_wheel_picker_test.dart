import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:payroll_app/widgets/mouse_wheel_picker.dart';

void main() {
  testWidgets('mouse wheel selects the next and previous values', (
    tester,
  ) async {
    var value = 2;
    const targetKey = Key('wheel-target');

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: StatefulBuilder(
            builder: (context, setState) => Center(
              child: MouseWheelPicker<int>(
                value: value,
                options: const [1, 2, 3],
                onChanged: (next) => setState(() => value = next),
                child: const SizedBox(key: targetKey, width: 160, height: 56),
              ),
            ),
          ),
        ),
      ),
    );

    final position = tester.getCenter(find.byKey(targetKey));
    await tester.sendEventToBinding(
      PointerScrollEvent(position: position, scrollDelta: const Offset(0, 20)),
    );
    await tester.pump();
    expect(value, 3);

    await tester.sendEventToBinding(
      PointerScrollEvent(position: position, scrollDelta: const Offset(0, -20)),
    );
    await tester.pump();
    expect(value, 2);
  });
}
