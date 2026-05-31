import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'auth_controller.dart';
import '../../../core/theme/theme.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _submit() async {
    if (_formKey.currentState!.validate()) {
      final success = await ref.read(authControllerProvider.notifier).login(
            _emailController.text.trim(),
            _passwordController.text.trim(),
          );
      if (success && mounted) {
        context.go('/campaigns');
      } else if (mounted) {
        final error = ref.read(authControllerProvider).error ?? 'Erro desconhecido';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Falha ao entrar: $error'),
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
      body: Container(
        decoration: const BoxDecoration(
          color: SteampunkTheme.leatherBark,
        ),
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Logo / Cabeçalho Steampunk
                  Text(
                    'DESPERTAR DO CAOS',
                    style: Theme.of(context).textTheme.displayLarge?.copyWith(
                          fontSize: 40,
                          shadows: [
                            const Shadow(
                              blurRadius: 10.0,
                              color: Colors.black,
                              offset: Offset(2.0, 2.0),
                            ),
                          ],
                        ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Ficha Digital & Controle de Sessão',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: SteampunkTheme.copper,
                          letterSpacing: 1.2,
                        ),
                  ),
                  const SizedBox(height: 48),

                  // Card de Formário estilo Chapa de Ferro
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            'AUTENTICAÇÃO',
                            style: Theme.of(context).textTheme.titleLarge,
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
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _passwordController,
                            decoration: const InputDecoration(
                              labelText: 'Senha de Acesso',
                              prefixIcon: Icon(Icons.lock_outline, color: SteampunkTheme.copper),
                            ),
                            obscureText: true,
                            validator: (val) {
                              if (val == null || val.trim().isEmpty) {
                                return 'Por favor, insira sua senha';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 24),
                          if (authState.isLoading)
                            const Center(
                              child: CircularProgressIndicator(
                                color: SteampunkTheme.copper,
                              ),
                            )
                          else
                            ElevatedButton(
                              onPressed: _submit,
                              child: const Text('ENTRAR'),
                            ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  TextButton(
                    onPressed: () {
                      context.push('/register');
                    },
                    child: RichText(
                      text: const TextSpan(
                        text: 'Ainda não tem conta? ',
                        style: TextStyle(color: Colors.white60),
                        children: [
                          TextSpan(
                            text: 'Cadastre-se aqui',
                            style: TextStyle(
                              color: SteampunkTheme.copper,
                              fontWeight: FontWeight.bold,
                              decoration: TextDecoration.underline,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
