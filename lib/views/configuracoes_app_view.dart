// configuracoes_app_view.dart
// Painel de configurações do app — acessível apenas para admins.
// Controla manutenção por plataforma via Firestore (configuracoes/app).

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class ConfiguracoesAppView extends StatelessWidget {
  const ConfiguracoesAppView({super.key});

  static const _docRef = 'settings/app';

  DocumentReference<Map<String, dynamic>> get _doc =>
      FirebaseFirestore.instance.doc(_docRef);

  Future<void> _setManutencao(
    BuildContext context,
    String campo,
    bool novoValor,
    String plataforma,
  ) async {
    if (novoValor) {
      final confirmar = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Ativar manutenção?'),
          content: Text(
            'Tem certeza que deseja colocar o app em manutenção para $plataforma? '
            'Os usuários não conseguirão acessar o app.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFFBF1921),
              ),
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Ativar'),
            ),
          ],
        ),
      );
      if (confirmar != true) return;
    }

    await _doc.set(
      {campo: novoValor},
      SetOptions(merge: true),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Configurações do App')),
      body: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        stream: _doc.snapshots(),
        builder: (context, snap) {
          final data = snap.data?.data() ?? {};
          final emManutencaoIOS = data['emManutencaoIOS'] as bool? ?? false;
          final emManutencaoAndroid =
              data['emManutencaoAndroid'] as bool? ?? false;

          return ListView(
            children: [
              const SizedBox(height: 8),
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Text(
                  'Controle de Manutenção',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        color: Colors.black54,
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ),
              SwitchListTile(
                secondary: Icon(
                  Icons.phone_iphone_rounded,
                  color: emManutencaoIOS
                      ? const Color(0xFFBF1921)
                      : Colors.black54,
                ),
                title: const Text('Manutenção iOS'),
                subtitle: Text(
                  emManutencaoIOS
                      ? 'Usuários iOS estão bloqueados'
                      : 'iOS operando normalmente',
                  style: TextStyle(
                    color:
                        emManutencaoIOS ? const Color(0xFFBF1921) : null,
                  ),
                ),
                value: emManutencaoIOS,
                activeThumbColor: const Color(0xFFBF1921),
                onChanged: (v) => _setManutencao(
                  context,
                  'emManutencaoIOS',
                  v,
                  'iOS',
                ),
              ),
              const Divider(height: 1, indent: 16, endIndent: 16),
              SwitchListTile(
                secondary: Icon(
                  Icons.android_rounded,
                  color: emManutencaoAndroid
                      ? const Color(0xFFBF1921)
                      : Colors.black54,
                ),
                title: const Text('Manutenção Android'),
                subtitle: Text(
                  emManutencaoAndroid
                      ? 'Usuários Android estão bloqueados'
                      : 'Android operando normalmente',
                  style: TextStyle(
                    color:
                        emManutencaoAndroid ? const Color(0xFFBF1921) : null,
                  ),
                ),
                value: emManutencaoAndroid,
                activeThumbColor: const Color(0xFFBF1921),
                onChanged: (v) => _setManutencao(
                  context,
                  'emManutencaoAndroid',
                  v,
                  'Android',
                ),
              ),
              const Divider(height: 1, indent: 16, endIndent: 16),
              if (emManutencaoIOS || emManutencaoAndroid)
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFBF1921).withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.warning_amber_rounded,
                            color: Color(0xFFBF1921)),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'O app está em manutenção em '
                            '${[
                              if (emManutencaoIOS) 'iOS',
                              if (emManutencaoAndroid) 'Android',
                            ].join(' e ')}.',
                            style: const TextStyle(
                              color: Color(0xFFBF1921),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}
