# Decisões do projeto — F1 Guidelines

Respostas do usuário na rodada de múltipla escolha (2026-11-01). Este arquivo é a fonte
oficial do que foi decidido; `docs/IDEAS.md` guarda o histórico das ideias.
Números entre parênteses = dúvida correspondente em IDEAS.md.

## Identidade e distribuição
- **Destino**: grátis, fora da loja (APK distribuído publicamente). (19)
- **Nome**: "F1 Guidelines", **definitivo**. (#6)
- **Nomes no jogo base**: **reais direto no jogo** (pilotos, equipes, chefes, engenheiros,
  patrocinadores). (20, 25, 26)
  - Aviso registrado ao usuário: distribuição pública + nome "F1" + nomes reais tem risco jurídico
    (marca e direito de imagem). Decisão consciente do usuário.
  - Limites técnicos/éticos mantidos pelo Claude: **sem fotos oficiais, sem logos oficiais de
    equipes, da F1 ou de marcas** dentro do jogo; esses só via importação pessoal (Modo Edição).
- **Retratos**: **ilustração estilizada** — retratos genéricos no estilo do jogo, sem imitar o rosto
  real de ninguém; fotos reais só via importação. (21)

## Corrida
- **Pneus**: regra oficial 2026 — pelo menos 2 compostos secos diferentes, isento se usar
  intermediário/chuva. (1)
- **Tempo**: acelerar (1×/2×/4×/8×) + pausa opcional; menus funcionam sem pausar. (3)
- **Duração**: escolhível — 25%, 50% ou 100% das voltas reais. (4)
- **Tela**: paisagem (deitado). (10)
- **Ordens aos pilotos**: ritmo (atacar/normal/poupar pneus), energia/motor, defender/atacar
  rival, trocas entre companheiros. (2)
- **Clima**: dinâmico, pode mudar durante a corrida. (7)
- **Neutralizações**: safety car, VSC e bandeira vermelha. (8)
- **Punições**: tempo (5s/10s/drive-through) + pontos na licença + multas na campanha. (9)
- **Grid**: 11 equipes / 22 carros (2026). (6)

## Modos
- **Grande Prêmio — fim de semana**: completo (treinos livres, Q1/Q2/Q3, corrida, formato sprint
  nos GPs sprint), qualquer sessão pode ser simulada. (12)
- **Grande Prêmio — configuração**: tudo configurável (circuito, equipe, duração, clima). (13)
- **Corrida Caótica**: "Roleta do Caos" completa (roleta + cartas + variantes). (18)

## Propostas
- **Aprovadas**: P1 (rádio com personalidade), P3 (radar de chuva), P8 (Roleta do Caos).
- **Aprovadas (cont.)**: P5 (pista que evolui), P6 (safety car estratégico), P9 (estúdio de
  design completo), P10 (origens da equipe completa), P11 → **Academia de pilotos**, P12 (teto de
  gastos, restrição de túnel de vento, anos de mudança de regulamento), P13 (conselho com voto e
  lobby), P14 (eventos inesperados completa).
- **Recusadas**: P2 (prévia de retorno do pit), P4 (batalhas em destaque), P7 (som ambiente
  reativo), coletiva de imprensa (alternativa da P11).

## Campanha
- **Duração**: sem fim; objetivos da diretoria a cada temporada. (14)
- **Fracasso**: demissão/falência possíveis, mais tolerante nas dificuldades fáceis; demitido pode
  receber proposta de outra equipe. (17)
- **Criação de equipe**: 4 origens (Garagem, Investidor, Montadora estreante, Resgate) + objetivo
  de longo prazo + nível Essencial/Avançado + dificuldade da IA. (16, P10)
- **Motor próprio**: qualquer origem pode escolher motor próprio na criação. (30)
- **P&D**: árvore completa sempre existe; modo Essencial (diretor técnico decide detalhes) ou
  Avançado, trocável a qualquer momento. (31)
- **Tempo**: dias de calendário, com "avançar até o próximo evento". (32)
- **Contratos**: simples — salário + duração → aceita / recusa / contraproposta. (33)
- **Design do carro**: P9 completa; tinta/acabamento **só visual**. (28)
- **Pilotos disponíveis** (resposta livre do usuário): (27)
  - F1, **F2, F3 e F4 com nomes e informações reais**;
  - pilotos **no radar da F1 como agentes livres** (WEC, IndyCar, Fórmula E etc.), também reais;
  - o restante: **pilotos fictícios criados ao longo dos anos**.
- **F2/F3/F4**: simuladas ao fundo (resultados automáticos, sem corridas jogáveis). (27)
- **Mudanças de regras**: Conselho com voto e lobby (P13). Regras mutáveis: pontuação, tipo de
  carro, motor, chassi, pneus, **reabastecimento, corridas sprint, aero ativa/asa móvel,
  calendário**. (35, 36, 37)
- **Eventos**: frequência configurável (desligados/raros/normais/frequentes). (38)
- **Tom dos eventos** (resposta livre do usuário): realista, incluindo acontecimentos dolorosos
  possíveis na vida real. (39)
  - Aplicação pelo Claude: eventos graves e realistas (lesões sérias, fim de carreira,
    cancelamentos por crises, falências) escritos em tom sóbrio de drama esportivo. Como o jogo usa
    **nomes reais**, eventos de natureza criminal ou escandalosa (prisões, doping, escândalos
    pessoais) só atingem **personagens e marcas fictícios**, para não atribuir fatos falsos e
    difamatórios a pessoas reais.

## Modo Edição
- Altera: **nomes e fotos, pinturas e logos, atributos, circuitos** (nomes e fundos). (22)
- Importação: **arquivo único .zip** com manifest, validado antes de aplicar. (23)

## Logo e primeiro marco
- **Logo**: conceito "linha de corrida" (traçado ideal formando o desenho), original, sem imitar a
  logo oficial da F1.
- **Primeiro marco**: base do projeto + corrida simulada — um circuito 2026 com 22 carros,
  pneus com desgaste e tabela de posições.
- **Primeiro circuito**: Interlagos (Brasil).

## Direção visual (2026-11-01)
- Método "mockup primeiro" (inspirado em github.com/halilc4/tabbyspaces): 8 direções em HTML
  puro em `design/mockups/`; o usuário escolheu a **03 · Paddock** (estilo revista impressa).
  (Chegou a indicar a 04 · Retrô 70 e se corrigiu em seguida.)
- Tokens no código: `game/src/ui/ui_style.gd` — papel `#efe9de`, tinta `#141414`, vermelho
  `#E10600`; Archivo Black (títulos/nomes/números) + Archivo Narrow 600 (texto); fios grossos.
- Novas telas: primeiro mockup em `design/mockups/`, depois implementação, depois conferência
  por captura de tela comparando com o mockup.
- **Tabela da corrida** no formato da transmissão: posição, emblema da equipe, SOBRENOME.
- **Emblemas das equipes**: o usuário pediu os símbolos reais. Logos oficiais são marcas
  registradas e não entram no jogo distribuído. Solução aplicada (padrão recomendado; a pergunta
  ficou sem resposta explícita): emblemas **originais** nas cores de cada equipe
  (`game/assets/emblems/`, gerados por `tools/make_emblems.py`) e **importação pelo jogador**:
  uma imagem em `user://import/emblems/<id_da_equipe>.png` substitui o emblema.
- Escopo aplicado (padrão; pergunta sem resposta explícita): menu, corrida e resultado.

## Marco 2 — corrida completa (2026-11-01)
- Mockups aprovados como estão: `design/mockups/m2-a-chuva-radio.html` e `m2-b-safety-car-dados.html`
  (rádio no canto inferior do mapa, radar no canto superior direito, ordens de equipe nos
  painéis, menu DADOS cobrindo o mapa, faixa de status no topo da tabela).
- Rádio com perguntas **só em momentos-chave** (~1 pergunta a cada 8–10 voltas por piloto).
- Incidentes no padrão **realista**: na seca, safety car em ~metade das corridas e 1–3
  abandonos; na chuva, bem mais.

## Estilo das tabelas (2026-11-01)
- Pedido do usuário: linha separando cada piloto e tabelas mais bonitas. Mockups em
  `design/mockups/t-*.html`; escolhida a **C · Folha de cronometragem** (grade completa, cabeçalho
  em tinta), com o **quadrado da posição na cor da equipe** mantendo bom contraste (número
  preto ou branco conforme a luminosidade da cor).
- Pneu: **círculo colorido com a letra + porcentagem de desgaste**.
- Vale para a tabela da corrida, o menu DADOS e o resultado final.

## Marco 3 — modo Grande Prêmio (2026-11-01)
- Mockups `design/mockups/m3-*.html`: telas de configuração, fim de semana e classificação aprovadas
  no conceito.
- **Cenário e pista em 3D** (resposta livre do usuário): cenário mais detalhado e **tridimensional**,
  com câmera que o jogador gira para ver de outros ângulos. Substitui o cenário 2D proposto.
- **Treinos livres** (resposta livre): o jogador **monta um programa** combinando blocos
  predefinidos e os pilotos seguem. Pode **jogar** o treino (acompanhar a execução) ou **simular**
  (resultados aleatórios desses programas).
- **Classificação**: o jogador escolhe o pneu e o momento de sair para a volta rápida (pista
  evolui; risco de tráfego, bandeira vermelha e chuva).
- **Sprint**: formato real 2026 — TL1, classificação sprint, corrida sprint (~1/3 da distância,
  sem parada obrigatória, pontos para o top 8), classificação e corrida.
- **Visual 3D** (respostas em múltipla escolha): **tudo em 3D** (o mapa 2D sai), **relevo
  aproximado** por pista (subidas/descidas conhecidas, valores provisórios) e estilo **mais
  realista** (texturas, sombras, iluminação). Texturas geradas por código (ruído procedural), pois
  bibliotecas de assets estão bloqueadas na rede; protótipo em Interlagos para aprovação antes de
  estender aos 22 circuitos.
- **Protótipo 3D** (design/mockups/png/3d/): usuário pediu **mais realismo antes** de seguir com o
  resto do Marco 3 e vai **liberar kenney.nl e polyhaven.com** na rede para usar modelos e
  texturas CC0 (registrar origem/licença em docs/THIRD_PARTY.md). Enquanto isso: detalhes de pista
  independentes de assets (brita, barreiras, prédio dos boxes, grid).
- **Tempo acelerado no 3D** (múltipla escolha): continua 3D; no **4× e 8×** a câmera vai sozinha
  para a **vista geral** e volta à câmera anterior no 1×/2×. Se o jogador trocar a câmera enquanto
  acelerado, vale a escolha dele. (Sem mapa 2D: o custo do 3D não depende da velocidade.)
