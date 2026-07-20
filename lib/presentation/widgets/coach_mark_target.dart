import 'package:flutter/material.dart';

class CoachMarkTargetHandle {
  final GlobalKey key;
  Object? _owner;
  VoidCallback? _onActivate;

  CoachMarkTargetHandle({String? debugLabel})
      : key = GlobalKey(debugLabel: debugLabel);

  VoidCallback? get action => _onActivate;

  void attach(Object owner, VoidCallback? onActivate) {
    _owner = owner;
    _onActivate = onActivate;
  }

  void detach(Object owner) {
    if (!identical(_owner, owner)) return;
    _owner = null;
    _onActivate = null;
  }
}

class CoachMarkTarget extends StatefulWidget {
  final CoachMarkTargetHandle handle;
  final VoidCallback? onActivate;
  final Widget child;

  const CoachMarkTarget({
    super.key,
    required this.handle,
    required this.child,
    this.onActivate,
  });

  @override
  State<CoachMarkTarget> createState() => _CoachMarkTargetState();
}

class _CoachMarkTargetState extends State<CoachMarkTarget> {
  final Object _owner = Object();

  @override
  void initState() {
    super.initState();
    widget.handle.attach(_owner, widget.onActivate);
  }

  @override
  void didUpdateWidget(covariant CoachMarkTarget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.handle != widget.handle) {
      oldWidget.handle.detach(_owner);
    }
    widget.handle.attach(_owner, widget.onActivate);
  }

  @override
  void dispose() {
    widget.handle.detach(_owner);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return KeyedSubtree(key: widget.handle.key, child: widget.child);
  }
}
