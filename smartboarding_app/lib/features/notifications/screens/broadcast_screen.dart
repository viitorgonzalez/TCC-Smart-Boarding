import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/widgets/loading_filled_button.dart';
import '../../../core/widgets/snackbar_utils.dart';
import '../providers/notification_provider.dart';

class BroadcastScreen extends StatefulWidget {
  const BroadcastScreen({super.key});

  @override
  State<BroadcastScreen> createState() => _BroadcastScreenState();
}

class _BroadcastScreenState extends State<BroadcastScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleCtrl = TextEditingController();
  final _bodyCtrl = TextEditingController();

  @override
  void dispose() {
    _titleCtrl.dispose();
    _bodyCtrl.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    if (!_formKey.currentState!.validate()) return;
    try {
      await context.read<NotificationProvider>().broadcast(
        _titleCtrl.text.trim(),
        _bodyCtrl.text.trim(),
      );
      if (mounted) {
        _titleCtrl.clear();
        _bodyCtrl.clear();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Notificação enviada!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) showErrorSnackBar(context, e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    final isSending = context.watch<NotificationProvider>().isSending;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 8),
            const Text(
              'Enviar Notificação',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              'A mensagem será enviada para todos os estudantes.',
              style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
            ),
            const SizedBox(height: 24),
            TextFormField(
              controller: _titleCtrl,
              decoration: const InputDecoration(
                labelText: 'Título',
                prefixIcon: Icon(Icons.title),
              ),
              validator: (v) =>
                  v?.trim().isEmpty == true ? 'Informe o título' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _bodyCtrl,
              decoration: const InputDecoration(
                labelText: 'Mensagem',
                prefixIcon: Icon(Icons.message_outlined),
                alignLabelWithHint: true,
              ),
              maxLines: 5,
              validator: (v) =>
                  v?.trim().isEmpty == true ? 'Informe a mensagem' : null,
            ),
            const SizedBox(height: 24),
            LoadingFilledButton(
              loading: isSending,
              onPressed: _send,
              label: 'Enviar para todos',
              icon: Icons.send,
            ),
          ],
        ),
      ),
    );
  }
}
