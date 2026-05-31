# Fórmulas e Regras de Jogo (Formules)

Este documento centraliza as fórmulas matemáticas e regras de cálculo consolidadas para o RPG **Despertar do Caos**, integrando as decisões de design da mesa.

---

## 1. Atributos Básicos e Modificadores

O personagem possui 8 atributos principais:
1. **Constituição (CON)**
2. **Força (FOR)**
3. **Destreza (DES)**
4. **Agilidade (AGI)**
5. **Carisma (CAR)**
6. **Força de Vontade (VON)**
7. **Inteligência (INT)**
8. **Percepção (PER)**

### Criação do Personagem
*   **Distribuição Inicial**: O jogador recebe um total de **80 pontos** para distribuir livremente entre os atributos na tela de criação de ficha (ex: dividindo igualmente, seriam 10 pontos em cada atributo).
*   **Valor Mínimo**: 0.
*   **Valor Máximo**: Não há limite estrito estabelecido (um personagem nível 1 poderia ter até 80 pontos em um único atributo).
*   **Força de Vontade**: Atributo de uso opcional/exclusivo de certas classes (mas o aplicativo permitirá distribuição genérica sem travas de negócio).

### Cálculo de Modificadores (Fórmula D&D 5e)
Os modificadores de atributo no sistema seguem a fórmula tradicional do D&D 5e:

$$\text{Modificador} = \lfloor \frac{\text{Atributo} - 10}{2} \rfloor$$

Abaixo está a tabela de referência rápida:

| Valor do Atributo | Modificador | Valor do Atributo | Modificador |
|:---:|:---:|:---:|:---:|
| 0-1 | -5 | 12-13 | +1 |
| 2-3 | -4 | 14-15 | +2 |
| 4-5 | -3 | 16-17 | +3 |
| 6-7 | -2 | 18-19 | +4 |
| 8-9 | -1 | 20-21 | +5 |
| 10-11 | 0 | 22-23 | +6 |

---

## 2. Estatísticas e Variáveis Vitais

As estatísticas vitais são calculadas dinamicamente com base nos atributos do personagem:

### Força de Vida / Pontos de Vida (FV Máximo)
$$\text{FV Máximo} = \text{Constituição (Bruto)} \times \text{Dado de Vida (DV)}$$
*   **Dado de Vida (DV)**: Devido à customização das raças ainda estar em desenvolvimento, o Dado de Vida (DV) será um **campo numérico manual** (ex: o jogador digita `8`, `10` ou `12`) preenchido pelo jogador no momento da criação do personagem.
*   *Exemplo*: Constituição bruto = 15, DV inserido = 10 $\rightarrow$ FV Máximo = $15 \times 10 = 150$.

### Vigor Máximo
$$\text{Vigor Máximo} = \lfloor \frac{\text{Constituição} \times \text{Agilidade}}{2} \rfloor$$

### Carga Máxima (Carga)
$$\text{Carga Máxima (kg)} = \text{Constituição} \times \text{Força}$$

### Sobrecarga de Peso
*   O aplicativo calcula o peso total de itens no inventário: 
    $$\text{Peso Total} = \sum (\text{Peso do Item} \times \text{Quantidade})$$
*   Se $\text{Peso Total} > \text{Carga Máxima}$:
    1.  **Interface do Jogador**: O indicador de carga fica vermelho.
    2.  **Interface do Mestre**: O mestre recebe uma indicação visual de que o jogador está sobrecarregado (para aplicar a punição que julgar justa na sessão).

---

## 3. Variáveis de Sobrevivência e Estados Especiais

*   **Fome e Sede**: Escala de $0$ a $100$.
    *   $100$: Saciedade total.
    *   $0$: Fome/Sede extrema (emite um alerta ao Mestre na tela de sessão ativa).
*   **Exposição à Radiação e Caos**: Escala de $0$ a $100$ (ou mais em casos excepcionais).
    *   Se atingir ou superar $100$: Emite um alerta imediato ao Mestre na tela de sessão ativa.
*   **Vapor e Óleo**: Recursos consumíveis para próteses. Funcionam de forma genérica como "mana" e são editáveis manualmente pelo jogador, sem automação de recarga pelo app.
*   **Clima C° e Corpo C°**: Campos puramente informativos para acompanhamento de temperatura durante as sessões.

---

## 4. Distribuição de Pontos em Perícias

As perícias estão agrupadas por atributos. A alocação de pontos de atributos gera pontos de perícias associadas da seguinte forma:

$$\text{Pontos de Perícia Disponíveis por Atributo} = \text{Valor do Atributo} \times 3$$

O aplicativo valida que a soma de pontos distribuídos nas perícias de um determinado grupo não ultrapasse essa quantia disponível.

---

## 5. Progressão de Nível e Experiência (XP)

Os personagens iniciam no **Nível 0**. A progressão é linear cumulativa, onde a quantidade de XP necessária para subir de nível (delta) aumenta a cada patamar:

$$\text{XP Necessário para subir de nível (Delta)} = (\text{Nível Atual} + 1) \times 100$$

Abaixo está o acúmulo de XP necessário para alcançar cada nível:

| Nível Atual | Nível Alvo | XP Delta do Nível | XP Total Acumulado Necessário |
| :---: | :---: | :---: | :---: |
| **0** | 1 | 100 XP | 100 XP |
| **1** | 2 | 200 XP | 300 XP |
| **2** | 3 | 300 XP | 600 XP |
| **3** | 4 | 400 XP | 1.000 XP |
| **4** | 5 | 500 XP | 1.500 XP |
| **N** | N + 1 | $(N + 1) \times 100$ XP | $\frac{100 \times (N+1) \times (N+2)}{2}$ XP |

---

## 6. Próteses e Órgãos Aperfeiçoados (Meca)

*   O jogador cadastra suas próteses manualmente.
*   Cada item de prótese contém: **Nome**, **Descrição** e um **Campo de Bônus/Penalidades** (texto livre).
*   Os bônus de atributos ou perícias concedidos pela prótese são ajustados manualmente pelo jogador nas suas perícias/atributos, sem necessidade de processamento ou cálculo automático por parte do app.
