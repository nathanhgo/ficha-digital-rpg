import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'core/router/router.dart';
import 'core/theme/theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Carregar variáveis de ambiente se o arquivo existir, senão prosseguir
  try {
    await dotenv.load(fileName: ".env");
  } catch (e) {
    debugPrint("Aviso: Arquivo .env não encontrado. Certifique-se de criá-lo com base no .env.example");
  }

  // Inicializar Supabase se as chaves estiverem disponíveis
  final supabaseUrl = dotenv.env['SUPABASE_URL'] ?? '';
  final supabaseAnonKey = dotenv.env['SUPABASE_ANON_KEY'] ?? '';

  if (supabaseUrl.isNotEmpty && supabaseAnonKey.isNotEmpty) {
    await Supabase.initialize(
      url: supabaseUrl,
      anonKey: supabaseAnonKey,
    );
  } else {
    debugPrint("Erro: Credenciais do Supabase ausentes no arquivo .env");
  }

  runApp(
    // ProviderScope gerencia o estado global do Riverpod
    const ProviderScope(
      child: DespertarCaosApp(),
    ),
  );
}

class DespertarCaosApp extends StatelessWidget {
  const DespertarCaosApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Despertar do Caos',
      debugShowCheckedModeBanner: false,
      theme: SteampunkTheme.darkTheme,
      routerConfig: appRouter,
    );
  }
}
