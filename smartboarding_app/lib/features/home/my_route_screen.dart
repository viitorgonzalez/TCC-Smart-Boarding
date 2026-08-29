import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/widgets/async_builder.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/snackbar_utils.dart';
import '../lists/models/list_with_enrollment.dart';
import '../lists/providers/student_list_provider.dart';
import 'widgets/student_list_card.dart';

class MyRouteScreen extends StatelessWidget {
  const MyRouteScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Minha rota')),
      body: SafeArea(
        child: Consumer<StudentListProvider>(
          builder: (context, provider, _) => AsyncBuilder(
            value: provider.state,
            onRetry: provider.load,
            builder: (items) => RefreshIndicator(
              onRefresh: provider.load,
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  if (items.isEmpty)
                    const Padding(
                      padding: EdgeInsets.only(top: 60),
                      child: EmptyState(
                        icon: Icons.event_busy,
                        title: 'Nenhuma lista disponível hoje',
                      ),
                    )
                  else
                    ...items.map(
                      (item) => Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: StudentListCard(
                          item: item,
                          onEnter: (tripType) =>
                              _enter(context, provider, item, tripType),
                          onLeave: () => _leave(context, provider, item),
                        ),
                      ),
                    ),
                ],
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
      if (context.mounted) showErrorSnackBar(context, e.toString());
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
      if (context.mounted) showErrorSnackBar(context, e.toString());
    }
  }
}
