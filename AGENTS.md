# AGENTS.md — Contexto para agentes de IA

Este arquivo é o ponto de entrada para qualquer agente (human ou IA) que for trabalhar neste
repositório. Ele é curto de propósito: leia-o antes de mexer no código e só então abra os
documentos específicos. **O código é a fonte da verdade** — quando este arquivo, o `README.md`
ou alguma doc divergirem do código, o código ganha, e a divergência deve ser corrigida ou
registrada.

## O que é este projeto

App **Flutter** para gerenciar fichas digitais, campanhas, sessões em tempo real e inventário do
RPG de mesa **Despertar do Caos** (sistema customizado baseado em D&D 5e). Nome do pacote:
`despertar_caos_app` (`pubspec.yaml`, versão `1.0.7+6`). A interface é em português (pt-BR).

## Stack real

| Camada | O que é | Papel |
|---|---|---|
| `lib/` | Flutter + Dart (SDK `^3.12.0`) | UI, navegação, estado e regras de cálculo |
| `supabase_flutter` | SDK Supabase | Auth (e-mail/senha + Google), Postgres (dados), Storage (avatares/mapas/itens/documentos), Realtime (vitais e presença) |
| Riverpod (`flutter_riverpod ^2.5.1`) | Gerenciamento de estado | `StateNotifierProvider` para controllers; `FutureProvider.autoDispose` para listas |
| GoRouter (`go_router ^14.2.0`) | Navegação | Rotas centralizadas em `lib/core/router/router.dart`, com `StatefulShellRoute` (bottom nav) |

O schema do banco, as políticas e os triggers vivem em `supabase/supabase_schema.sql`.

## Mapa de documentos — quando ler cada um

- **`README.md`** — visão geral do produto, identidade visual e comandos de build do APK (Docker).
  Bom para entender o "porquê"; não é fonte da verdade sobre arquitetura (ver divergências no fim).
- **`supabase_instructions.md`** — passo a passo para provisionar o Supabase: rodar o
  `supabase_schema.sql`, habilitar Realtime nas tabelas `characters`, `sessions`,
  `session_participants` e `character_inventory`, criar os buckets `avatars`, `maps`, `items`,
  `documents` (todos públicos) e opcionalmente desativar a confirmação de e-mail.
- **`supabase/supabase_schema.sql`** — verdade do banco: tabelas, colunas, FKs, triggers e
  `disable row level security`. Consulte antes de escrever qualquer insert/update ou SQL novo.
- **`supabase/migrations/`** — mudanças incrementais de schema já aplicadas ao banco remoto.
  Novos ajustes de banco entram aqui como `<timestamp>_<descricao>.sql`, nunca editando o
  `supabase_schema.sql` (que serve de bootstrap).
- **`.env` / `.env.example`** — credenciais (`SUPABASE_URL`, `SUPABASE_ANON_KEY`). O `.env` é
  asset do app e **contém segredos**: não imprima, não commite, não exponha em log.

## Como rodar, testar e buildar

O SDK do Flutter **não está instalado** em todos os ambientes onde este repo é editado (por
exemplo, numa máquina só de revisão de código). Se `flutter`/`dart` não existirem no `PATH`,
trabalhe por leitura de código, valide assinaturas contra os arquivos vizinhos e **diga
explicitamente no relatório o que não pôde ser verificado** — nunca afirme que testou.

```bash
flutter pub get       # dependências (requer .env na raiz)
flutter run           # rodar em device/emulador conectado
flutter test          # testes em test/
flutter analyze       # lints (analysis_options.yaml: flutter_lints, com build/ e android/ etc. excluídos)
./run.sh              # roda como web-server na porta 3000
```

Build do APK de release é feito via Docker (comando no `README.md`) com
`ghcr.io/cirruslabs/flutter:stable`; o build web/Vercel usa `build_vercel.sh` (gera o `.env` a
partir das variáveis de ambiente da Vercel).

## Convenções observadas no código

- **Estrutura**: `lib/features/<feature>/{data,presentation}/`. **Não existe** pasta `domain/`
  no repositório (apesar do que o README diz) — regras de negócio ficam junto de `data/`
  (ex.: fórmulas em `character_repository.dart`) ou na própria tela. Features: `auth`,
  `campaign`, `character`, `dice`, `inventory`, `notifications`, `public_documents`, `session`
  (npc/monitor), `settings`, `shell`, `system_info`.
- **Arquivos**: `snake_case.dart` com sufixo pelo papel — `*_screen.dart` (tela),
  `*_repository.dart` (acesso ao Supabase, classe `XRepository`), `*_controller.dart`
  (`StateNotifier` + `XState`), `*_provider.dart` (providers Riverpod), `*_editor_screen.dart`.
- **Providers**: nomeados `<feature>ControllerProvider` (`campaignsControllerProvider`) e
  `<entidade>Provider` (`userCharactersProvider`). Telas que reagem a estado usam
  `ConsumerWidget` / `ConsumerStatefulWidget`.
- **Dados**: os models são `Map<String, dynamic>` crus do Supabase — não há classes de entidade.
  Colunas do banco em `snake_case` (`char_class`, `max_fv`, `avatar_url`); nomes de variáveis e
  classes em inglês.
- **Tratamento de erro**: repositories fazem `try/catch`, `debugPrint("Erro ao ...")` e devolvem
  `null`/lista vazia; a UI traduz em `SnackBar` com `SteampunkTheme.bloodRed`. Siga esse padrão
  em vez de deixar exceção subir para a tela.
- **Tema**: nunca escreva cores/fontes soltas. Use `SteampunkTheme`
  (`lib/core/theme/theme.dart`): `leatherBark` (fundo), `castIron` (superfícies),
  `copper` (destaque), `brassGlow`, `bloodRed` (perigo), `agedParchment` (leitura).
  Tipografia via `GoogleFonts` — `cinzel` (títulos), `ebGaramond` (corpo).
- **Idioma**: comentários e strings de UI em pt-BR; identificadores, classes e nomes de arquivos
  em inglês. Labels de botão aparecem em CAIXA ALTA.

## Regras de trabalho

- **Commits**: [Conventional Commits](https://www.conventionalcommits.org/) em inglês, curtos e
  focados (`feat:`, `fix:`, `chore:`, `docs:`). Um assunto lógico por commit.
- **Nunca** commite `build/`, `.dart_tool/`, `.env` nem artefatos gerados.
- **Push/merge** não são implícitos: confirme com o dono antes de publicar.
- **Versão e release** (crítico para o updater): o `version:` do `pubspec.yaml` é a versão que o
  APK instalado reporta (`packageInfo.version` + `buildNumber`), e o `UpdateChecker` a compara
  com a tag da última release no GitHub. **Antes de buildar/apublicar uma release, faça o bump de
  `version:` para exatamente o valor da tag** (ex.: tag `v1.0.8` → `version: 1.0.8+N`). Tag e
  pubspec fora de sincronia fazem o app avisar "nova versão disponível" mesmo já estando nela.
- **Banco**: nenhuma alteração destrutiva (DROP/coluna NOT NULL nova) sem aviso explícito.
  Prefira migrações idempotentes (`alter table if exists ...`).

## Divergências conhecidas (docs × código)

1. O `README.md` cita arquivos que **não existem** no repositório: `general_architecture.md`,
   `formules.md`, `visual.md`, `questions.md`, `tests.md` e o diretório `ai-build-instructions/`.
2. O `README.md` cita uma camada `domain/` (`Use Cases`) na estrutura de pastas — não há nenhuma
   pasta `domain/` em `lib/`.
3. O `README.md` fala em Dart SDK `^3.11.1`; o `pubspec.yaml` declara `^3.12.0`.
4. O `README.md` diz que o app usa Auth "e-mail/senha"; o código também suporta login com Google
   e fluxo de recuperação de senha.
5. `test/rpg_formulas_test.dart` testa funções **redefinidas dentro do próprio arquivo de teste**
   (não importa `lib/`), então ele não protege as fórmulas reais do app — e o `calculateMaxVigor`
   do teste (`CON * 2`) diverge da fórmula usada na tela de criação
   (`maxVigor = (CON * AGI) ~/ 2`). Vale unificar quando houver tempo.
