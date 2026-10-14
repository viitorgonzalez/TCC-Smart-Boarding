import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/app_text_field.dart';

class OwnDataCard extends StatelessWidget {
  final TextEditingController phoneCtrl;
  final TextEditingController courseCtrl;
  final bool isStudent;
  final bool readOnly;

  const OwnDataCard({
    super.key,
    required this.phoneCtrl,
    required this.courseCtrl,
    required this.isStudent,
    this.readOnly = false,
  });

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Seus dados', style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 4),
          Text(
            'O telefone é o único contato direto no dia da viagem.',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 16),

          AppTextField(
            key: const Key('own_data_phone_field'),
            label: 'Telefone',
            controller: phoneCtrl,
            icon: Icons.phone_outlined,
            keyboardType: TextInputType.phone,
            readOnly: readOnly,
          ),
          if (isStudent) ...[
            const SizedBox(height: 12),
            AppTextField(
              key: const Key('own_data_course_field'),
              label: 'Curso',
              controller: courseCtrl,
              icon: Icons.school_outlined,
              hint: 'Opcional',
              readOnly: readOnly,
            ),
          ],

          ListenableBuilder(
            listenable: phoneCtrl,
            builder: (context, _) {
              if (phoneCtrl.text.trim().isNotEmpty) {
                return const SizedBox.shrink();
              }
              return Padding(
                padding: const EdgeInsets.only(top: 14),
                child: Row(
                  key: const Key('own_data_missing_warning'),
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      size: 18,
                      color: AppColors.danger,
                    ),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text(
                        'Falta preencher: Telefone. '
                        'Sem isso você não consegue entrar na lista.',
                        style: TextStyle(color: AppColors.danger),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
