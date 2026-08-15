import 'package:flutter/material.dart';
import '../models/trip_type.dart';

class TripTypeChip extends StatelessWidget {
  final String? tripType;
  final double iconSize;

  const TripTypeChip({super.key, required this.tripType, this.iconSize = 16});

  @override
  Widget build(BuildContext context) {
    final info = tripTypeInfo(tripType);
    return Chip(
      avatar: Icon(info.icon, size: iconSize),
      label: Text(info.label),
      visualDensity: VisualDensity.compact,
    );
  }
}
