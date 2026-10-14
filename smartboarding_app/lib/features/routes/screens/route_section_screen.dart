import 'package:flutter/material.dart';

class RouteSectionScreen extends StatelessWidget {
  final String title;
  final Widget child;

  const RouteSectionScreen({
    super.key,
    required this.title,
    required this.child,
  });

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text(title)),
    body: ListView(padding: const EdgeInsets.all(20), children: [child]),
  );
}
