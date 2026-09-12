import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/errors/app_exception.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../../core/widgets/initials_avatar.dart';
import '../../../core/widgets/loading_filled_button.dart';
import '../../../core/widgets/snackbar_utils.dart';
import '../models/profile_update_model.dart';
import '../services/profile_service.dart';
import '../widgets/my_institutions_card.dart';
import '../widgets/set_password_card.dart';

/// Perfil do próprio usuário.
///
/// O admin edita direto; o aluno envia solicitação e o admin decide. Nome e
/// instituição do aluno decidem em que lista ele aparece, então mudá-los sozinho
/// abriria caminho pra entrar em transporte que não é o dele.
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _service = ProfileService();
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  final _courseCtrl = TextEditingController();

  ProfileUpdate? _pendente;
  Me? _me;
  bool _loading = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _nameCtrl.text = context.read<AuthProvider>().token?.fullName ?? '';
    _load();
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _addressCtrl.dispose();
    _courseCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    // Em catch proprio: o /me so decide se o card de senha aparece. Se ele
    // falhar, o perfil inteiro ainda tem que abrir.
    _service
        .me()
        .then((m) {
          if (mounted) setState(() => _me = m);
        })
        .catchError((_) {});
    try {
      final ultimo = await _service.myLatest();
      if (mounted) setState(() => _pendente = ultimo);
    } catch (e) {
      if (mounted) showErrorSnackBar(context, AppException.fromError(e));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  /// Só o que mudou vai no pedido: mandar tudo faria o admin revisar campos que
  /// o aluno nem tocou.
  String? _mudou(TextEditingController ctrl, String? atual) {
    final novo = ctrl.text.trim();
    if (novo.isEmpty || novo == (atual ?? '')) return null;
    return novo;
  }

  Future<void> _enviar() async {
    if (!_formKey.currentState!.validate()) return;
    final auth = context.read<AuthProvider>();
    final nome = _mudou(_nameCtrl, auth.token?.fullName);
    final telefone = _mudou(_phoneCtrl, null);
    final endereco = _mudou(_addressCtrl, null);
    final curso = _mudou(_courseCtrl, null);

    if (nome == null && telefone == null && endereco == null && curso == null) {
      showErrorSnackBar(context, 'Altere ao menos um campo antes de enviar.');
      return;
    }

    setState(() => _saving = true);
    try {
      final p = await _service.requestUpdate(
        fullName: nome,
        phone: telefone,
        address: endereco,
        course: curso,
      );
      if (!mounted) return;
      setState(() => _pendente = p);
      showSuccessSnackBar(context, 'Solicitação enviada para o administrador');
    } catch (e) {
      if (mounted) showErrorSnackBar(context, AppException.fromError(e));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final nome = auth.token?.fullName ?? '';
    final emAnalise = _pendente?.pending ?? false;

    return Scaffold(
      appBar: AppBar(title: const Text('Meu perfil')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(20),
              children: [
                AppCard(
                  child: Row(
                    children: [
                      InitialsAvatar(
                        text: nome.isNotEmpty ? nome[0].toUpperCase() : '?',
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              nome,
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            Text(
                              auth.token?.email ?? '',
                              style: const TextStyle(
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                // Fica ACIMA do formulario: sem instituicao o aluno nao entra em
                // rota nenhuma, entao e a primeira coisa que ele precisa
                // resolver ao abrir o perfil.
                const MyInstitutionsCard(),
                const SizedBox(height: 20),
                // So pra quem entrou pelo Google e ainda nao tem senha: oferecer
                // a todos faria metade tomar 409 do backend.
                if (_me case Me(hasPassword: false, hasGoogle: true)) ...[
                  SetPasswordCard(onCreated: _load),
                  const SizedBox(height: 20),
                ],

                if (emAnalise) ...[
                  AppCard(
                    child: Row(
                      children: [
                        const Icon(
                          Icons.hourglass_top,
                          color: AppColors.deepTeal,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Solicitação em análise',
                                style: TextStyle(fontWeight: FontWeight.w700),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _pendente!.changes.entries
                                    .map((e) => '${e.key}: ${e.value}')
                                    .join(' · '),
                                style: const TextStyle(
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                ],

                if (_pendente?.rejected ?? false) ...[
                  AppCard(
                    child: Row(
                      children: [
                        const Icon(
                          Icons.cancel_outlined,
                          color: AppColors.danger,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Pedido recusado: '
                            '${_pendente!.rejectionReason ?? "sem motivo informado"}',
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                ],

                Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      AppTextField(
                        key: const Key('profile_name_field'),
                        label: 'Nome completo',
                        controller: _nameCtrl,
                        icon: Icons.person_outline,
                        readOnly: emAnalise,
                      ),
                      const SizedBox(height: 16),
                      AppTextField(
                        key: const Key('profile_phone_field'),
                        label: 'Telefone',
                        controller: _phoneCtrl,
                        icon: Icons.phone_outlined,
                        keyboardType: TextInputType.phone,
                        readOnly: emAnalise,
                      ),
                      const SizedBox(height: 16),
                      AppTextField(
                        key: const Key('profile_address_field'),
                        label: 'Endereço',
                        controller: _addressCtrl,
                        icon: Icons.place_outlined,
                        readOnly: emAnalise,
                      ),
                      const SizedBox(height: 16),
                      AppTextField(
                        key: const Key('profile_course_field'),
                        label: 'Curso',
                        controller: _courseCtrl,
                        icon: Icons.school_outlined,
                        readOnly: emAnalise,
                      ),
                      const SizedBox(height: 24),
                      // Campo travado durante a analise: deixar editavel sugere
                      // que da pra enviar outro, e o backend recusa com 409.
                      LoadingFilledButton(
                        key: const Key('profile_submit_button'),
                        loading: _saving,
                        onPressed: emAnalise ? null : _enviar,
                        label: emAnalise
                            ? 'Aguardando análise'
                            : 'Enviar para aprovação',
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}
