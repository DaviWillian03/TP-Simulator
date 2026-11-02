# Roadmap — F1 Guidelines

Ordem de construção: corrida → fim de semana (Grande Prêmio) → Corrida Caótica → Campanha.
Cada marco termina jogável e testado. Itens vêm de `docs/DECISIONS.md`.

## ✅ Marco 1 — Corrida rápida em Interlagos (2026-11-01)
- Projeto Godot, logo e ícone, tema visual, fonte Inter.
- Dados 2026: 11 equipes, 22 pilotos (nomes reais), compostos de pneu, Interlagos (traçado real).
- Simulação: desgaste de pneu com "penhasco", regra dos 2 compostos (DSQ se não cumprir),
  combustível, ar turbulento, ultrapassagem por zona e dificuldade da pista, modo de
  ultrapassagem com bateria (2026), pit stop com perda real do pit lane, IA de estratégia.
- Tela inicial (escolha de equipe e duração 25/50/100%) e tela de corrida: pista com 22
  bolinhas, tabela com pneu e desgaste, ordens de ritmo/energia/box para os 2 carros,
  tempo 1×/2×/4×/8× + pausa, avisos não intrusivos, resultado final.
- 28 testes GUT (unidade + integração da tela de corrida).

## ✅ Direção visual Paddock (2026-11-01)
- 8 mockups → escolha do usuário → tokens em `UiStyle`; menu, corrida e resultado refeitos.
- Tabela no formato da transmissão com emblemas originais + importação de logo pelo jogador.

## ✅ Marco 2 — Corrida completa (2026-11-01)
- Mockups aprovados (`design/mockups/m2-*.html`) e implementados.
- **Clima dinâmico** com umidade e secagem da pista, pneus intermediário/chuva com curva por
  umidade, **radar de chuva com incerteza (P3)** e **pista que evolui (P5)** (borracha).
- **Safety car, VSC e bandeira vermelha (P6)**: SC agrupa e barateia a parada; VSC mantém as
  diferenças; vermelha libera troca de pneus e relarga atrás do SC.
- Rodadas, batidas, quebras e toques; **dano de asa** com troca no box; **punições** 5 s / 10 s /
  drive-through, cumpridas no box ou somadas ao tempo final; **pontos na licença**.
- **Ordens de equipe** (deixar passar, não brigar, liberado) com chance de desobediência.
- **Rádio com personalidade (P1)**: perguntas em momentos-chave com efeito de confiança; sem
  resposta, o piloto decide sozinho.
- **Menu DADOS** sem pausar (todos os pilotos, meus pilotos, tempos de volta).
- Calibração "realista" conferida com `tools/race_report.gd`; 52 testes.

## Marco 3 — Modo Grande Prêmio (em andamento)
- ✅ Calendário 2026 com 22 circuitos (`game/data/circuits`, `calendar_2026.json`).
- ✅ Mockups aprovados: configuração, fim de semana, classificação (`design/mockups/m3-*.html`).
- ✅ Protótipo 3D em Interlagos: pista com relevo, cenário, chuva, noite, câmera giratória,
  pit lane, boxes, brita, barreiras e grid; vista geral automática no 4×/8×.
- ✅ Simulação do fim de semana (`src/sim/`): `CarSetup` (acerto), `PracticeSession` (programas
  de blocos; jogar = simular), `QualiSim` (Q1/Q2/Q3 e SQ1/SQ2/SQ3, pneu e momento de sair,
  evolução da pista, tráfego, erros, bandeira vermelha, chuva), sprint (~1/3, sem regra dos 2
  compostos, pontos 8..1), grid vindo da classificação, pontos e `WeekendSim` (formatos normal,
  sprint e só a corrida; clima Realista/Seco/Chuva/Variável com previsão por dia).
- ✅ Telas (`src/ui/`): configuração do GP (m3-a), painel do fim de semana com o editor de
  programas (m3-b), classificação ao vivo (m3-c), treino ao vivo (mesma estrutura da
  classificação — sem mockup próprio) e corrida/sprint com o grid e o acerto, coluna de pontos e
  "Continuar". Capturas em `docs/screenshots/m3-*.png`. 84 testes.
- ⬜ 3D nos 22 circuitos (relevo e cenário de cada pista).
- ⬜ Realismo com modelos/texturas CC0 (aguarda liberar kenney.nl e polyhaven.com na rede).

## Marco 4 — Corrida Caótica ("Roleta do Caos", P8)
- Roleta de eventos + cartas de caos + variantes prontas, sobre o mesmo motor de corrida.

## Campanha — modo principal (prioridade desde 2026-11-02)
- ✅ 1ª camada: entrada (equipe real ou criada), criação da equipe em 4 passos (origem,
  identidade com carro e emblema gerados, motor e objetivos, pilotos reais da F2/F3), equipe
  criada como 12ª do grid (24 carros; classificação corta 7+7), salvar/carregar
  (`user://campaign.json`), sede mínima com a próxima rodada e o campeonato de construtores.
- ✅ Temporada completa (mockups v6): calendário em dias com "avançar até o evento", fim de
  semana jogável ou simulado, campeonatos de construtores e pilotos, meta da diretoria por origem
  (ou pelo nível do carro) com confiança, caixa simples (patrocínio − custos + prêmio final),
  demissão, falência e virada de temporada. Valores PROVISÓRIOS em `campaign_origins.json`.
- ✅ P&D (2026-11-02): árvore estilo F1 2017 (4 departamentos, 92 nós, carro atual × ano seguinte,
  Essencial/Avançado) e Fábrica (4 estruturas, níveis 1–5). `CarDevelopment`, telas Carro e Fábrica.
- ⬜ Camadas seguintes (ordem do roadmap abaixo): finanças, pessoal e contratos, patrocínios,
  estúdio de design, academia, teto de gastos, conselho, eventos, F2/F3/F4.

## Marco 5+ — Campanha (em camadas jogáveis)
Finanças e temporada → pessoal/pilotos e contratos → P&D (Essencial/Avançado) → fábrica →
patrocínios → estúdio de design (P9) → origens da equipe (P10) → academia de pilotos (P11) →
teto de gastos e restrição de túnel (P12) → conselho de regras (P13) → eventos (P14) →
F2/F3/F4 simuladas ao fundo → Modo Edição e importação (.zip).

## Pesquisa (antes de fixar atributos)
- Definir o modelo de atributos de pilotos e equipes; depois pesquisar dados reais de 2026
  para substituir os valores PROVISÓRIOS de `game/data/`.
- Confirmar o calendário 2026 completo (o dataset de traçados lista 23 GPs, sem Bahrein e
  Arábia Saudita — verificar), regulamento técnico 2026 (aero ativa, modo de ultrapassagem,
  compostos de pneu) e calibrar tempos de volta, desgaste e ultrapassagens por circuito.

## Android (depende do usuário)
- Instalar Android SDK (bloqueado na nuvem: `dl.google.com`) e criar o preset de exportação.
- No preset: excluir `addons/gut/*`, `test/*` e `tools/*`; conferir que `data/*.json` entra no APK.
- Primeiro teste em aparelho real: desempenho, toque e legibilidade da tela de corrida.


## ✅ Garagem em todo o fluxo jogável (2026-11-02)
- Corrida (torre tocável, cartões compactos, ícones de status), tela do box (estoque, ajustes, parada
  dupla, punição, mini-jogo de toque), classificação ao vivo, treino, painel do fim de semana, campanha.
- Rostos dos pilotos e logos das equipes (só locais, `game/local/`). Cor da equipe como ambiente.
- Desgaste de pneus balanceado (1 parada em corridas de 25%).

## O que falta para o jogo ficar pronto (auditoria dos pedidos do usuário, 2026-11-02)
Ordem sugerida por impacto. Itens vêm de `docs/IDEAS.md` (#1–#6) e das mensagens da sessão.
1. **Dados reais** (#3, #4): hoje cada piloto tem só `rating` e cada equipe só `car_rating`. Faltam atributos
   (ritmo, regularidade, ultrapassagem, chuva, potencial), idade/altura/peso/conquistas, dirigentes técnicos,
   engenheiros, história e estrutura reais da equipe, e pesquisa de 2026 para trocar os valores PROVISÓRIOS.
2. **Corrida Caótica** (#2): modo inteiro (Roleta do Caos) — a tela inicial mostra "em desenvolvimento".
3. **Campanha — camadas que faltam** (#4, #5): Pilotos/pessoal e contratos (agentes livres, outras equipes,
   novos pilotos), Finanças e aba de patrocínios (negociar por influência), estúdio de design do carro e editor
   de logo completos, academia de pilotos, teto de gastos e restrição de túnel de vento, conselho de regras
   (pontuação, motor, chassi, pneus…), eventos inesperados, F2/F3/F4 simuladas ao fundo, mercado de pilotos na virada.
4. **IA rival que joga o mesmo jogo**: as outras equipes não desenvolvem o carro (o jogador acaba ultrapassando).
5. **Modo Edição e importação** (#3): pacote .zip com validação (nomes, fotos, pinturas, logos, atributos,
   circuitos) e importador no celular (seletor de arquivos do Android).
6. **Cenários 3D** (#1): conferir o cenário e o relevo dos 22 circuitos (chão de Xangai, escala dos pinheiros,
   materiais) e trocar por modelos/texturas CC0 quando kenney.nl/polyhaven.com forem liberados.
7. **Android**: instalar o SDK (liberar `dl.google.com`), gerar o APK de teste e validar toque e desempenho.
8. **Balanceamento geral**: custos e efeitos de P&D/fábrica, finanças, calibração por circuito, simulação de
   várias temporadas; `tests` de economia.
9. **Acabamento**: som/efeitos (P7 foi recusada), tela de configurações, tutorial/ajuda, salvar vários
   slots de campanha, ícone e tela de abertura final, textos revisados.
