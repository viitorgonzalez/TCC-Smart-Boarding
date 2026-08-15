import 'package:flutter/material.dart';
import '../utils/async_value.dart';
import 'error_state.dart';

class AsyncBuilder<T> extends StatelessWidget {
  final AsyncValue<T> value;
  final Widget Function(T data) builder;
  final Widget? loading;
  final VoidCallback? onRetry;

  const AsyncBuilder({
    super.key,
    required this.value,
    required this.builder,
    this.loading,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return switch (value) {
      AsyncLoading() =>
        loading ?? const Center(child: CircularProgressIndicator()),
      AsyncError(:final message) => ErrorState(
        message: message,
        onRetry: onRetry,
      ),
      AsyncData(:final value) => builder(value),
    };
  }
}
