# Instruções de Configuração - Supabase

Este guia descreve os passos necessários para configurar o banco de dados e serviços do **Supabase** para integrar com o aplicativo móvel **Despertar do Caos**.

---

## 1. Criar o Projeto no Supabase
1. Acesse o console do [Supabase](https://supabase.com/) e faça login.
2. Clique em **New Project** (Novo Projeto).
3. Selecione a sua organização, dê um nome ao projeto (ex: `despertar-caos-rpg`) e defina uma senha segura para o banco de dados.
4. Escolha a região mais próxima (ex: *South America (São Paulo)*) e clique em **Create New Project**.

---

## 2. Executar a Estrutura de Tabelas (SQL Schema)
1. No painel lateral esquerdo do Supabase, clique em **SQL Editor** (ícone `SQL`).
2. Clique em **New Query** (Nova Consulta).
3. Copie todo o conteúdo do arquivo local [supabase_schema.sql](file:///home/admin/Pessoal/CodeInProgress/ficha-digital-rpg/supabase/supabase_schema.sql).
4. Cole o código no painel do editor e clique em **Run** (Executar) no canto inferior direito.
5. Verifique a mensagem de sucesso no console para confirmar que as 9 tabelas, as políticas de segurança (RLS) e o trigger de perfis foram criados corretamente.

---

## 3. Ativar o Supabase Realtime nas Tabelas Críticas
Para que as atualizações de FV (vida), vigor, radiação, caos e a entrada de participantes em sessões sincronizem instantaneamente, você precisa ativar o Realtime. Existem três maneiras fáceis de fazer isso:

### Opção A: Pelo SQL Editor (Mais rápida)
Basta abrir o **SQL Editor**, criar uma **New Query** e executar o seguinte comando:
```sql
alter publication supabase_realtime add table public.characters;
alter publication supabase_realtime add table public.sessions;
alter publication supabase_realtime add table public.session_participants;
alter publication supabase_realtime add table public.character_inventory;
```

### Opção B: Pela seção "Publications" (Visível na sua barra lateral)
1. Na sua barra lateral esquerda, abaixo de *DATABASE MANAGEMENT*, clique em **Publications** (logo abaixo de *Indexes*).
2. Você verá a publicação padrão chamada `supabase_realtime`.
3. Clique em **Edit** (ou no botão de engrenagem) da publicação `supabase_realtime`.
4. Marque ou adicione as seguintes tabelas da lista:
   *   `characters`
   *   `session_participants`
   *   `sessions`
   *   `character_inventory`
5. Salve as alterações.

### Opção C: Editando cada Tabela individualmente
1. Vá em **Database** -> **Tables** (no menu lateral).
2. Para cada uma das quatro tabelas (`characters`, `session_participants`, `sessions` e `character_inventory`):
   *   Clique nos três pontinhos (`...`) ao lado do nome da tabela e selecione **Edit Table**.
   *   Role para baixo e ative a opção **Enable Realtime** (Habilitar Realtime).
   *   Clique em **Save**.

---

## 4. Configurar Baldes de Armazenamento (Storage Buckets)
O aplicativo precisa de armazenamento de arquivos para fotos de avatares, mapas e documentos enviados.
1. No painel do Supabase, clique em **Storage** (ícone de caixa/balde).
2. Clique em **New Bucket** (Novo Balde) e crie os seguintes buckets:
   *   `avatars` (Armazenamento de avatares dos personagens).
   *   `maps` (Armazenamento de mapas de campanha enviados pelo mestre).
   *   `items` (Imagens associadas aos itens do inventário).
   *   `documents` (Documentos públicos enviados pelos jogadores e mestre).
3. **Importante**: Certifique-se de marcar todos como **Public Bucket** (Balde Público) durante a criação para permitir que o app consiga ler as URLs públicas de imagens.

---

## 5. Praticidade nos Testes (Opcional)
Para facilitar o cadastro inicial de contas durante o desenvolvimento, sem a necessidade de validar e-mails reais:
1. No menu lateral esquerdo, sob a seção **CONFIGURATION**, clique em **Sign in / Providers** (logo abaixo de *Policies*).
2. Na lista de provedores, clique sobre **Email** para expandir as opções.
3. Desative a chave/switch **Confirm email**.
4. Clique em **Save** (Salvar) na parte inferior.
5. Isso permitirá que novos usuários criados com e-mail/senha consigam fazer login imediatamente no app após o cadastro.
