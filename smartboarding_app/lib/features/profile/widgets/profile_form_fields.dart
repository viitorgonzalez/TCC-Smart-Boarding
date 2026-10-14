import 'package:flutter/widgets.dart';

import '../models/address_model.dart';
import '../models/profile_update_model.dart';

/// Os campos do formulário de perfil, com o ciclo de vida junto.
///
/// Nove controllers, o merge que escuta todos, o preenchimento inicial e a
/// comparação com o que está salvo são o mesmo assunto — e ocupavam metade da
/// tela. Aqui eles ficam onde dá pra ler a regra: o que conta como "mudou", e
/// o que vira `Address` no envio.
class ProfileFormFields {
  final name = TextEditingController();
  final phone = TextEditingController();
  final course = TextEditingController();
  final cep = TextEditingController();
  final rua = TextEditingController();
  final bairro = TextEditingController();
  final cidade = TextEditingController();
  final uf = TextEditingController();
  final numero = TextEditingController();
  final complemento = TextEditingController();

  late final Listenable todos = Listenable.merge([
    name,
    phone,
    course,
    cep,
    rua,
    bairro,
    cidade,
    uf,
    numero,
    complemento,
  ]);

  bool _preenchido = false;

  /// Só na primeira vez: repetir sobrescreveria o que a pessoa já digitou toda
  /// vez que o `/me` recarregasse.
  void preencherDe(Me me) {
    if (_preenchido) return;
    _preenchido = true;
    phone.text = me.phone ?? '';
    course.text = me.course ?? '';
    cep.text = me.address.zipCode ?? '';
    rua.text = me.address.street ?? '';
    bairro.text = me.address.neighborhood ?? '';
    cidade.text = me.address.city ?? '';
    uf.text = me.address.state ?? '';
    numero.text = me.address.streetNumber ?? '';
    complemento.text = me.address.complement ?? '';
  }

  void dispose() {
    for (final c in [
      name,
      phone,
      course,
      cep,
      rua,
      bairro,
      cidade,
      uf,
      numero,
      complemento,
    ]) {
      c.dispose();
    }
  }

  static String? texto(TextEditingController c) {
    final t = c.text.trim();
    return t.isEmpty ? null : t;
  }

  /// Nulo quando não mudou OU quando esvaziou: apagar um campo não é pedido de
  /// alteração, é campo em branco — e mandá-lo apagaria o dado que está lá.
  static String? mudou(TextEditingController ctrl, String? atual) {
    final novo = ctrl.text.trim();
    if (novo.isEmpty || novo == (atual ?? '')) return null;
    return novo;
  }

  bool enderecoMudou(Address atual) =>
      texto(cep) != atual.zipCode ||
      texto(rua) != atual.street ||
      texto(bairro) != atual.neighborhood ||
      texto(cidade) != atual.city ||
      texto(uf) != atual.state ||
      texto(numero) != atual.streetNumber ||
      texto(complemento) != atual.complement;

  Address enderecoDigitado() => Address(
    zipCode: texto(cep),
    street: texto(rua),
    neighborhood: texto(bairro),
    city: texto(cidade),
    state: texto(uf),
    streetNumber: texto(numero),
    complement: texto(complemento),
  );
}
