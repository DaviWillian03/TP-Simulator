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
- ✅ IA rival (as outras equipes desenvolvem o carro) e Pessoal (2026-11-02): contratos de pilotos, diretor
  técnico e engenheiros, mercado, negociação, folha de pagamento e virada com a IA renovando/contratando.
- ✅ Finanças e Patrocínios (2026-11-02): 5 zonas do carro, ofertas mensais por influência, bônus por pódio,
  livro-caixa (receitas × despesas), projeção do caixa e histórico. `Sponsorship`, telas Patrocínios e Finanças.
- ✅ Eventos inesperados e Conselho de regras (2026-11-02): 10 eventos automáticos e votação de pontuação, sprints e pneus.
- ⬜ Camadas seguintes: estúdio de design, academia, teto de gastos, conselho,
  eventos, F2/F3/F4 simuladas, dados reais de pilotos/técnicos.

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

## Fila de pedidos pendentes (revisão de 2026-11-04, pedido do usuário: uma tarefa por vez, do primeiro ao último)
Ordem de chegada dos pedidos ainda abertos (o que já foi feito está nas seções abaixo com ✅):
1. ✅ (2026-11-04) #1 — Pop-ups do **campeonato mundial** durante a corrida da campanha (pilotos, construtores, título em jogo).
   Fica pendente só a troca dos cenários 3D por modelos CC0 (bloqueado: rede).
2. #2 — **Corrida Caótica** (P8 aprovada, Roleta do Caos).
3. #3 — **Modo Edição e importação** (.zip com validação e seletor de arquivos no Android).
4. #4 — **Estúdio de design** (P9) e cargos da sua equipe (dirigentes, engenheiros de corrida); equipe criada com logo/identidade e
   objetivos de longo prazo; #17 — demitido recebe proposta de outra equipe.
5. P11/P12 — academia de pilotos, F2/F3 simuladas ao fundo e F4; **teto de gastos, limite de túnel de vento e empréstimo**;
   mais eventos (cancelamento/adiamento por país, dirigentes, IA).
6. 2026-11-03 — **Corrida: planos táticos, reação à parada do rival e desacelerar em momentos-chave** (a parte da classificação foi feita).
7. 2026-11-04 (prompt mestre) — (b) **componentes com limite e punição de grid**; (c) **finanças** (garantido × meta, compromissos,
   prêmio oficial); (d) **mercado vivo** (contratos futuros da IA, perfis, cadeia F1→F2→F3).
8. 2026-11-04 — **Campanha em 3 categorias** (F3/F2/F1, acesso e rebaixamento, tabelas bonitas).
9. 2026-11-04 — **Aba Histórico** (Lendas, Pilotos atuais com números até 2025, Campeonatos).
10. 2026-11-04 — **Animação de campeão**.

## O que falta para o jogo ficar completo (revisão geral, 2026-11-02)
Revisão de todos os pedidos (`docs/IDEAS.md` #1–#6, propostas aprovadas P1–P14, decisões e mensagens da sessão) contra o que existe.
Já feito: corrida completa e GP (treinos, classificação, sprint), Garagem em todas as telas, box com mini-jogo, campanha com temporada,
P&D, fábrica, IA rival, pessoal e contratos, patrocínios, finanças, eventos, conselho, dados reais de 2026 e fichas de pilotos.

### A. Modos de jogo
1. **Corrida Caótica** (#2, P8 aprovada: Roleta do Caos completa): nada implementado; a tela inicial mostra "em desenvolvimento".

### B. Campanha — o que ainda falta
0. **Reestruturação (prompt mestre, 2026-11-04)** — ordem: (a) ciclo de peças por carro + 4 características do carro e perfil
   das pistas + sede nova (mockup); (b) componentes com limite e punição; (c) finanças (garantido × meta, compromissos, prêmio
   oficial); (d) mercado vivo (contratos futuros da IA, perfis, cadeia F1→F2→F3); depois estúdio de design e 3 categorias.
2. **Estúdio de design do carro** (#4, P9): pinturas em camadas, acabamentos, posição dos patrocinadores no carro (hoje só as zonas),
   capacete, até 3 pinturas especiais por temporada, lançamento do carro, editor de logo da equipe criada, atalho "gerar pintura".
3. ✅ (2026-11-04) Aposentadoria, pilotos novos fictícios, base que evolui e sobe de categoria. **Falta**: academia de pilotos (P11),
   resultados de F2/F3 simulados ao fundo e F4.
4. **Teto de gastos e limite de túnel de vento** (P12) e **empréstimo** (Finanças só tem o resumo).
5. ✅ (2026-11-04) Regras técnicas (motor, aero, chassi, reabastecimento, calendário) com ano de virada. **Conselho** (antes): motor (V6/V8…), chassi, aerodinâmica ativa, reabastecimento, calendário e os "anos de virada"
   que embaralham as notas. A 1ª versão só tem pontuação, sprints e pneus; o lobby foi dispensado pelo usuário.
6. **Eventos**: catálogo de 10; faltam mais eventos (cancelamento/adiamento por país, acidentes de carreira, crises de fábrica, mudanças de
   dirigentes) e eventos com efeito em equipes da IA. O usuário escolheu consequência automática (sem escolhas).
7. ✅ (2026-11-04) 4 cargos com nomes reais e notas em todas as equipes; IA renova e contrata técnicos. **Pessoal** (resto): faltam outros cargos "da sua equipe" (#4: dirigentes, engenheiros de corrida), dirigentes reais por
   equipe e a IA trocar técnicos. **Demissão**: o "demitido pode receber proposta de outra equipe" (#17) ainda não existe (só "nova campanha").
8. **Histórico da campanha** (campeões por ano, regras de cada ano, eventos marcantes) e a aba "Histórico" dos campeonatos.
   Pedido de 2026-11-04: sub-telas **Lendas** (maiores campeões; aposentados da campanha entram), **Pilotos atuais**
   (números até o fim de 2025 + o que a campanha somar) e **Campeonatos** (campeões de pilotos e construtores de cada ano).
9. **Animação de campeão** (pedido de 2026-11-04): celebração especial ao fim da corrida que decide o título de pilotos
   ou de construtores (antecipado ou na última etapa).
9. **Equipe criada**: cargos fictícios existem só como técnicos; faltam logo/identidade editáveis além de formas, e objetivos de longo prazo
   com acompanhamento.

10b. **Campanha em 3 categorias (F3/F2/F1)** com acesso e rebaixamento — decisões em DECISIONS (2026-11-04). Depois das frentes 4–6.

### C. Dados e conteúdo
10. **Dados reais restantes**: diretores técnicos da maioria das equipes, história/estrutura por equipe, biografia de F2/F3 e dos técnicos reais,
    atualização a cada GP; atributos são estimativa do projeto (resultados 2024–26). Balancear pela temporada de 2026 (notas dos carros).
11. **Modo Edição e importação** (#3): pacote `.zip` com validação (nomes, fotos, pinturas, logos, atributos, circuitos) e importador no celular com o
    seletor de arquivos do Android. Hoje logos e fotos entram por pasta local (`game/local/`).

### D. Corrida, 3D e experiência
12. **Cenários 3D** (#1): conferir relevo e cenário dos 22 circuitos (chão de Xangai, escala dos pinheiros, materiais) e trocar por modelos/texturas CC0
    quando kenney.nl/polyhaven.com forem liberados. Pop-ups do **campeonato mundial** durante a corrida (#1) só existem para eventos da corrida.
13. ✅ 1ª rodada (2026-11-02): som na corrida, zoom por pinça, marcadores por equipe, letra maior, arrastar para rolar.
    ✅ 2ª rodada (2026-11-03): corrida em tela cheia (MM3), cartões compactos com foto, radar em Dados > Clima, classificação jogável na pista 3D.
    Ideias futuras da classificação: Atacar/abortar durante a volta, setores com cores, som de motores na classificação.
    **Revisão de jogabilidade no aparelho** (continua): toque, tamanho dos alvos, legibilidade da corrida e do box, desempenho do 3D no celular.

### E. Plataforma e qualidade
14. **Android**: instalar o SDK (liberar `dl.google.com`), gerar o APK de teste (preset e `scripts/build-apk.sh` prontos) e validar em aparelho.
15. **Testes mais rápidos**: a suíte tem ~262 testes e leva ~8 min em sequência (arquivos pesados: campanha, corrida, eventos). Plano: rodar os
    arquivos em paralelo (`scripts/run-tests.sh`), reduzir as corridas simuladas dentro dos testes e separar os testes lentos.
16. **Balanceamento de economia** (simular várias temporadas em lote: caixa, P&D, folha, patrocínio) e de eventos; pesos de IA.
17. **Acabamento**: tela de configurações, tutorial/ajuda, vários slots de campanha, versão do save (migração), tela de abertura e ícone finais,
    revisão de textos, `docs/THIRD_PARTY.md` completo. Som: já há som na corrida (2026-11-02); faltam música/sons de menu se o usuário quiser.
