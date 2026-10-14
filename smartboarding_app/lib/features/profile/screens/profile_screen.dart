import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/errors/app_exception.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../../core/widgets/loading_filled_button.dart';
import '../../../core/widgets/snackbar_utils.dart';
import '../models/profile_update_model.dart';
import '../services/profile_service.dart';
import '../../membership/providers/membership_provider.dart';
import '../providers/me_provider.dart';
import 'student_card_screen.dart';
import '../widgets/address_card.dart';
import '../widgets/profile_form_fields.dart';
import '../widgets/profile_header_card.dart';
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

  final _campos = ProfileFormFields();

  ProfileUpdate? _pendente;
  bool _loading = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _campos.name.text = context.read<AuthProvider>().token?.fullName ?? '';
    _load();
  }

  @override
  void dispose() {
    _campos.dispose();
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

  bool _algoMudou(AuthProvider auth, Me? me) {
    if (ProfileFormFields.mudou(_campos.name, auth.token?.fullName) != null) {
      return true;
    }
    if (me == null) return false;
    if (ProfileFormFields.mudou(_campos.phone, me.phone) != null) return true;
    if (auth.isStudent &&
        ProfileFormFields.mudou(_campos.course, me.course) != null) {
      return true;
    }
    return _campos.enderecoMudou(me.address);
  }

  Future<void> _enviar(AuthProvider auth, Me? me) async {
    if (!_formKey.currentState!.validate()) return;
    if (!_algoMudou(auth, me)) return;

    setState(() => _saving = true);
    try {
      final p = await _service.requestUpdate(
        fullName: ProfileFormFields.mudou(_campos.name, auth.token?.fullName),
        phone: me == null
            ? null
            : ProfileFormFields.mudou(_campos.phone, me.phone),
        course: (me == null || !auth.isStudent)
            ? null
            : ProfileFormFields.mudou(_campos.course, me.course),
        address: (me != null && _campos.enderecoMudou(me.address))
            ? _campos.enderecoDigitado()
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
    if (me != null) _campos.preencherDe(me);

    return Scaffold(
      appBar: AppBar(title: const Text('Meu perfil')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(20),
              children: [
                ProfileHeaderCard(nome: nome, email: auth.token?.email ?? ''),
                const SizedBox(height: 20),
                const MyInstitutionsCard(),
                const SizedBox(height: 20),
                if (me != null && auth.isStudent) ...[
                  StudentCardLink(
                    onAbrir: () => Navigator.push<void>(
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
                  const SizedBox(height: 20),
                ],

                if (emAnalise) ...[
                  ProfileRequestStatus(
                    emAnalise: _pendente!.changes.entries
                        .map((e) => '${e.key}: ${e.value}')
                        .join(' · '),
                  ),
                  const SizedBox(height: 20),
                ],

                if (_pendente?.rejected ?? false) ...[
                  ProfileRequestStatus(
                    motivoDaRecusa: _pendente!.rejectionReason,
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
                        controller: _campos.name,
                        icon: Icons.person_outline,
                        readOnly: emAnalise,
                      ),
                      const SizedBox(height: 20),
                      if (me != null) ...[
                        OwnDataCard(
                          phoneCtrl: _campos.phone,
                          courseCtrl: _campos.course,
                          isStudent: auth.isStudent,
                          readOnly: emAnalise,
                        ),
                        const SizedBox(height: 20),
                        AddressCard(
                          cepCtrl: _campos.cep,
                          ruaCtrl: _campos.rua,
                          bairroCtrl: _campos.bairro,
                          cidadeCtrl: _campos.cidade,
                          ufCtrl: _campos.uf,
                          numeroCtrl: _campos.numero,
                          complementoCtrl: _campos.complemento,
                          readOnly: emAnalise,
                        ),
                        const SizedBox(height: 20),
                      ],
                      ListenableBuilder(
                        listenable: _campos.todos,
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
