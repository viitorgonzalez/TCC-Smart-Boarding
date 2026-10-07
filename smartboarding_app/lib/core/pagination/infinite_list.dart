import 'package:flutter/material.dart';

class InfiniteList extends StatelessWidget {
  final List<Widget> children;

  final bool hasMore;

  final VoidCallback onLoadMore;

  final EdgeInsetsGeometry padding;

  const InfiniteList({
    super.key,
    required this.children,
    required this.hasMore,
    required this.onLoadMore,
    this.padding = const EdgeInsets.fromLTRB(20, 20, 20, 96),
  });

  @override
  Widget build(BuildContext context) {
    return NotificationListener<ScrollNotification>(
      onNotification: (n) {
        if (hasMore && n.metrics.extentAfter < 400) onLoadMore();
        return false;
      },
      child: ListView(
        padding: padding,
        children: [
          ...children,
          if (hasMore)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Center(child: CircularProgressIndicator()),
            ),
        ],
      ),
    );
  }
}
