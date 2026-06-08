import 'package:flutter/material.dart';

class ConstrainedScaffoldBody extends StatelessWidget {
  final double maxWidth;
  final Widget child;

  const ConstrainedScaffoldBody({
    super.key,
    required this.maxWidth,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: child,
      ),
    );
  }
}
