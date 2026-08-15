import 'package:flutter/material.dart';

class InitialsAvatar extends StatelessWidget {
  final String text;
  final double radius;

  const InitialsAvatar({super.key, required this.text, this.radius = 16});

  @override
  Widget build(BuildContext context) {
    return CircleAvatar(
      radius: radius,
      child: Text(text, style: const TextStyle(fontSize: 13)),
    );
  }
}
