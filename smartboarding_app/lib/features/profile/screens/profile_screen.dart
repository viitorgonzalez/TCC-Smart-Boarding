import 'dart:async';

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
import '../models/address_model.dart';
import '../models/profile_update_model.dart';
import '../services/profile_service.dart';
import '../../membership/providers/membership_provider.dart';
import '../providers/me_provider.dart';
import 'student_card_screen.dart';
import '../widgets/address_card.dart';
import '../widgets/email_card.dart';
import '../widgets/my_institutions_card.dart';
import '../widgets/own_data_card.dart';
import '../widgets/password_card.dart';

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
  final _courseCtrl = TextEditingController();
  final _cepCtrl = TextEditingController();
  final _ruaCtrl = TextEditingController();
  final _bairroCtrl = TextEditingController();
  final _cidadeCtrl = TextEditingController();
  final _ufCtrl = TextEditingController();
  final _numeroCtrl = TextEditingController();
  final _complementoCtrl = TextEditingController();
  late final _todosCtrls = Listenable.merge([
    _nameCtrl,
    _phoneCtrl,
    _courseCtrl,
    _cepCtrl,
    _ruaCtrl,
    _bairroCtrl,
    _cidadeCtrl,
    _ufCtrl,
    _numeroCtrl,
    _complementoCtrl,
  ]);

  ProfileUpdate? _pendente;
  bool _loading = true;
  bool _saving = false;
  bool _preenchidoDoMe = false;

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
    _courseCtrl.dispose();
    _cepCtrl.dispose();
    _ruaCtrl.dispose();
    _bairroCtrl.dispose();
    _cidadeCtrl.dispose();
    _ufCtrl.dispose();
    _numeroCtrl.dispose();
    _complementoCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    unawaited(context.read<MeProvider>().load());
    try {
      final ultimo = await _service.myLatest();
      if (mounted) setState(() => _pendente = ultimo);
    } catch (e) {
      if (mounted) showErrorSnackBar(context, AppException.fromError(e));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _emailAlterado(AuthProvider auth) async {
    await auth.logout();
    if (mounted) {
      showSuccessSnackBar(
        context,
        'E-mail alterado. Faça login de novo com o e-mail novo.',
      );
    }
  }

  void _preencherDoMe(Me me) {
    if (_preenchidoDoMe) return;
    _preenchidoDoMe = true;
    _phoneCtrl.text = me.phone ?? '';
    _courseCtrl.text = me.course ?? '';
    _cepCtrl.text = me.address.zipCode ?? '';
    _ruaCtrl.text = me.address.street ?? '';
    _bairroCtrl.text = me.address.neighborhood ?? '';
    _cidadeCtrl.text = me.address.city ?? '';
    _ufCtrl.text = me.address.state ?? '';
    _numeroCtrl.text = me.address.streetNumber ?? '';
    _complementoCtrl.text = me.address.complement ?? '';
  }

  static String? _texto(TextEditingController c) {
    final t = c.text.trim();
    return t.isEmpty ? null : t;
  }

  String? _mudouTexto(TextEditingController ctrl, String? atual) {
    final novo = ctrl.text.trim();
    if (novo.isEmpty || novo == (atual ?? '')) return null;
    return novo;
  }

  bool _enderecoMudou(Address atual) =>
      _texto(_cepCtrl) != atual.zipCode ||
      _texto(_ruaCtrl) != atual.street ||
      _texto(_bairroCtrl) != atual.neighborhood ||
      _texto(_cidadeCtrl) != atual.city ||
      _texto(_ufCtrl) != atual.state ||
      _texto(_numeroCtrl) != atual.streetNumber ||
      _texto(_complementoCtrl) != atual.complement;

  bool _algoMudou(AuthProvider auth, Me? me) {
    if (_mudouTexto(_nameCtrl, auth.token?.fullName) != null) return true;
    if (me == null) return false;
    if (_mudouTexto(_phoneCtrl, me.phone) != null) return true;
    if (auth.isStudent && _mudouTexto(_courseCtrl, me.course) != null) {
      return true;
    }
    return _enderecoMudou(me.address);
  }

  Future<void> _enviar(AuthProvider auth, Me? me) async {
    if (!_formKey.currentState!.validate()) return;
    if (!_algoMudou(auth, me)) return;

    setState(() => _saving = true);
    try {
      final p = await _service.requestUpdate(
        fullName: _mudouTexto(_nameCtrl, auth.token?.fullName),
        phone: me == null ? null : _mudouTexto(_phoneCtrl, me.phone),
        course: (me == null || !auth.isStudent)
            ? null
            : _mudouTexto(_courseCtrl, me.course),
        address: (me != null && _enderecoMudou(me.address))
            ? Address(
                zipCode: _texto(_cepCtrl),
                street: _texto(_ruaCtrl),
                neighborhood: _texto(_bairroCtrl),
                city: _texto(_cidadeCtrl),
                state: _texto(_ufCtrl),
                streetNumber: _texto(_numeroCtrl),
                complement: _texto(_complementoCtrl),
              )
            : null,
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
    final me = context.watch<MeProvider>().me;
    if (me != null) _preencherDoMe(me);

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
                const MyInstitutionsCard(),
                const SizedBox(height: 20),
                if (me != null && auth.isStudent) ...[
                  AppCard(
                    child: ListTile(
                      key: const Key('profile_open_student_card'),
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(
                        Icons.badge_outlined,
                        color: AppColors.deepTeal,
                      ),
                      title: const Text('Carteirinha'),
                      subtitle: const Text(
                        'Seus dados de estudante, pra mostrar na conferência',
                      ),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => Navigator.push<void>(
                        context,
                        MaterialPageRoute(
                          builder: (_) => StudentCardScreen(
                            me: me,
                            hasActiveRoute: context
                                .read<MembershipProvider>()
                                .routes
                                .isNotEmpty,
                          ),
                        ),
                      ),
                    ),
                  ),
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
                      const SizedBox(height: 20),
                      if (me != null) ...[
                        OwnDataCard(
                          phoneCtrl: _phoneCtrl,
                          courseCtrl: _courseCtrl,
                          isStudent: auth.isStudent,
                          readOnly: emAnalise,
                        ),
                        const SizedBox(height: 20),
                        AddressCard(
                          cepCtrl: _cepCtrl,
                          ruaCtrl: _ruaCtrl,
                          bairroCtrl: _bairroCtrl,
                          cidadeCtrl: _cidadeCtrl,
                          ufCtrl: _ufCtrl,
                          numeroCtrl: _numeroCtrl,
                          complementoCtrl: _complementoCtrl,
                          readOnly: emAnalise,
                        ),
                        const SizedBox(height: 20),
                      ],
                      ListenableBuilder(
                        listenable: _todosCtrls,
                        builder: (context, _) {
                          final podeEnviar = !emAnalise && _algoMudou(auth, me);
                          return LoadingFilledButton(
                            key: const Key('profile_submit_button'),
                            loading: _saving,
                            onPressed: podeEnviar
                                ? () => _enviar(auth, me)
                                : null,
                            label: emAnalise
                                ? 'Aguardando análise'
                                : 'Enviar para aprovação',
                          );
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                if (me != null) ...[
                  EmailCard(
                    currentEmail: me.email,
                    onChanged: () => _emailAlterado(auth),
                  ),
                  const SizedBox(height: 20),
                  PasswordCard(changing: me.hasPassword, onSaved: _load),
                  const SizedBox(height: 20),
                ],
              ],
            ),
    );
  }
}
