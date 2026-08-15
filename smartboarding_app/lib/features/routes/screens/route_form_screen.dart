import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/widgets/loading_filled_button.dart';
import '../../../core/widgets/snackbar_utils.dart';
import '../models/route_model.dart';
import '../providers/route_provider.dart';

class RouteFormScreen extends StatefulWidget {
  final RouteModel? route;
  const RouteFormScreen({super.key, this.route});

  @override
  State<RouteFormScreen> createState() => _RouteFormScreenState();
}

class _RouteFormScreenState extends State<RouteFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final _nameCtrl = TextEditingController(text: widget.route?.name ?? '');
  late final _descCtrl = TextEditingController(
    text: widget.route?.description ?? '',
  );
  bool _loading = false;

  bool get _isEdit => widget.route != null;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      final provider = context.read<RouteProvider>();
      if (_isEdit) {
        await provider.update(
          widget.route!.id,
          _nameCtrl.text.trim(),
          _descCtrl.text.trim(),
        );
      } else {
        await provider.create(_nameCtrl.text.trim(), _descCtrl.text.trim());
      }
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) showErrorSnackBar(context, e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_isEdit ? 'Editar Rota' : 'Nova Rota')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _nameCtrl,
                decoration: const InputDecoration(
                  labelText: 'Nome da rota',
                  prefixIcon: Icon(Icons.route),
                ),
                textCapitalization: TextCapitalization.words,
                validator: (v) =>
                    v?.trim().isEmpty == true ? 'Informe o nome' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descCtrl,
                decoration: const InputDecoration(
                  labelText: 'Descrição (opcional)',
                  prefixIcon: Icon(Icons.notes),
                  alignLabelWithHint: true,
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 24),
              LoadingFilledButton(
                loading: _loading,
                onPressed: _submit,
                label: _isEdit ? 'Salvar alterações' : 'Criar rota',
              ),
            ],
          ),
        ),
      ),
    );
  }
}
