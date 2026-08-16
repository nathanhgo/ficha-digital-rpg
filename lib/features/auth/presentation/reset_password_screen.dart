import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'auth_controller.dart';
import '../../../core/theme/theme.dart';

/// Tela exibida quando o link de recuperação de senha do e-mail é aberto
/// (o Supabase já cria uma sessão temporária de recovery antes de chegar aqui).
class ResetPasswordScreen extends ConsumerStatefulWidget {
  const ResetPasswordScreen({super.key});

  @override
  ConsumerState<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends ConsumerState<ResetPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _submit() async {
    if (_formKey.currentState!.validate()) {
      final success = await ref.read(authControllerProvider.notifier).updatePassword(
            _passwordController.text.trim(),
          );
      if (!mounted) return;
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Senha atualizada com sucesso!'),
            backgroundColor: SteampunkTheme.copper,
          ),
        );
        context.go('/campaigns');
      } else {
        final error = ref.read(authControllerProvider).error ?? 'Erro desconhecido';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Não foi possível atualizar a senha: $error\nSolicite um novo link de recuperação.',
            ),
            backgroundColor: SteampunkTheme.bloodRed,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authControllerProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('NOVA SENHA'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        automaticallyImplyLeading: false,
      ),
      body: Container(
        decoration: const BoxDecoration(
          color: SteampunkTheme.leatherBark,
        ),
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.0),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Icon(Icons.password, color: SteampunkTheme.copper, size: 48),
                      const SizedBox(height: 16),
                      Text(
                        'Defina uma nova senha de acesso para sua conta.',
                        style: Theme.of(context).textTheme.bodyMedium,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 24),
                      TextFormField(
                        controller: _passwordController,
                        decoration: const InputDecoration(
                          labelText: 'Nova Senha',
                          prefixIcon: Icon(Icons.lock_outline, color: SteampunkTheme.copper),
                        ),
                        obscureText: true,
                        validator: (val) {
                          if (val == null || val.trim().length < 6) {
                            return 'A senha precisa ter no mínimo 6 caracteres';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _confirmPasswordController,
                        decoration: const InputDecoration(
                          labelText: 'Confirmar Nova Senha',
                          prefixIcon: Icon(Icons.lock_outline, color: SteampunkTheme.copper),
                        ),
                        obscureText: true,
                        validator: (val) {
                          if (val != _passwordController.text) {
                            return 'As senhas não coincidem';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 24),
                      if (authState.isLoading)
                        const Center(
                          child: CircularProgressIndicator(color: SteampunkTheme.copper),
                        )
                      else
                        ElevatedButton(
                          onPressed: _submit,
                          child: const Text('SALVAR NOVA SENHA'),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
