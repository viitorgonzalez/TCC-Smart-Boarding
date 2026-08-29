import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/errors/app_exception.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../../core/widgets/loading_filled_button.dart';
import '../../../core/widgets/snackbar_utils.dart';
import '../../../core/utils/async_value.dart';
import '../../routes/models/route_model.dart';
import '../../routes/providers/route_provider.dart';
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

  /// Nulo = sem prazo. Presets em vez de campo livre: o admin pensa em "quanto
  /// tempo isso importa", não em data e hora exatas.
  int? _durationHours = 24;
  String? _routeId;

  static const _durations = <({String label, int? hours})>[
    (label: '1 hora', hours: 1),
    (label: '6 horas', hours: 6),
    (label: '24 horas', hours: 24),
    (label: '3 dias', hours: 72),
    (label: '7 dias', hours: 168),
    (label: 'Sem prazo', hours: null),
  ];

  @override
  void dispose() {
    _titleCtrl.dispose();
    _bodyCtrl.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    if (!_formKey.currentState!.validate()) return;
    final routeId = _routeId;
    if (routeId == null) {
      showErrorSnackBar(context, 'Escolha a rota que vai receber o aviso.');
      return;
    }
    try {
      await context.read<NotificationProvider>().broadcast(
        _titleCtrl.text.trim(),
        _bodyCtrl.text.trim(),
        routeId: routeId,
        durationHours: _durationHours,
      );
      if (!mounted) return;
      _titleCtrl.clear();
      _bodyCtrl.clear();
      showSuccessSnackBar(context, 'Aviso enviado');
    } catch (e) {
      if (mounted) showErrorSnackBar(context, AppException.fromError(e));
    }
  }

  @override
  Widget build(BuildContext context) {
    final isSending = context.watch<NotificationProvider>().isSending;
    final routes = switch (context.watch<RouteProvider>().state) {
      AsyncData(:final value) => value.where((r) => r.isActive).toList(),
      _ => const <RouteModel>[],
    };
    // Com uma rota só, escolher é cerimônia — já vem marcada.
    if (_routeId == null && routes.length == 1) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) setState(() => _routeId = routes.first.id);
      });
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  AppTextField(
                    label: 'Título',
                    controller: _titleCtrl,
                    icon: Icons.campaign_outlined,
                    hint: 'Ex.: Atraso na saída',
                    maxLength: 150,
                    validator: (v) => (v == null || v.trim().isEmpty)
                        ? 'Informe o título'
                        : null,
                  ),
                  const SizedBox(height: 16),
                  AppTextField(
                    label: 'Mensagem',
                    controller: _bodyCtrl,
                    maxLines: 4,
                    hint: 'O que o aluno precisa saber',
                    validator: (v) => (v == null || v.trim().isEmpty)
                        ? 'Informe a mensagem'
                        : null,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            const SectionTitle('Rota'),
            const SizedBox(height: 4),
            Text(
              'O aviso vai para quem pega essa rota.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 10),
            AppCard(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              child: RadioGroup<String?>(
                groupValue: _routeId,
                onChanged: (v) => setState(() => _routeId = v),
                child: Column(
                  children: [
                    for (final route in routes)
                      RadioListTile<String?>(
                        contentPadding: EdgeInsets.zero,
                        value: route.id,
                        title: Text(route.name),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            const SectionTitle('Por quanto tempo fica válido'),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final d in _durations)
                  ChoiceChip(
                    label: Text(d.label),
                    selected: _durationHours == d.hours,
                    onSelected: (_) => setState(() => _durationHours = d.hours),
                    showCheckmark: false,
                    selectedColor: AppColors.deepTeal,
                    backgroundColor: AppColors.surface,
                    side: const BorderSide(color: AppColors.stroke),
                    labelStyle: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: _durationHours == d.hours
                          ? Colors.white
                          : AppColors.charcoal,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              _durationHours == null
                  ? 'O aviso fica na caixa de entrada indefinidamente.'
                  : 'Depois desse prazo o aviso some da caixa dos alunos.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 24),
            LoadingFilledButton(
              loading: isSending,
              onPressed: _send,
              label: 'Enviar aviso',
            ),
          ],
        ),
      ),
    );
  }
}
