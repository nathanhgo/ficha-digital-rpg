# Plano de Testes e Validações (Tests)

Este documento define a estratégia de testes para validar a correta aplicação das regras consolidadas do RPG **Despertar do Caos**, a segurança do banco de dados e a sincronização em tempo real das sessões de jogo.

---

## 1. Testes Unitários (Regras de Negócio & Fórmulas)

Os testes unitários focam em validar o processamento isolado das variáveis calculadas da ficha.

### Casos de Teste Essenciais:

1.  **Cálculo de Modificadores (Fórmula D&D 5e)**:
    *   *Entradas de teste*: Atributo = `15` $\rightarrow$ Modificador esperado = `+2`.
    *   *Entradas de teste*: Atributo = `8` $\rightarrow$ Modificador esperado = `-1`.
    *   *Entradas de teste*: Atributo = `0` $\rightarrow$ Modificador esperado = `-5`.
2.  **Cálculo de Pontos de Vida (FV Máximo) com Dado de Vida (DV) Manual**:
    *   *Ação*: Simular a criação do personagem onde o usuário insere manualmente Constituição = `15` e DV = `10` (campo numérico).
    *   *Esperado*: FV Máximo = `150`.
3.  **Carga Máxima e Acúmulo de Peso**:
    *   *Entradas de teste*: Constituição = `12`, Força = `10` $\rightarrow$ Carga Máxima = `120` kg.
    *   *Ação*: Adicionar um item de peso `2.5` kg com quantidade `50` (Peso total = $125$ kg).
    *   *Esperado*: O sistema deve marcar a flag `isOverloaded = true` (excedeu 120 kg).
4.  **Distribuição de Pontos em Perícias**:
    *   *Ação*: Atributo Inteligência definido como `12` (libera $12 \times 3 = 36$ pontos). Tentar alocar $40$ pontos entre as perícias de Inteligência (como Engenharia e Medicina).
    *   *Esperado*: O validador do formulário deve lançar um erro e bloquear o salvamento.
5.  **Progressão de Experiência e Nível (Linear Acumulativa)**:
    *   *Cenário 1*: Personagem Nível 0 tem 80 XP e ganha +30 XP (Total: 110 XP).
        *   *Esperado*: Subir para **Nível 1** com **10 XP** restantes.
    *   *Cenário 2*: Personagem Nível 1 com 250 XP acumulados recebe +60 XP (Total acumulado: 310 XP).
        *   *Esperado*: Subir para **Nível 2** com **10 XP** restantes ($100 \text{ XP para Nível 1} + 200 \text{ XP para Nível 2} = 300 \text{ XP total}$).
    *   *Cenário 3*: Garantir que o valor delta exigido seja calculado corretamente como $(\text{Nível Atual} + 1) \times 100$.

---

## 2. Testes de Widget e Componentes (UI)

Garantem que a interface de usuário reaja de maneira previsível às ações e estados do jogo.

### Casos de Teste Essenciais:

1.  **Avisos de Alerta do Jogador**:
    *   *Ação*: Simular redução do status de Fome do personagem para `0`.
    *   *Esperado*: O slider de Fome fica vermelho escuro e exibe um ícone de exclamação de alerta de estado crítico.
2.  **Entrada Manual de Próteses (Meca)**:
    *   *Ação*: Preencher o formulário de nova prótese com Nome: "Olho Hidráulico", Descrição: "Olho mecânico a vapor", Bônus: "+2 em Percepção".
    *   *Esperado*: A prótese é exibida na lista sob a forma de texto puro, sem tentar aplicar cálculos automáticos no atributo do personagem.
3.  **Confirmação de Morte e Modo Somente Leitura**:
    *   *Ação*: Clicar em "Morrer", digitar o nome correto do personagem e confirmar.
    *   *Esperado*: Desativação de todas as opções de edição (inputs, sliders e inventário) na tela do jogador.

---

## 3. Testes de Integração e Realtime (Fim a Fim)

Validam a sincronização em tempo real entre o app do Jogador, o app do Mestre e o Supabase.

### Casos de Teste Essenciais:

1.  **Criação de Sessão e Notificação**:
    *   *Ação*: O Mestre clica para iniciar uma sessão na campanha X.
    *   *Esperado*:
        1.  Uma linha é criada na tabela `sessions` (status: `active`).
        2.  O serviço de notificação (FCM) é disparado.
        3.  O dispositivo de teste do Jogador recebe uma notificação push "Nova Sessão Iniciada".
2.  **Entrada em Sessão**:
    *   *Ação*: O Jogador clica no modal/notificação para participar da sessão.
    *   *Esperado*: Uma linha é adicionada em `session_participants` associando a ficha do jogador à sessão ativa.
3.  **Monitoramento em Tempo Real pelo Mestre (Live Monitor)**:
    *   *Ação*: O Jogador A (na sessão ativa) altera sua Radiação para `105` ou sua Fome para `0`.
    *   *Esperado*: A tela de monitoramento de sessão aberta no aparelho do Mestre deve destacar imediatamente o cartão do Jogador A em vermelho com os ícones de alerta correspondentes (Radiação $\ge 100$ ou Fome = $0$), em tempo real via escuta do Supabase WebSockets.
4.  **Alerta de Sobrecarga para o Mestre**:
    *   *Ação*: Jogador A ultrapassa seu peso máximo de carga.
    *   *Esperado*: O status de sobrecarga sincroniza instantaneamente e acende o ícone indicador de sobrecarga no painel do Mestre.
