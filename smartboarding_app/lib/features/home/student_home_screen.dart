import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/providers/auth_provider.dart';
import '../../core/widgets/async_builder.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/snackbar_utils.dart';
import '../lists/models/list_with_enrollment.dart';
import '../lists/providers/student_list_provider.dart';
import 'widgets/student_list_card.dart';

class StudentHomeScreen extends StatelessWidget {
  const StudentHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final name = auth.token?.fullName ?? '';

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Smart Boarding'),
            if (name.isNotEmpty)
              Text(
                'Olá, $name',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.normal,
                ),
              ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => context.read<StudentListProvider>().load(),
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => auth.logout(),
          ),
        ],
      ),
      body: Consumer<StudentListProvider>(
        builder: (context, provider, _) => AsyncBuilder(
          value: provider.state,
          onRetry: provider.load,
          builder: (items) => items.isEmpty
              ? const EmptyState(
                  icon: Icons.event_busy,
                  title: 'Nenhuma lista disponível hoje',
                )
              : RefreshIndicator(
                  onRefresh: provider.load,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: items.length,
                    itemBuilder: (_, i) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: StudentListCard(
                        item: items[i],
                        onEnter: (tripType) =>
                            _enter(context, provider, items[i], tripType),
                        onLeave: () => _leave(context, provider, items[i]),
                      ),
                    ),
                  ),
                ),
        ),
      ),
    );
  }

  Future<void> _enter(
    BuildContext context,
    StudentListProvider provider,
    ListWithEnrollment item,
    String tripType,
  ) async {
    try {
      await provider.enter(item.list.id, tripType);
    } catch (e) {
      if (context.mounted) _showError(context, e);
    }
  }

  Future<void> _leave(
    BuildContext context,
    StudentListProvider provider,
    ListWithEnrollment item,
  ) async {
    try {
      await provider.leave(item.list.id);
    } catch (e) {
      if (context.mounted) _showError(context, e);
    }
  }

  void _showError(BuildContext context, Object e) {
    showErrorSnackBar(context, e.toString());
  }
}
