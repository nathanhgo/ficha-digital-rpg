# Despertar do Caos - Ficha Digital RPG

Aplicativo móvel desenvolvido para gerenciar campanhas, fichas de personagens, sessões de jogo e inventários em tempo real para o RPG **Despertar do Caos** (sistema customizado baseado em D&D 5e).

---

## 📸 Conceito Visual (Steampunk & Medieval)

O aplicativo adota uma identidade visual **Steampunk/Medieval** rústica, inspirada em engrenagens de cobre, couro envelhecido e anotações feitas em pergaminhos antigos, ideal para a imersão na mesa de jogo:

![Mockup do Aplicativo](character_sheet_steampunk.png)

---

## 🛠️ Stack Tecnológica

O projeto foi estruturado seguindo uma divisão clara:

*   **Frontend (Cliente)**:
    *   **Flutter**: Framework multiplataforma para o aplicativo móvel.
    *   **Riverpod**: Gerenciador de estado para reatividade robusta e fácil testabilidade.
    *   **GoRouter**: Controle de navegação modular entre telas.
    *   **Google Fonts**: Utilização dinâmica de fontes serifadas e góticas (*Grenze Gotisch*, *EB Garamond*, *Special Elite*).
*   **Backend (Servidor - Supabase)**:
    *   **PostgreSQL**: Banco de dados relacional para persistência de campanhas, fichas e inventários.
    *   **Supabase Auth**: Autenticação convencional (e-mail/senha).
    *   **Realtime WebSockets**: Sincronização em tempo real de status vitais dos jogadores (vida, radiação, caos e sobrecarga) com o monitor do Mestre.
    *   **Supabase Storage**: Armazenamento público de imagens de avatares, mapas e itens do inventário.
    *   **Database RLS (Row Level Security)**: Políticas rígidas no banco de dados para segurança de leitura e escrita.

---

## 📁 Estrutura de Diretórios

O projeto é organizado seguindo o conceito **Clean Architecture / Feature-First**:

```
ficha-digital-rpg/
├── ai-build-instructions/        # Documentos de apoio originais da mesa (fichas em PDF, ideias)
├── supabase/                     # Scripts de banco de dados
│   └── supabase_schema.sql       # Tabelas, Triggers e Políticas de RLS
├── lib/                          # Código-fonte em Flutter
│   ├── core/                     # Módulos globais compartilhados (Router, Theme, Utils)
│   └── features/                 # Recursos isolados (Auth, Character, Session, Inventory, etc.)
│       ├── data/                 # Fontes de dados e models
│       ├── domain/               # Entidades e regras de negócio puras (Use Cases)
│       └── presentation/         # Telas, widgets e controladores (Riverpod)
├── .env.example                  # Modelo de variáveis de ambiente
├── supabase_instructions.md      # Manual de configuração detalhado do Supabase
├── general_architecture.md       # Documentação técnica e arquitetura do software
├── formules.md                   # Detalhamento de fórmulas e mecânicas da mesa
├── visual.md                     # Guia de identidade visual do aplicativo
├── questions.md                  # Questionário de alinhamento com respostas integradas
└── tests.md                      # Estratégia de testes unitários, widgets e integração
```

---

## 🚀 Como Iniciar

### Passo 1: Configurar o Supabase
Siga todas as instruções detalhadas em [supabase_instructions.md](supabase_instructions.md) para criar o projeto, rodar as tabelas no SQL Editor, habilitar a replicação em tempo real e configurar os buckets de armazenamento.

### Passo 2: Configurar o Aplicativo Móvel
1. Certifique-se de ter o **Flutter SDK** instalado (versão compatível com o SDK Dart `^3.11.1`).
2. Duplique o arquivo `.env.example` e renomeie-o para `.env` na raiz do projeto.
3. Abra o arquivo `.env` e preencha as variáveis com as credenciais da API do seu projeto no Supabase:
   ```env
   SUPABASE_URL=https://seu-projeto.supabase.co
   SUPABASE_ANON_KEY=seu-token-anon-key-publico
   ```
4. Baixe as dependências executando o comando no terminal:
   ```bash
   flutter pub get
   ```
5. Conecte seu celular (com depuração ativada) ou emulador e execute o projeto:
   ```bash
   flutter run
   ```

---

## 📐 Documentação de Design do Sistema

Para uma compreensão aprofundada das decisões técnicas, consulte os documentos em Markdown disponíveis no repositório:
*   [Arquitetura do Software e Banco de Dados](general_architecture.md)
*   [Fórmulas e Regras de Negócio Implementadas](formules.md)
*   [Diretrizes Visuais e Telas](visual.md)
*   [Alinhamento de Dúvidas e Respostas](questions.md)
*   [Estratégia de Validação e Testes](tests.md)


## Comando de build do APK
```
docker run --rm -v "$PWD":/app -w /app ghcr.io/cirruslabs/flutter:stable bash -c "git config --global --add safe.directory /sdks/flutter && flutter build apk --release && chown -R $(id -u):$(id -g) /app/build"
```