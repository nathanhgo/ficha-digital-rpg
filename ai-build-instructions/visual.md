# Identidade Visual e Interface do Usuário (Visual)

Este documento descreve as diretrizes visuais para o aplicativo mobile **Despertar do Caos**. O design é projetado em uma estética **Steampunk/Medieval**, transmitindo um tom de engenharia rústica, couro, metal envelhecido e registros em pergaminho.

---

## 1. Mockup da Interface (Ficha do Jogador)

Abaixo está o conceito visual premium proposto para a tela da Ficha de Personagem, desenhado para celulares na temática de couro envelhecido, cobre e pergaminho:

![Mockup Visual da Ficha Digital](file:///home/admin/Pessoal/CodeInProgress/ficha-digital-rpg/character_sheet_steampunk.png)

A imagem acima está disponível localmente em: [character_sheet_steampunk.png](file:///home/admin/Pessoal/CodeInProgress/ficha-digital-rpg/character_sheet_steampunk.png).

---

## 2. Paleta de Cores e Temática Steampunk/Medieval

O tema baseia-se em **tons terrosos**, contrastados com elementos estruturais pretos e brancos, criando a sensação de um livro de regras ou diário de bordo antigo de engenharia mecânica.

### Cores de Fundo (Backgrounds)
*   **Fundo Principal (Leather Bark)**: `#322015` ou `#251810` (textura que simula couro escuro desgastado).
*   **Cards de Informação (Aged Parchment)**: `#EFE3C3` ou `#E8D8B0` (tom de pergaminho antigo com bordas rústicas).
*   **Cards Escuros de Contraste (Cast Iron)**: `#1E1611` (um marrom-escuro quase preto para painéis secundários).

### Cores Temáticas de Contraste (Accents)
*   **Cobre / Bronze (Mechanical Details)**: `#B87333` ou `#CD7F32` (linhas finas, engrenagens e botões de metal).
*   **Luz de Lamparina / Fogo**: `#E68A00` ou `#FF9900` (amarelo/laranja quente para indicar barras de vigor ou recursos ativos).
*   **Texto Principal (Ink Black / Soft White)**: `#1C130C` (preto-tinta para textos no pergaminho) e `#FFFFFF` (para textos diretamente no fundo escuro).
*   **Indicador de Status Crítico**: Redução a `#A62B2B` (vermelho escuro/sangue para alertas de perigo, fome, radiação e sobrecarga).

---

## 3. Tipografia

*   **Títulos das Seções (Headers)**: `Grenze Gotisch` ou `Cinzel Decorative` (Google Fonts). Dão um visual medieval e de escrita gótica ideal para cabeçalhos e títulos.
*   **Textos de Leitura (Body)**: `EB Garamond` ou `Alegreya` (Google Fonts). Fontes serifadas clássicas de livros que combinam perfeitamente com a estética de pergaminho.
*   **Valores Numéricos (Stats)**: `Special Elite` (estilo máquina de escrever) ou `Courier Prime` (monoespaçada clássica).

---

## 4. Estrutura de Telas e Fluxo do Aplicativo

### Tela de Login e Cadastro
*   Logotipo rústico em tons de bronze sobre fundo de couro texturizado.
*   Campos de input estilo caixas de metal com cantos em rebite.
*   Login convencional por Usuário/E-mail e Senha.

### Ficha de Personagem (Abas)
1.  **Aba Geral (Perfil)**:
    *   Avatar emoldurado em cobre e barras mecânicas com sliders reguladores de FV (Vida), Vigor, Sanidade, Fome e Sede.
    *   Exposição à Radiação e Caos exibidos em medidores analógicos circulares (estilo manômetro de vapor).
2.  **Aba Atributos e Perícias**:
    *   Atributos dispostos em cartões de pergaminho individuais. Ao clicar em um atributo, abre-se a lista de perícias correspondentes.
3.  **Aba Inventário**:
    *   Lista de itens com indicador de peso total. O botão de carga fica com uma coloração vermelha escura e um aviso de "Sobrecarga" caso o limite seja ultrapassado.
4.  **Aba Próteses e Magias**:
    *   Cadastro de próteses mecânicas com campo de nome, descrição e bônus em texto livre. Controle manual dos manômetros de Vapor e Óleo.
5.  **Aba Diário & Morte**:
    *   Diário de anotações pessoais do personagem.
    *   **Botão "Morrer"**: Ao ser pressionado, exige a digitação do nome do personagem para confirmar a morte. Quando acionado, bloqueia a escrita na ficha e disponibiliza o Diário na aba de Campanhas para todos os participantes da mesa.

### Painel do Mestre: Tela de Monitoramento da Sessão (Live Monitor)
Enquanto uma sessão criada pelo mestre estiver ativa, esta tela mostra cartões compactos para cada jogador que entrou na sessão:
*   **Cartões de Jogador**: Mostra o nome, avatar, FV atual/máximo e Vigor atual/máximo.
*   **Indicadores de Alerta Visual**:
    *   **Ícone de Peso (Vermelho)**: Acende se o jogador estiver "Sobrecarregado".
    *   **Ícone de Radiação (Vermelho)**: Alerta piscante se Radiação for $\ge 100$.
    *   **Ícone de Caos (Vermelho)**: Alerta piscante se Caos for $\ge 100$.
    *   **Ícone de Fome / Sede (Vermelho)**: Alerta piscante se Fome ou Sede chegarem a $0$.
*   **Anotações da Sessão**: Campo de digitação de texto persistente para o Mestre.
*   **Controle de XP e Itens**: Seletor rápido para enviar recompensa de XP (ex: "+50 XP") ou enviar itens (já cadastrados ou novos) para qualquer jogador participante da sessão.
