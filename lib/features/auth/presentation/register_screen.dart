import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'auth_controller.dart';
import '../../../core/theme/theme.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  String _selectedRole = 'player'; // 'player' ou 'master'

  @override
  void dispose() {
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _submit() async {
    if (_formKey.currentState!.validate()) {
      final success = await ref.read(authControllerProvider.notifier).register(
            _emailController.text.trim(),
            _passwordController.text.trim(),
            _usernameController.text.trim(),
            _selectedRole,
          );
      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Conta criada com sucesso! Faça login.'),
            backgroundColor: SteampunkTheme.copper,
          ),
        );
        Navigator.of(context).pop(); // Volta para tela de Login
      } else if (mounted) {
        final error = ref.read(authControllerProvider).error ?? 'Erro desconhecido';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Falha ao cadastrar: $error'),
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
        title: const Text('NOVO REGISTRO'),
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
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            'CRIAR CONTA',
                            style: Theme.of(context).textTheme.titleLarge,
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 24),
                          TextFormField(
                            controller: _usernameController,
                            decoration: const InputDecoration(
                              labelText: 'Nome de Usuário (Apelido)',
                              prefixIcon: Icon(Icons.person_outline, color: SteampunkTheme.copper),
                            ),
                            validator: (val) {
                              if (val == null || val.trim().isEmpty) {
                                return 'Por favor, insira um nome de usuário';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),
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
                              if (val == null || val.trim().length < 6) {
                                return 'A senha precisa ter no mínimo 6 caracteres';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 24),

                          // SELEÇÃO DE CARGO ESTILO CARDS PREMIUM
                          Text(
                            'SELECIONE SEU CARGO NA MESA',
                            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                                  color: SteampunkTheme.copper,
                                  fontWeight: FontWeight.bold,
                                ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: InkWell(
                                  onTap: () => setState(() => _selectedRole = 'player'),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(vertical: 12),
                                    decoration: BoxDecoration(
                                      color: _selectedRole == 'player'
                                          ? SteampunkTheme.copper.withValues(alpha: 0.15)
                                          : Colors.transparent,
                                      border: Border.all(
                                        color: _selectedRole == 'player'
                                            ? SteampunkTheme.copper
                                            : Colors.white24,
                                        width: 2,
                                      ),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Column(
                                      children: [
                                        Icon(
                                          Icons.shield_outlined,
                                          color: _selectedRole == 'player'
                                              ? SteampunkTheme.copper
                                              : Colors.white60,
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          'JOGADOR',
                                          style: TextStyle(
                                            color: _selectedRole == 'player'
                                                ? SteampunkTheme.copper
                                                : Colors.white60,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: InkWell(
                                  onTap: () => setState(() => _selectedRole = 'master'),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(vertical: 12),
                                    decoration: BoxDecoration(
                                      color: _selectedRole == 'master'
                                          ? SteampunkTheme.copper.withValues(alpha: 0.15)
                                          : Colors.transparent,
                                      border: Border.all(
                                        color: _selectedRole == 'master'
                                            ? SteampunkTheme.copper
                                            : Colors.white24,
                                        width: 2,
                                      ),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Column(
                                      children: [
                                        Icon(
                                          Icons.gavel_outlined,
                                          color: _selectedRole == 'master'
                                              ? SteampunkTheme.copper
                                              : Colors.white60,
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          'MESTRE',
                                          style: TextStyle(
                                            color: _selectedRole == 'master'
                                                ? SteampunkTheme.copper
                                                : Colors.white60,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 28),
                          if (authState.isLoading)
                            const Center(
                              child: CircularProgressIndicator(
                                color: SteampunkTheme.copper,
                              ),
                            )
                          else
                            ElevatedButton(
                              onPressed: _submit,
                              child: const Text('CRIAR CONTA'),
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
