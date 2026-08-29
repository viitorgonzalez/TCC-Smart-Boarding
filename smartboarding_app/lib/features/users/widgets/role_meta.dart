import 'package:flutter/material.dart';
import '../models/user_model.dart';

const roleHierarchy = ['ADMIN', 'STUDENT'];

class RoleMeta {
  final String singular;
  final String plural;
  final IconData icon;
  const RoleMeta(this.singular, this.plural, this.icon);
}

const _roleMeta = <String, RoleMeta>{
  'ADMIN': RoleMeta(
    'Administrador',
    'Administradores',
    Icons.admin_panel_settings,
  ),
  'STUDENT': RoleMeta('Aluno', 'Alunos', Icons.school),
};

RoleMeta metaFor(String role) =>
    _roleMeta[role] ?? const RoleMeta('Usuário', 'Usuários', Icons.person);

List<UserModel> sortUsersByName(Iterable<UserModel> users) {
  final list = users.toList();
  list.sort(
    (a, b) => a.fullName.toLowerCase().compareTo(b.fullName.toLowerCase()),
  );
  return list;
}
