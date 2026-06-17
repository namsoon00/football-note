import 'package:flutter/widgets.dart';

import '../../application/sport_state_controller.dart';

class SportScope extends InheritedNotifier<SportStateController> {
  const SportScope({
    super.key,
    required SportStateController controller,
    required super.child,
  }) : super(notifier: controller);

  static SportStateController? maybeOf(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<SportScope>()?.notifier;
  }

  static SportStateController of(BuildContext context) {
    final controller = maybeOf(context);
    assert(controller != null, 'No SportScope found in context.');
    return controller!;
  }

  static SportStateController? read(BuildContext context) {
    final widget =
        context.getElementForInheritedWidgetOfExactType<SportScope>()?.widget;
    return widget is SportScope ? widget.notifier : null;
  }
}
