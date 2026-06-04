# Logs de Modificações - Despertar do Caos RPG

Este documento registra as modificações de código e infraestrutura realizadas no projeto **Despertar do Caos RPG** para referência futura.

---

## 📅 [29/05/2026] - Correções de Banco, Relações e Criação de Testes

### 1. Resolução de Ambiguidade PostgREST (PostgreSQL Join)
*   **Problema**: O erro `PGRST201 (Could not embed because more than one relationship was found for 'campaigns' and 'profiles')` impedia a listagem das campanhas ao logar na conta de mestre/jogador.
*   **Causa**: A tabela `campaigns` possui mais de uma relação implícita ou explícita com `profiles` (uma direta via coluna `master_id` e outra indireta via tabela many-to-many `campaign_players`). Com isso, a chamada `.select('*, profiles(username)')` gerava ambiguidade no interpretador PostgREST do Supabase.
*   **Modificação**:
    *   No arquivo `lib/features/campaign/data/campaign_repository.dart`, alteramos a chamada do select para especificar explicitamente a chave estrangeira da relação do mestre:
        ```diff
        - .select('*, profiles(username)')
        + .select('*, profiles!campaigns_master_id_fkey(username)')
        ```
    *   Locais afetados: Método `fetchCampaigns` para mestre e jogador.

### 2. Correção de Recursão Infinita em Políticas RLS do Supabase
*   **Problema**: O erro `42P17 (infinite recursion detected in policy for relation "campaign_players")` ocorria ao tentar acessar ou listar participantes da campanha.
*   **Causa**: O banco entrava em loop infinito de avaliação porque:
    1.  A política de `select` da tabela `campaigns` exigia uma checagem de existência (`exists`) na tabela `campaign_players`.
    2.  A política de `select` da tabela `campaign_players` exigia uma checagem de existência (`exists`) na tabela `campaigns`.
    3.  Qualquer consulta a uma delas forçava o banco de dados a consultar a outra indefinidamente.
*   **Modificação**:
    *   No arquivo `supabase/supabase_schema.sql` (e nas instruções de migração), alteramos as políticas de `select` de ambas as tabelas para simplificar e remover a recursão:
        *   **Campanhas (`campaigns`)**: Qualquer usuário autenticado (`auth.uid() is not null`) agora pode visualizar informações básicas das campanhas.
        *   **Participantes (`campaign_players`)**: Qualquer usuário autenticado (`auth.uid() is not null`) agora pode visualizar os participantes das campanhas.
    *   A segurança dos dados sensíveis (Fichas, Itens do Inventário, Presenças, Anotações do Mestre) continua blindada por políticas de propriedade restritas que dependem do ID do proprietário (`owner_id = auth.uid()`) ou do mestre (`master_id = auth.uid()`), que não causam recursão.

### 3. Implementação e Correção de Testes
*   **Testes de Fórmulas (`test/rpg_formulas_test.dart`)**:
    *   Criado o arquivo de testes unitários cobrindo as mecânicas centrais do jogo:
        *   Cálculo de FV Máxima (`Constituição * Dado de Vida`)
        *   Cálculo de Vigor Máximo (`Constituição * 2`)
        *   Cálculo de Carga Máxima (`Constituição * Força`)
        *   Cálculo de Pontos de Perícia (`Valor do Atributo * 3`)
*   **Teste de Widgets (`test/widget_test.dart`)**:
    *   O teste antigo buscava um texto de mockup que foi removido.
    *   Adicionamos a injeção do `ProviderScope` do Riverpod.
    *   Mockamos o repositório de autenticação (`FakeAuthRepository` implementando `AuthRepository`) para contornar a inicialização do Supabase no ambiente de teste headless.
    *   Ajustamos a asserção para confirmar a renderização do botão "ENTRAR" da tela de login real.

---

### 4. Validação de UUIDs Vazios em Repositórios (Erro 22P02)
*   **Problema**: O erro `22P02 (invalid input syntax for type uuid: "")` ocorria durante a inicialização do app ou transições de estado de autenticação.
*   **Causa**: O `CampaignsController` (e potencialmente outros controladores) era inicializado antes do perfil de usuário ser carregado completamente, resultando em um ID de usuário ou ID de campanha vazio (`""`) sendo passado para os métodos de consulta do Supabase, disparando uma exceção de sintaxe de UUID inválida do PostgreSQL.
*   **Modificação**:
    *   Adicionamos validações explícitas (guards) no início de todos os métodos dos repositórios que fazem consultas filtrando por ID (UUID):
        *   `CampaignRepository.fetchCampaigns`: Retorna `[]` se `userId` for vazio.
        *   `CharacterRepository.fetchCharactersForUser`: Retorna `[]` se `userId` for vazio.
        *   `CharacterRepository.fetchCharactersForCampaign`: Retorna `[]` se `campaignId` for vazio.
        *   `SessionRepository.fetchSessions`: Retorna `[]` se `campaignId` for vazio.
        *   `SessionRepository.streamCharacters`: Retorna `Stream.value([])` se `campaignId` for vazio.
        *   `DocumentRepository.fetchDocuments`: Retorna `[]` se `campaignId` for vazio.
        *   `InventoryRepository.fetchInventory`: Retorna `[]` se `characterId` for vazio.


---

### 5. Correção de Permissões de Ingressão/Saída de Campanha para Jogadores (RLS)
*   **Problema**: O jogador recebia erro "Id inválido ou erro ao entrar" ao tentar se juntar a uma campanha digitando o código da mesma.
*   **Causa**: A política de `INSERT` na tabela `campaign_players` estava configurada incorretamente como "Apenas o Mestre pode adicionar jogadores na campanha", bloqueando a inserção realizada diretamente pelo jogador quando este tentava ingressar usando o código. A política de `DELETE` também limitava a remoção apenas ao mestre.
*   **Modificação**:
    *   No arquivo `supabase/supabase_schema.sql` (e nas instruções), atualizamos as políticas de `INSERT` e `DELETE` para `campaign_players`:
        *   **INSERT**: Permite a inserção se o `player_id` inserido for igual ao ID do usuário conectado (`auth.uid() = player_id`), ou se o usuário conectado for o mestre da campanha.
        *   **DELETE**: Permite a remoção se o `player_id` removido for o usuário conectado, ou se for o mestre da campanha.

---

## 📁 Arquivos Modificados
*   `lib/features/campaign/data/campaign_repository.dart` (Correção do Join explícito e guard de UUID vazio)
*   `lib/features/character/data/character_repository.dart` (Guards de UUID vazio para busca por usuário e campanha)
*   `lib/features/session/data/session_repository.dart` (Guards de UUID vazio para sessões e stream de personagens)
*   `lib/features/public_documents/data/document_repository.dart` (Guard de UUID vazio para documentos de campanha)
*   `lib/features/inventory/data/inventory_repository.dart` (Guard de UUID vazio para inventário de personagens)
*   `supabase/supabase_schema.sql` (Correção de recursão e permissão de inscrição/saída de jogadores na campanha)
*   `test/widget_test.dart` (Adaptação para o fluxo real de autenticação mockada)
*   `test/rpg_formulas_test.dart` (Novos testes unitários das fórmulas de RPG)

## [04/06/2026] UI/UX Fixes, Skills Update & Web Responsiveness
- Atualizado o mapa _attributeSkills em character_sheet_screen.dart para refletir a nova lista de perícias do sistema.
- Refatoração do layout da rolagem de dados (dice_screen.dart) para fixar os botões na base da área superior, evitando corte de tela em dispositivos móveis menores.
- Ajustado o layout das siglas dos atributos na ficha de personagem (vertical, centralizado e espaçado adequadamente do botão de decremento).
- Adicionada constraint de largura máxima (500px) no main.dart para garantir uma exibição agradável (aparência mobile) no Flutter Web.
- Preparação das instruções para deploy na Vercel.
