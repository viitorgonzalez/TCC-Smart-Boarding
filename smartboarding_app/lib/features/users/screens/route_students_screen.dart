import 'package:flutter/material.dart';
import '../../../core/errors/app_exception.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/initials_avatar.dart';
import '../../../core/widgets/student_sheet.dart';
import '../models/user_model.dart';
import '../services/user_service.dart';
import '../widgets/role_meta.dart';

/// Todos os alunos atendidos por uma rota. Escopado por rota de propósito: a
/// base de usuários cresce sem teto, e o admin trabalha sobre uma rota por vez.
class RouteStudentsScreen extends StatefulWidget {
  final String routeId;
  final String routeName;

  const RouteStudentsScreen({
    super.key,
    required this.routeId,
    required this.routeName,
  });

  @override
  State<RouteStudentsScreen> createState() => _RouteStudentsScreenState();
}

class _RouteStudentsScreenState extends State<RouteStudentsScreen> {
  late Future<List<UserModel>> _future;
  String _query = '';

  @override
  void initState() {
    super.initState();
    _future = UserService().getUsers(routeId: widget.routeId);
  }

  Future<void> _reload() async {
    setState(() {
      _future = UserService().getUsers(routeId: widget.routeId);
    });
    await _future;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Alunos da rota'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(64),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: TextField(
              onChanged: (v) => setState(() => _query = v.toLowerCase()),
              decoration: const InputDecoration(
                hintText: 'Buscar por nome ou e-mail',
                prefixIcon: Icon(Icons.search),
              ),
            ),
          ),
        ),
      ),
      body: SafeArea(
        child: FutureBuilder<List<UserModel>>(
          future: _future,
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return Center(
                child: Text(AppException.fromError(snapshot.error!)),
              );
            }
            final all = sortUsersByName(
              (snapshot.data ?? const <UserModel>[]).where(
                (u) => u.role == 'STUDENT',
              ),
            );
            final users = _query.isEmpty
                ? all
                : all
                      .where(
                        (u) =>
                            u.fullName.toLowerCase().contains(_query) ||
                            u.email.toLowerCase().contains(_query),
                      )
                      .toList();

            if (users.isEmpty) {
              return RefreshIndicator(
                onRefresh: _reload,
                child: ListView(
                  children: [
                    const SizedBox(height: 100),
                    EmptyState(
                      icon: Icons.people_outline,
                      title: _query.isEmpty
                          ? 'Nenhum aluno nesta rota'
                          : 'Nenhum aluno encontrado',
                    ),
                  ],
                ),
              );
            }

            return RefreshIndicator(
              onRefresh: _reload,
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(vertical: 8),
                itemCount: users.length,
                separatorBuilder: (_, _) => const Divider(height: 1),
                itemBuilder: (_, i) {
                  final user = users[i];
                  return ListTile(
                    leading: InitialsAvatar(
                      text: user.fullName.isNotEmpty
                          ? user.fullName[0].toUpperCase()
                          : '?',
                    ),
                    onTap: () => showStudentProfile(context, user.id),
                    title: Text(user.fullName),
                    subtitle: Text(
                      user.institution == null
                          ? user.email
                          : '${user.email} · ${user.institution}',
                    ),
                    trailing: user.isActive
                        ? null
                        : const Icon(Icons.block, size: 18),
                  );
                },
              ),
            );
          },
        ),
      ),
    );
  }
}
