import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'auth_controller.dart';
import '../../../core/theme/theme.dart';

class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  ConsumerState<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  bool _emailSent = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  void _submit() async {
    if (_formKey.currentState!.validate()) {
      final success = await ref.read(authControllerProvider.notifier).sendPasswordRecoveryEmail(
            _emailController.text.trim(),
          );
      if (!mounted) return;
      if (success) {
        // Por segurança, exibimos a mesma mensagem de sucesso independentemente
        // de o e-mail existir ou não na base (evita enumeração de contas).
        setState(() => _emailSent = true);
      } else {
        final error = ref.read(authControllerProvider).error ?? 'Erro desconhecido';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Falha ao enviar e-mail: $error'),
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
        title: const Text('RECUPERAR SENHA'),
        backgroundColor: Colors.transparent,
        elevation: 0,
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
                child: _emailSent ? _buildSuccessContent(context) : _buildFormContent(context, authState),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFormContent(BuildContext context, AuthStateData authState) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Icon(Icons.lock_reset, color: SteampunkTheme.copper, size: 48),
          const SizedBox(height: 16),
          Text(
            'Informe o e-mail cadastrado na sua conta. Enviaremos um link para você definir uma nova senha.',
            style: Theme.of(context).textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          TextFormField(
            controller: _emailController,
            decoration: const InputDecoration(
              labelText: 'Endereço de E-mail',
              prefixIcon: Icon(Icons.email_outlined, color: SteampunkTheme.copper),
            ),
            keyboardType: TextInputType.emailAddress,
            validator: (val) {
              if (val == null || val.trim().isEmpty) {
                return 'Por favor, insira seu e-mail';
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
              child: const Text('ENVIAR LINK DE RECUPERAÇÃO'),
            ),
        ],
      ),
    );
  }

  Widget _buildSuccessContent(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Icon(Icons.mark_email_read_outlined, color: SteampunkTheme.copper, size: 48),
        const SizedBox(height: 16),
        Text(
          'Se esse e-mail estiver cadastrado, você receberá em breve uma mensagem com um link para redefinir sua senha.',
          style: Theme.of(context).textTheme.bodyMedium,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 24),
        ElevatedButton(
          onPressed: () => context.go('/login'),
          child: const Text('VOLTAR AO LOGIN'),
        ),
      ],
    );
  }
}
