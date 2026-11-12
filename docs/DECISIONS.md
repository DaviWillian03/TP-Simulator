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

## Reformulação visual — direção Garagem (2026-11-02)
- Usuário pediu reformulação profunda dos menus (Paddock deixa de ser obrigatória). Três direções
  em `design/mockups/v3-*` (Garagem, Central da equipe, Largada); escolhida a **Garagem**:
  ambiente escuro de box, o carro da equipe iluminado como destaque, a cor da equipe tinge os
  destaques; vermelho = marca e ação principal; fonte Titillium Web (OFL) — trocada pela Kanit em 2026-11-10.
- Implementadas como referência de qualidade: **tela inicial** e **configuração do GP**. As demais
  telas seguem Paddock até serem migradas (UiStyle tem as duas seções; ver CLAUDE.md).
- Carro em destaque: ilustração vetorial **original** (`tools/make_car_art.py`), uma por equipe.
- **Logos oficiais**: usuário pediu; continuam fora do repositório (marcas registradas). Para o
  APK pessoal: pasta `game/local/emblems/` (ignorada pelo git) ou `user://import/emblems/`.
- **Aprovadas** (múltipla escolha): tela inicial e configuração do GP na Garagem viram o padrão.
  Ordem de migração: painel do fim de semana → treino ao vivo (mockup próprio antes) →
  classificação → resultados → corrida; depois os ajustes do 3D.

## Campanha — prioridade e primeira camada (2026-11-02)
- **Foco**: a campanha é o modo principal; telas do Grande Prêmio são adaptadas depois.
- **1ª camada** (múltipla escolha): **criação da equipe** (4 origens, motor próprio, objetivo de
  longo prazo, nível Essencial/Avançado, dificuldade da IA) + temporada simples em seguida.
- **Entrada** (múltipla escolha): **equipe real ou criada**; a equipe real entra junto.
- **Grid** (múltipla escolha): a equipe criada é a **12ª equipe — 24 carros**.
- **Temporada da campanha** (mockups aprovados): sede com tempo em dias, campeonatos e relatório da
  diretoria. Meta = posição final nos construtores (origem ou nível do carro; sobe 1 posição quando
  cumprida). Demissão com a confiança zerada; falência com o caixa negativo. Finanças só no básico
  (contratos, patrocínios e P&D ficam nas próximas camadas).
- **Logos oficiais** (usuário joga só no celular pessoal): ficam fora do repositório; o usuário envia
  as imagens, o Claude padroniza e devolve um zip para `game/local/emblems/` (ignorada pelo git).

## Tela de corrida na Garagem e box (2026-11-02)
- **Layout aprovado** (mockup v7): pista 3D maior (916×462), cartões de controle baixos, ordens de
  equipe em botão com popover, câmera por botões diretos, logos e rostos do usuário.
- **Pneu**: a vida do pneu dos **seus** carros é uma barra que esvazia; dos **rivais** só composto +
  **idade em voltas** (desgaste exato é telemetria interna). A torre alterna intervalo **à frente** e **líder**.
- **Fotos de pilotos** (uso pessoal do usuário): só o **rosto**, recortado por `tools/prepare_portraits.py`
  para `game/local/drivers/` (ignorada pelo git). Sem foto (F2/F3, equipe criada): círculo com iniciais.
- **Chamar para o box** abre uma **tela própria**, sem pausar a corrida (fica em **1× ou 2×**), com todas
  as opções da parada. Recursos escolhidos (múltipla escolha): **estoque limitado de pneus** (jogos novos
  e usados por composto; no GP vem da classificação), **ajustes do carro** (ângulo da asa dianteira, troca
  de asa, reparo parcial do assoalho, cada um custa tempo parado) e **parada dupla** (fila no box; decidir
  a ordem). Execução: **mini-jogo de toque na hora certa** (ganha ou perde décimos). Não escolhido: modos
  seguro/agressivo da equipe de box. A "prévia de retorno do pit" (P2) segue recusada.
- **Indicadores na torre** (ícones com formas diferentes, não só cores): relógio **roxo** = melhor volta
  da corrida; triângulo **amarelo** "!" = piloto sob investigação; círculo **vermelho** "!" = punição de
  tempo ainda não cumprida.
- **Investigação** (nova regra, pedido do usuário): um toque entre carros abre investigação do causador
  (1–2 voltas); o veredito mantém a chance atual de punição (50%) ou arquiva sem punição.
- **Punição de tempo no box por escolha**: na tela do box o jogador decide cumprir a punição parado
  agora (soma ao tempo parado) ou levá-la ao fim (soma ao tempo final). Drive-through segue como está.
- **Cor da equipe como ambiente** (ideia do usuário): todos os menus, inclusive a corrida, passam a ter o
  fundo tingido pela cor da equipe gerenciada (paredes, painéis e pista). Um único ponto no `UiStyle`
  (cor ativa da equipe) controla; aplicado na migração da tela de corrida e das demais.
- **Câmera pela torre**: tocar na linha de um piloto segue o carro dele na pista; tocar de novo volta à
  vista geral. Os botões "Seguir ALB/SAI/Líder/Geral" sobre a pista saem.

## Tela de corrida e tela do box implementadas (Garagem)
- Corrida na Garagem: barra de topo (velocidade 1×–8×, Dados, selo de bandeira SC/VSC/vermelha, voltas),
  pista 3D 916×462 com cantos arredondados, dois cartões dos seus carros e torre de 320 px.
  Fundo na cor da equipe do jogador (também na tela do box).
- Tocar na linha da torre segue o carro; tocar de novo volta à vista geral. Botões "Seguir…" removidos.
- Tela do box (`PitScreen`) não pausa a corrida: limita a 1×/2× e restaura a velocidade ao fechar.
  Nada vale até "Confirmar box". Parada dupla: só este carro · companheiro na volta seguinte · junto (fila).
- Mini-jogo de toque (`PitTapOverlay`): carro parado = 1×; verde perfeito −0,3 s, fora do verde +0,6 s;
  sem toque a parada fica neutra (IA e simulações em lote nunca passam por ele).
- Decidido sem perguntar durante a ausência do usuário (revisar se quiser): ao fechar a tela do box a câmera
  volta ao que era antes; o companheiro na parada dupla usa o mesmo composto, jogo novo; pista seca deixa
  intermediário/chuva apagados (ainda escolhíveis).
- Flags de captura: `--pit` (abre a tela do box) e `--tap` (leva um carro ao box e abre o mini-jogo).

## Rostos e ambiente nos menus (decisão do usuário: "Rostos + ambiente nos menus")
- Rostos (só locais, `game/local/drivers/`; sem foto, iniciais na cor da equipe): placas da tela inicial,
  cartões dos pilotos no painel do fim de semana, vencedor do GP, cartões da corrida, rádio, box e resultado.
- Ambiente na cor da equipe: já vem de `ScreenKit.garage_page` em todas as telas Garagem (início, GP, fim de
  semana, treino, campanha, corrida, box). A classificação ao vivo também foi migrada (mesmo layout do treino).

## Balanceamento do desgaste de pneus (pedido do usuário, valores PROVISÓRIOS)
- Problema: em corridas curtas (25%) o desgaste crescia na proporção cheia (÷ duração) e o pneu morria em ~6–8
  voltas, com 2–3 paradas em 18 voltas.
- Ajuste: o multiplicador de corrida curta agora é `1 / duração^0,5` (`RaceSim.WEAR_SHORT_RACE_EXP`) e o desgaste
  base dos compostos secos caiu ~9% (macio 0,042 · médio 0,028 · duro 0,020 por volta).
- Resultado medido (`tools/race_report.gd --weather=dry`, 4 sementes, Interlagos): 25% → quase todos 1 parada;
  50% → 1–2; 100% → 2 (às vezes 3 com SC). Ferramenta ganhou `--weather=dry`.
- Rever depois com a pesquisa de atributos e circuitos de alto desgaste (`tyre_wear_factor`).

## P&D (árvore do carro) e Fábrica — respostas do usuário (2026-11-02), mockups v9 aguardando aprovação
- Referência: árvore do F1 2017 (Codemasters): 4 departamentos (Motor, Aerodinâmica, Chassi, Durabilidade), cada um
  com 4 categorias em braços (as duas últimas sempre "Eficiência do departamento" e "Controle de qualidade") e nós
  menor (hexágono) / importante (quadrado) / definitiva (quadrado grande). Motor só desenvolve com motor próprio.
- **Moeda: dinheiro do orçamento** (sem Pontos de Recurso). Cada nó tem custo em US$ mi.
- **Tempo: dias de calendário**, com limite de projetos simultâneos definido pela fábrica.
- **Carro do ano seguinte: duas abas (carro atual / próximo), mesma reserva de dinheiro e de projetos.**
- **Fábrica: 4 estruturas** com níveis 1–5: Túnel de vento e CFD · Simulador e centro de dados · Fábrica de peças e
  controle de qualidade · Marketing, mídia e patrocínios. Uma obra por vez em cada estrutura.
- Modo Essencial (diretor técnico escolhe os projetos dentro de um teto de gasto) × Avançado (jogador escolhe),
  trocável a qualquer momento (decisão anterior #31).
- Efeito na pista (PROVISÓRIO): nós somam à nota do carro (`car_rating`); durabilidade reduz falhas. Valores de custo,
  prazo, nota e níveis dos mockups são exemplos.

### P&D e Fábrica implementados (mockups v9 aprovados pelo usuário)
- `CarDevelopment` (sem tela): 92 nós (4 depts × 4 braços); custo em US$ mi, dias de calendário, vagas de projeto =
  nível da fábrica de peças (mín. 2); chance de acerto = 58% + túnel (aero) ou fábrica de peças (demais) + nós de
  qualidade; defeito de produção devolve metade do dinheiro; resultado parcial rende metade do efeito.
- Efeitos: nós "perf" somam à `car_rating` da equipe; "rel" reduz quebras (`failure_mult`); "eff" reduz dias do
  departamento; "qual" soma chance de acerto. Simulador aumenta o ganho dos treinos; marketing, o patrocínio.
- Virada de temporada: o carro do ano seguinte vira o atual; o carro velho deixa 50% do bônus. Projetos do carro
  velho não terminados são perdidos.
- Modo Essencial: o diretor técnico preenche as vagas livres (teto US$ 40 mi/mês, 30% para o carro do ano seguinte),
  com foco escolhível; no Avançado nada é automático. Trocável a qualquer momento.
- Telas: `campaign_car_screen` (Carro) e `campaign_factory_screen` (Fábrica), abas na sede (`ScreenKit.campaign_nav`).
  Capturas: `--car` / `--factory` (+ `--fresh --demo --team=<id>`).
- Pendente: IA das outras equipes não desenvolve (o jogador pode ultrapassar com o tempo); balancear custos/efeitos.

## IA rival e Pessoal/Contratos (2026-11-02)
- **IA rival (implementada)**: as outras equipes evoluem a nota do carro ao longo do calendário: ganho anual =
  3,0 (fácil 2,0 · difícil 4,5) × fator do ranking (mais estrutura, mais ganho) × sorte da temporada (0,55–1,45);
  na virada guardam 50% do ganho. A meta da diretoria usa a nota de base (não muda no meio do ano).
- **Pessoal e contratos — respostas do usuário**: escopo = **pilotos + diretor técnico e engenheiros**; contratos
  **vencem na virada** e a negociação é **a qualquer hora** (troca só vale na virada; piloto de outra equipe só depois
  que vence ou pagando multa); a **IA também renova, dispensa e contrata na virada** e os que sobram viram agentes
  livres. Contrato simples: salário + duração → aceita / recusa / contraproposta.
- Mockups v10 (`v10-1-pessoal`, `v10-2-negociacao`) aguardando aprovação. Técnicos de exemplo são fictícios; salários
  e notas PROVISÓRIOS. A aba "Pilotos" da sede passa a se chamar "Pessoal".

### Pessoal e contratos implementados (mockups v10 aprovados)
- `Personnel` (sem tela): contratos de pilotos e técnicos, mercado (livres, F2/F3, outras equipes, agentes livres reais
  PROVISÓRIOS em `free_agents.json`, técnicos FICTÍCIOS em `staff_pool.json` via `tools/make_staff_pool.py`), salário
  pedido por nota, avaliação aceita/contraproposta/recusa (apelo da equipe pelo ranking do carro), multa de 50% do salário
  restante para tirar alguém de outra equipe, assinaturas valem na virada. Folha entra no custo por corrida.
- Virada: a IA renova (≈70% + nota−75), dispensa e contrata (equipes melhores escolhem primeiro); o jogador recebe os
  contratos; vaga de piloto vazia é preenchida automaticamente (melhor custo-benefício). Grid sempre com 2 pilotos por equipe.
- Técnicos: diretor técnico reduz dias de todos os projetos e engenheiros melhoram dias e acerto do departamento.
- Tela `campaign_staff_screen` (aba Pessoal; captura `--staff --fresh --team=<id>`).

## Finanças e Patrocínios — respostas do usuário (2026-11-02), mockups v11 aguardando aprovação
- Patrocínio por **zonas do carro com valor** (asa traseira ×1,0 · laterais ×0,9 · bico ×0,7 · asa dianteira ×0,6 ·
  halo ×0,5): um patrocinador por zona, contrato de 1 a 3 anos, valor por corrida e bônus por pódio.
- **Marcas fazem ofertas** (mudam todo mês) conforme a influência; o jogador aceita, recusa ou pede mais.
- **Marcas reais só em texto, sem logos**, categorias seguras (sem tabaco/apostas).
- **Finanças = resumo claro**: receitas × despesas da temporada, projeção do caixa, histórico das temporadas.
  Empréstimo e teto de gastos ficam para depois (P12).

### Finanças e Patrocínios implementados (mockups v11 aprovados)
- `Sponsorship` (sem tela, `data/sponsors.json`, 28 marcas reais só em texto): patrocínio inicial escalado para o
  valor base da campanha (equilíbrio preservado); ofertas por zona mudam todo mês (3 marcas de nível ≤ influência);
  "pedir mais" 1× por oferta (chance 35% + 5%×influência de subir 15%, senão a marca desiste); rescindir paga multa
  (meia temporada por ano restante); contratos vencem na virada.
- Livro-caixa (`Campaign.ledger`): patrocínios, bônus por pódio, prêmio, operação, folha, manutenção, P&D, obras,
  contratos/multas e dívida; histórico do caixa por rodada (`cash_log`) e projeção do fim da temporada.
- Abas da sede: Início · Campeonatos · Pessoal · Carro · Fábrica · Patrocínios · Finanças.
- Efeito do marketing mudou: a fábrica sobe a influência (nível das marcas) e o valor das ofertas (×), não multiplica mais o
  patrocínio já contratado. Balanceamento: com folha de pagamento e manutenção, o saldo por corrida fica ligeiramente
  negativo para a maioria — o prêmio do fim da temporada fecha a conta (PROVISÓRIO).

## Dados reais — atributos dos pilotos (respostas do usuário, 2026-11-02)
- **6 atributos + potencial** (0–100): ritmo, classificação, regularidade, ultrapassagem/defesa, chuva, gestão de pneus.
  A nota geral é a média ponderada (30/15/15/20/10/10). Entram na simulação: ritmo (volta), classificação (volta lançada),
  regularidade (erros, incidentes, problemas no treino), ultrapassagem (vantagem na disputa), chuva (perda de tempo
  molhado), pneus (desgaste); idade/potencial mudam as notas na virada da campanha (jovens sobem, > 33 anos caem).
  F2/F3 e agentes livres sem atributos usam a nota geral.
- **Dados verificados**: nascimento e títulos mundiais até 2025; equipes: chefe de equipe, diretor técnico (só os
  confirmados), estreia e títulos de construtores; o resto é null ("—"). **Altura, peso, vitórias e pódios** ainda não
  entram: as buscas e o acesso a páginas de estatísticas na nuvem não deram fonte confiável (nada inventado).
- Os valores dos atributos são **estimativa do projeto** (resultados 2024–2025 e reputação), não dados oficiais.
- **Ficha do piloto implementada** (mockup v12 aprovado): toque num piloto (seu ou do mercado) abre a ficha; "Negociar/Renovar" leva à folha de contrato; técnicos vão direto à negociação. Captura: `--staff --fresh --team=<id> --profile=<id>`.

### Dados reais pesquisados (2026-11-02, sites liberados pelo usuário)
- Retrato de **02/11/2026 (após o GP do México, 20 rodadas)** em `tools/research/snapshot_2026-11-02.json`, com fontes: Wikipedia
  (carreira e títulos), RacingNews365 (altura e peso; chefes de equipe), PlanetF1 (alturas de 10 pilotos e nascimentos conferem),
  ESPN (pontos de pilotos e construtores). Bearman: PlanetF1 (1,88 m) × RacingNews365 (1,84 m) em conflito -> altura vazia.
- **Notas dos carros recalibradas pela temporada real**: 74 + 19×raiz(pontos/líder): Mercedes 93, Ferrari 91, Red Bull 88,8,
  McLaren 88,5, Racing Bulls 81,9, Alpine 80,3, Haas 78,2, Audi 77,9, Williams 76,6, Aston Martin 76, Cadillac 74.
- **Atributos dos pilotos**: base estimada (reputação, 2024-2025) ajustada pelo desempenho de 2026 contra o companheiro (até ±5);
  Antonelli (campeão de 2026, 9 vitórias) tratado à parte. Continua estimativa, não dado oficial.
- Chefes de equipe: Stella, Wolff, Mekies, Vasseur, Vowles, Permane, Newey (Aston Martin), Komatsu, Wheatley, Lowdon; Alpine sem
  chefe oficial (Briatore assume as funções, Steve Nielsen é diretor-geral). Diretores técnicos só onde há fonte recente
  (Waché, Fallows, Elliott (CTO da Alpine), Chester); o resto fica "—".
- Nota técnica: o `WebFetch` não resolve esses sites; a pesquisa foi feita com `curl` no terminal (a rota de rede é outra).

## Eventos inesperados e Conselho de regras — respostas do usuário (2026-11-02), mockups v13 aguardando aprovação
- **Eventos (4 tipos)**: pilotos (lesão, crise emocional, proposta de outra equipe), calendário (corrida cancelada), equipe e
  fábrica (incêndio, peças com defeito, patrocinador sai) e mercado/finanças (crise econômica, apoio do país-sede).
  Tom sóbrio; criminal/escandaloso só com personagens fictícios. Frequência configurável (desligados/raros/normais/frequentes).
- **Resposta: consequência automática com aviso** (sem escolhas): cartão ao avançar o tempo + lista de notícias na sede.
- **Conselho de regras (1ª versão)**: pontuação, corridas sprint e regra de pneus; valem na temporada seguinte.
- **Votação**: todas as equipes votam (IA pelo próprio interesse); o jogador só vota, **sem lobby**; maioria simples
  (empate barra a proposta).

### Eventos inesperados e Conselho de regras implementados (mockups v13 aprovados)
- `CampaignEvents` (`data/events.json`): sorteio por dia (raros ≈1/60 dias, normais ≈1/28, frequentes ≈1/14), 10 eventos em 4 categorias,
  consequência automática + notícia. Lesão troca o titular por um reserva da F2/F3 no grid (volta depois das corridas de afastamento),
  crise reduz ritmo/regularidade por rodadas, corrida cancelada é pulada no calendário, incêndio atrasa projetos e custa caixa,
  lote defeituoso perde um projeto, patrocinador sai sem multa, avanço adianta um projeto, crise econômica reduz ofertas, apoio do país-sede soma caixa.
- `Regulations` (`data/rules.json`): pontuação, número de fins de semana sprint e compostos obrigatórios; 3 propostas por fim de temporada, todas as
  equipes votam (IA por força do carro + 15% de ruído), jogador só vota, maioria simples, empate barra; valem na temporada seguinte e entram nos
  fins de semana (`points_race`, `sprint`, `min_dry_compounds`).
- Telas: cartão de evento na sede (`EventCard`), lista e frequência (`NewsSheet`, botão Notícias), `campaign_council_screen` (aba Conselho, botão no relatório).

### Ajustes de jogabilidade pedidos após testar o APK (2026-11-02)
- **Som na corrida** (muda a decisão antiga de deixar som fora): ronco de fundo de vários carros, passagens de carro
  alternadas (3 variações com efeito Doppler, em intervalos aleatórios), torcida em loop, torcida vibrando nas ultrapassagens
  (mais forte com os carros do jogador) e na bandeirada, semáforo da largada, pistola do box nas paradas do jogador, clique de
  rádio e alerta de bandeira/safety car. Sons **originais por síntese** (`tools/make_sounds.py` → `game/assets/audio/`);
  botão de som na barra da corrida. Código: `src/audio/race_audio.gd` (só escuta os sinais do RaceSim).
- **Zoom da pista**: pinça com dois dedos (tratada à mão, porque no celular o gesto chega como dois toques), botões + / −
  na pista e roda do mouse; distância entre 40 e 4000 m.
- **Bolinhas na cor da equipe** no lugar dos carros 3D; os carros do jogador são maiores e têm anel branco — sem siglas.
- **Letra maior em todo o jogo**: `UiStyle.fs()` — até 22 px cresce 20% (12 → 14), títulos ganham +4 px. Tudo passa por ela.
- **Arrastar para rolar** em todas as listas, tabelas e faixas laterais: `DragScroll` lê o arrasto antes dos botões; arrastar
  não aperta botão; inércia ao soltar. Colunas que passam do fim da tela rolam (`ScreenKit.scroll_column`), a barra de abas da
  campanha e os blocos do treino deslizam para o lado, e a tabela de Dados da corrida desliza para o lado.

### Marcadores estilo MM3, zoom só por pinça e som refeito (2026-11-03)
- **Marcador do carro** (`CarMarker3D`): disco plano na cor da equipe com o **número do piloto** por cima, sempre de frente
  para a câmera e com tamanho constante na tela; carros do jogador maiores e com anel branco; o líder desenha por cima.
  Testado número × logo da equipe dentro da bola: **número venceu** (identifica o piloto; o logo repete nos dois carros e some pequeno).
- **Cores de equipe distintas**: Williams passou de `#1868DB` para `#1347F5` (estava quase igual à Red Bull); teste garante distância mínima.
- **Zoom**: só pinça com dois dedos (e roda do mouse). **Sem botões + / −** na tela.
- **Som refeito**: a 1ª versão soava como sirene (tons puros que deslizam + alerta de dois tons). Agora cada explosão do motor é um
  estalo áspero com irregularidade, passagens com Doppler sobre cada estalo, avisos viraram toques curtos. Segue por síntese (`tools/make_sounds.py`).

### Corrida refeita estilo MM3 e classificação jogável (2026-11-03, mockups v14)
- **Corrida**: a pista 3D ocupa a **tela toda**; por cima, barra de topo (voltar, GP, pausa/velocidades, selo do clima, Dados, som, volta),
  **cartões dos seus pilotos na vertical à esquerda** (236 px, foto de 62 px com a posição num selo, sem a fileira de pneus — o pneu
  se escolhe na tela do box) e a **torre à direita** (290 px). Painéis são "vidro escuro" translúcido (`UiStyle.G_GLASS`).
- **Radar de chuva saiu da pista**: vive em **Dados > Clima**; na barra fica só um selo ("Seca · chuva 67% em 6–8 v") que abre essa aba.
  O rádio virou faixa baixa no centro da área livre.
- **Classificação jogável**: a mesma pista 3D mostra os carros andando (volta de saída, lançada e de entrada) via `TrackFeed`; o jogador
  escolhe o pneu e manda cada piloto sair (como já era), vendo a volta acontecer. Tocar na foto segue o carro. Nível de controle escolhido:
  **ver ao vivo e mandar sair** (sem ordens durante a volta e sem setores — ficam como ideia futura).
- **Bug corrigido**: `QualiSim.advance` e `PracticeSession.advance` descartavam o resto do quadro (a 60 fps e 4× cada quadro dá menos de um
  passo), então o relógio **não andava** na tela e só dava para "simular". Agora acumulam o resto (teste `test_session_clock`).

### Fundo dos logos e logos de volta (2026-11-03)
- Campo opcional `emblem_bg` em `teams_2026.json` define o fundo do quadradinho do logo (usado por `TeamEmblems._frame_color`).
  McLaren **laranja** `#FF8000` (caía no preto porque o laranja passa do limite de luminância); Racing Bulls **azul-marinho** `#26398C`
  (melhor contraste com o logo branco e distinto da Red Bull e da Williams; testado contra vermelho, azul real e azul escuro).
- Os logos das equipes voltaram nos cartões dos pilotos (canto da foto) e na tabela da classificação. Nos marcadores da pista 3D continua o número.

### Equilíbrio de forças, notas, incidentes, largada e pódio (2026-11-03)
- **Notas dos pilotos (definidas pelo usuário)**: Verstappen 96, Leclerc 93, Hamilton 92, Antonelli 90, Alonso 89, Norris 88,
  Russell 87, Bearman 85, Sainz 84, Piastri 83, Gasly 81, Hadjar/Hülkenberg/Pérez 80, Albon 79, Bortoleto/Ocon 78, Lawson 77,
  Lindblad/Bottas 75, Colapinto/Stroll 74. Atributos por perfil (reputação + estatísticas de carreira) em `tools/enrich_drivers.py`,
  com média ponderada exatamente igual à nota.
- **Base e outras categorias** (`tools/rescale_feeder_ratings.py`): F2 64–78, F3 50–70 (escolha do usuário), IndyCar/WEC/FE topo 84,
  mediana ~78, piores abaixo de 74. Colton Herta saiu da F2 (é da IndyCar; já está nos agentes livres).
- **Carros mais equilibrados (estilo 2012)**: escala 79–90 (`tools/enrich_teams.py`); `CarForm` dá a cada equipe uma forma por GP
  (variação normal, afinidade com a pista e 20% de chance de fim de semana muito bom/ruim). Pesos calibrados com
  `tools/balance_report.gd` (Shapley do R² da posição final): **sem incidentes, seco: carro 53,6% · piloto 23,6% · resto 22,7%**
  (alvo 55/25/20). Com incidentes e clima, Alpine, Haas e Racing Bulls venceram corridas em 30 GPs de teste.
  `CAR_K` 0,07→0,105, `DRIVER_K` 0,035→0,019, `RACECRAFT_K` 0,012→0,009. Equipe criada: 77–82 na nova escala.
- **Mais erros e quebras**: erros de piloto 0,0013→0,0024 por volta (novo: travada/escapada com pneu "quadrado"; rodadas danificam a asa
  com mais frequência; escapadas podem danificar o assoalho); quebras 0,0004→0,0018, 35% delas parciais (o carro segue mais lento até
  o fim). Resultado na seca: ~2,5 abandonos por corrida (0 a 5).
- **5 luzes de largada** (`StartLights`): acendem uma a uma, espera variável e apagam — só então a corrida começa (som sincronizado).
- **Bandeira quadriculada** ao lado do nome na torre para quem recebeu a bandeirada.
- **Pódio animado** (`PodiumView`): 3º, 2º e vencedor sobem nos degraus com foto, logo e confete; botão leva ao resultado completo.
- Correção: a herança de desenvolvimento da IA na virada era calculada equipe por equipe, mudando a ordem das seguintes; agora calcula tudo antes.

### Torre estilo TV, bateria, ultrapassagens, animações e cartão do piloto (2026-11-03)
- **Torre** (`StandingsPanel`, 266 px): posição na cor da equipe · emblema · seta verde/vermelha ao ganhar/perder posição (vira bandeira
  quadriculada após a bandeirada) · **sigla de 3 letras** · diferença (ou NO BOX em vermelho, RODOU, FORA) · pneu · idade/vida ·
  **extras na ponta direita, alinhados** (volta mais rápida e investigação/punição; cabem os dois). Volta atual no cabeçalho da torre
  (o contador vermelho da barra de cima saiu). Classificação também usa as siglas.
- **Bandeira do país** translúcida atrás do nome do GP (`ScreenKit.flag_title`; bandeiras flag-icons, MIT; `country_code` nos circuitos).
- **Bateria**: Equilíbrio recarrega +5%/volta (antes 0), Carregar +18%, Usar −14%; o bônus de ultrapassagem gasta 3% e só é usado quando
  faz diferença, no máximo uma vez por volta (antes era gasto em toda tentativa e a bateria vivia vazia). Largada com 80%.
- **Ultrapassagens um pouco mais fáceis** (vantagem mínima 0,45→0,40 s, dificuldade da pista 1,5→1,4, ar sujo 0,3→0,25 s): ~1,2–1,4×
  mais trocas de posição. Equilíbrio conferido depois: carro 53,6% · piloto 23,2% · resto 23,2%.
- **Animações na pista** (`MarkerMotion`): ultrapassagem = o carro de trás passa por dentro do outro em ~1,2 s; rodada/escapada = sai da
  pista (anel amarelo piscando), para e volta; batida/quebra = fica parado fora da pista, apagando, por ~14 s.
- **Cartão do piloto**: faixa na cor da equipe, logo ao lado da foto, posição que pulsa verde/vermelho ao mudar, velocímetro no ritmo e
  ícone de bateria com a carga (raio ao usar, seta ao carregar); tocar no cartão segue o piloto na pista (cartão destacado).
- Correção: o fundo vermelho do `CutButton` ficava cinza depois de o botão voltar a ficar ativo.

### Decisões a partir da análise externa (2026-11-03)
- **Classificação** (fazer primeiro): (1) **abortar ou repetir a volta** — quando a volta lançada é comprometida (tráfego, erro), o
  rádio oferece continuar, abortar e tentar de novo, ou voltar ao box; sem resposta, o piloto decide. (2) **Plano de 1 ou 2 voltas
  rápidas** por saída. (3) **Objetivo da volta (garantir tempo × buscar o limite) é decidido pelo PILOTO**, não pelo jogador: depende da
  "leitura de corrida" (regularidade + ultrapassagem/defesa, sem atributo novo), da situação da sessão (zona de eliminação, tempo,
  disputa da pole) e, na campanha, da situação no campeonato. Janela de saída com previsão de tráfego: **não**.
- **Corrida** (depois): manter os botões de ritmo e bateria e **somar planos** com duração (atalhos; o piloto ajusta ritmo e bateria
  durante o plano); **reagir à parada do rival** (cobrir / estender / manter); **desacelerar em momentos-chave** (opção). Previsão de
  retorno do box e engenheiro explicando o resultado: não por enquanto.
- **Implementado (classificação)**: `QualiSim.choose_lap_mode` (garantir: +0,10 s e metade do risco; limite: −0,12 s e 1,8× o risco; acerto
  da escolha 55–95% pela leitura de corrida; líder do campeonato evita risco desnecessário, a partir da metade da temporada); plano
  1/2 VOLTAS no cartão; problema da volta sorteado no início e revelado no meio (25–70%) → rádio Continuar / Abortar e tentar de novo
  (volta lenta até a linha, pneu usado) / Voltar ao box; 25 s de sessão para responder, senão o piloto decide; rivais decidem sozinhos.
  "Pausa em decisões" (padrão SIM) baixa a velocidade para 2× quando o rádio pergunta.

### Campanha — próximas frentes (2026-11-04)
O usuário marcou as quatro frentes: pilotos novos ao longo dos anos, estúdio de design, regras técnicas que mudam, dinheiro e pessoas.
- **Aposentadoria**: idade mínima 32 e máxima 47; a média fica em 36–37 anos, com exceções (pilotos muito bons ou muito
  ruins podem fugir da curva).
- **Corpo técnico**: além do chefe de equipe e dos pilotos, cada equipe tem **somente 4 cargos**, escolhidos pelo Claude como os
  mais importantes da vida real. Nomes **reais** de 2026 quando encontrados em fonte; senão, nomes genéricos. Cada um tem
  **nota**, como os pilotos, e influencia diretamente a qualidade dos treinos livres, o desenvolvimento das atualizações do carro etc.
- Ordem de trabalho: (1) aposentadoria + pilotos novos + corpo técnico; (2) regras técnicas que mudam; (3) dinheiro e pessoas;
  (4) estúdio de design (precisa de mockups antes).
- **Implementado (2026-11-04) — carreiras** (`DriverCareer`): risco de aposentadoria por idade de 32 a 47 (craques ×0,55, fracos ×1,4,
  sem vaga ×1,8, com contrato ×0,4; o seu piloto cumpre o contrato). Medido em 4 campanhas × 20 anos: **média 36,8** em regime
  estável (os veteranos de 2026 puxam a média dos primeiros anos para cima). A base (F2/F3) e os pilotos de outras categorias
  agora são da campanha: evoluem para o potencial, os 6 melhores da F3 sobem para a F2, F2 com mais de 26 anos ou excedente fica
  "sem vaga", e **pilotos novos fictícios** (16–18 anos, nomes de `data/name_pool.json`, 8% de chance de "joia") completam a F3
  todo ano — em 20 anos ~20 deles chegam à F1 por campanha. Idade da base: ano conhecido ou estimado (`tools/add_ages.py`).
- **Implementado (2026-11-04) — corpo técnico** (`data/staff_2026.json`, `tools/make_staff_2026.py`): 4 cargos escolhidos pelo
  Claude — **diretor técnico** (todos os departamentos de P&D), **chefe de aerodinâmica** (depto. aero), **projetista-chefe**
  (chassi, durabilidade e motor) e **diretor de engenharia de pista** (ganho dos treinos livres: ±1,2% por ponto acima de 75).
  34 dos 44 nomes são reais com fonte (cargo da equipe em `real_title`); sem fonte, nome fictício. Notas = estimativa.
  Equipes da IA: corpo técnico melhor desenvolve o carro mais rápido (±1,5% por ponto da média acima de 82) e treina melhor;
  na virada a IA renova (85%) ou contrata o melhor livre do cargo. Substituiu os 5 cargos antigos (saves antigos são refeitos).

### Campanha em 3 categorias — F3, F2 e F1 (2026-11-04, a fazer depois das frentes já combinadas)
- Começar a campanha na **F3, F2 ou F1**, com equipe real da categoria ou equipe criada. Os **3 campeonatos** correm sempre
  (as categorias em que o jogador não está são simuladas rodada a rodada, com tabelas atuais).
- **Acesso e rebaixamento automáticos** todo ano, para todas as equipes (inclusive a do jogador): campeão de construtores da F3 sobe
  e o último da F2 desce; campeão da F2 sobe e o último da F1 desce. O número de equipes por categoria nunca muda.
- **Grids reais**: F1 11×2, F2 11×2, F3 10×3. Equipe criada entra **no lugar** de uma equipe da categoria inicial.
- **Formato real** na F2/F3: um treino, classificação de sessão única, sprint com os 10 primeiros invertidos e corrida principal com
  parada obrigatória.
- **Equilíbrio na F2/F3** (carros iguais): ~30% carro / 50% piloto / 20% decisões; F1 continua 55/25/20.
- Equipe promovida/rebaixada **mantém os pilotos com contrato** (a IA pode trocar quem não tiver nível).
- Equipe que sobe para a F1 entra com o **carro mais fraco**, motor de fornecedor e **verba de entrada** para montar a fábrica.
- **Tabelas novas** (design inovador, mockup antes): grade de resultados por corrida (cores de pódio/pontos/abandono), destaques do
  top 3 com fotos e logos, e zona de acesso/rebaixamento nos construtores.
- **Nomes, fotos e logos oficiais** de F2/F3 2026 enviados pelo usuário: ficam só em `game/local/` (fora do git, APK pessoal),
  como já é com F1. Fotos precisam de **fundo transparente**: o avatar já pinta o fundo com a cor da equipe ATUAL, então a foto
  acompanha a troca de equipe automaticamente.

### Regras técnicas — implementado (2026-11-04)
Decisões do usuário: o Conselho pode mudar **motor, aerodinâmica, chassi/peso, reabastecimento e calendário**; valem na temporada
**seguinte**; ano de virada embaralha **bastante, mas com lógica**; as regras **mudam a corrida**.
- `TechRules` (efeitos, PROVISÓRIO): motor V6 híbrido (2026) / V8 / V10 / híbrido com mais elétrico (tempo de volta, peso dos modos de
  energia e da bateria, som mais agudo no V8/V10); aerodinâmica ativa / efeito solo (ultrapassar −25% de vantagem exigida, ar sujo
  ×0,6) / asas com DRS (−15%, ar sujo ×1,3); chassi padrão / leve (−0,8 s, pneu ×0,9) / pesado (+0,6 s, ×1,15); reabastecimento
  (largam leves, tanque dura 42% da corrida → pelo menos 2 paradas, +3,5 s parado); calendário 20 ou 22 corridas (saem Madri e Catar).
- Conselho: além das 3 esportivas, **1 proposta técnica por temporada**. Motor, aerodinâmica e chassi novos = **ano de virada**
  (`Campaign.regulation_reset`): notas dos carros se aproximam pela metade, desenvolvimento antigo vale 40%, o carro do ano seguinte
  da P&D vale inteiro, corpo técnico ajuda (±0,12 por ponto da média acima de 82), sorte do fabricante quando o motor muda, ±1 de acaso.
- Correção: a chance de ultrapassagem usava uma segunda conta da vantagem exigida, sem os ajustes (defesa forte já estava somada
  duas vezes); agora uma conta só.

### Elenco oficial F2/F3 2026 e fotos (2026-11-04)
- Zip do usuário (fontes fiaformula2.com / fiaformula3.com): equipes de cada piloto (`series_team`), **Colton Herta volta para a F2
  (Hitech)** — tinha sido removido por engano —, Nico Varrone (F2) e 8 estreantes da F3 entram (notas estimadas). F2 = 22, F3 = 35
  inscritos; tamanhos da carreira passam aos reais (F2 22, F3 30). `tools/sync_feeder_roster.py`.
- Fotos e logos ficam **só em `game/local/`** (rostos via `tools/prepare_portraits.py`, que agora lê F2/F3 e subpastas; logos em
  `game/local/series/f2|f3/`), fora do git, para o APK pessoal.

### Campanha reestruturada a partir do prompt mestre (2026-11-04)
Diagnóstico: a P&D vira bônus direto na nota da equipe (os dois carros, sem peça física); nota única por equipe e pistas sem perfil;
sem componentes/limites; IA só mexe no mercado na virada; finanças sem compromissos futuros; sede sem "assuntos".
Respostas do usuário:
- **Peças: ciclo completo por carro** — pesquisa libera a especificação → fabricar unidades (custo/prazo da fábrica) → instalar em
  cada carro; estrear num piloto só, esperar a segunda unidade ou pagar para acelerar; só o carro equipado ganha o efeito.
- **Carro com 4 características**: velocidade de reta, curvas lentas, curvas rápidas e confiabilidade; cada pista com um perfil;
  aerodinâmica como compromisso; a nota geral continua como resumo.
- **Componentes simplificados com punição**: unidade de potência e câmbio com limite por temporada, desgaste por corrida, risco de
  quebra com peça gasta, punição de grid acima do limite; preparação automática com preferência e aviso antes do GP.
- **Ordem**: ciclo de peças primeiro (com a sede nova), depois finanças/mercado; depois estúdio de design e 3 categorias.
- **Mercado: só contratos futuros** (jogador e IA assinam durante o ano, entrada na virada, cadeia F1→F2→F3); sem troca imediata.
- **IA com perfis por objetivo**: candidata ao título (ritmo e experiência), meio (custo-benefício), reconstrução (potencial, salário).
- **Finanças**: patrocínio garantido × por meta; compromissos futuros separados do saldo; prêmio de construtores pela posição
  oficial. (Simulação "e se" não foi escolhida.)
- **Sede**: próximo GP + até 3 assuntos (NOTÍCIA × DECISÃO) com atalho e "avançar com preparação recomendada" — mockup antes.
- **Tela de peças centrada no carro** (pedido 2026-11-04): carro da categoria visto de cima, nas cores da equipe, com etiquetas
  apontando para cada peça (asa dianteira, asa traseira, assoalho, suspensão, unidade de potência, câmbio). Tocar abre um painel
  com **Usar** (unidades com anel de desgaste e para onde vai cada uma) e **Desenvolver** (direções da próxima versão com efeitos,
  custo, prazo e GP previsto). Mockups v15-2/2b/3/4 aguardando aprovação.
- **P&D ligada à equipe técnica e à fábrica** (2026-11-04): prazo e qualidade das pesquisas dependem das notas do corpo técnico
  (chefe de aerodinâmica, projetista, diretor técnico) e do nível das instalações (túnel de vento etc.).
- **Upgrade pode dar errado**, para o jogador e para a IA: cada pesquisa tem chance de acertar, de render menos ou de piorar
  (correlação túnel × pista); a chance vem da equipe técnica + fábrica + ousadia da direção. O resultado real só aparece na
  pista; o jogador decide voltar à versão anterior, corrigir ou testar mais. Assim a ordem de forças muda ao longo do ano.
- **Interface**: todos os menus novos devem ser os mais bonitos e interativos possíveis, com símbolos no lugar de texto longo
  sempre que der, criativos e simples.
- **Mockups do passo 1 aprovados** (2026-11-04): Peças com carro interativo, Desenvolver com chance de acerto, upgrade que
  falhou, pesquisa concluída e Sede.
- **Upgrade errado só aparece depois da corrida**: o jogador corre um GP inteiro com a peça antes de saber o resultado real
  (mais arriscado); só então decide voltar, corrigir ou testar mais.
- **Implementação (simulação) do ciclo de peças** (2026-11-04): `CarParts` por equipe (jogador e IA). Carro com
  características de fábrica (`car_traits` em teams_2026.json: desvio de reta/lentas/rápidas + confiabilidade) e pistas com
  perfil (`profile` nos circuitos). A árvore de P&D não soma mais direto na nota: os nós de desempenho viram
  **conhecimento** (+15% por ponto no tamanho das peças novas do departamento) e, os do carro do ano seguinte, base do carro
  novo. Desgaste das unidades (asas, assoalho, suspensão) tira rendimento a partir de 60%. Calibração: a IA ganha em média
  +3 de nota por temporada (como antes), mas cada equipe varia de ~+1 a ~+5 conforme acerta ou erra
  (`tools/parts_report.gd`).
- **Menu principal e escolha de equipe aprovados** (2026-11-04, mockups v16): menu só com logo e modos; escolha de
  equipe dentro de cada modo. Ajuste: todos os blocos da fileira de emblemas com a cor de fundo da equipe (não só o
  escolhido). Na Campanha, primeiro a pergunta "Equipe real" × "Criar equipe"; depois a escolha.
- **Campeonato ao vivo na corrida** (2026-11-04, mockups v17 aprovados): pop-up "se terminar assim" de pilotos e de
  construtores só quando a projeção muda a ordem do top 5 (no máximo 1 a cada 3 voltas) e o cartão dourado "título em
  jogo" na hora em que a corrida, terminando assim, decide o título. Só na campanha (no Grande Prêmio avulso não há).
- **Estúdio de design implementado** (2026-11-04, mockups v18): aba Design na campanha. Lançamento do carro na virada:
  nota da crítica 1–5 → bônus das marcas (até US$ 0,9 mi) e confiança da diretoria (−2 a +5). Pinturas especiais valem no
  GP escolhido e zeram a cada temporada.
- **Demissão com proposta** (#17): ao ser demitido, até 3 equipes da metade de baixo do grid oferecem o cargo; aceitar troca
  de equipe no mesmo mundo (grid, histórico, regras), e a equipe antiga passa para a IA.
- **Item 5 — dinheiro e estrutura (respostas de 2026-11-04)**: **teto de gastos com trava rígida** (não deixa gastar além
  do limite anual: projetos e peças ficam bloqueados quando acaba); **restrição de túnel de vento pela posição do ano
  anterior** (campeão ~70% do tempo de pesquisa aerodinâmica, último ~115%; muda dias e chance das pesquisas de aero, também
  para a IA); **empréstimo: banco com juros e adiantamento de patrocínio**; **academia de pilotos fica para depois**.
- **3 categorias — fase 1 aprovada** (2026-11-04, mockups v20): F2 e F3 correm em paralelo (simuladas rodada a rodada,
  nomes reais das equipes; emblemas originais no jogo, logos oficiais só em `game/local/`), tabelas novas das 3 categorias,
  acesso/rebaixamento das equipes no fim do ano (campeão da F3 ↑ F2, último da F2 ↓; campeão da F2 ↑ F1, último da F1 ↓),
  equipe que sobe para a F1 com o carro mais fraco, motor de fornecedor e verba de entrada. **Sua equipe rebaixada**: ela
  desce para a F2 e você recebe propostas de equipes da F1 (como na demissão). Jogar na F2/F3 = fase 2.
- **Auditoria e calibragem da economia** (2026-11-08, pedido "avalie o que dá para melhorar" → "1 e 2 juntos"): uma temporada
  no modo Essencial quebrava a equipe (caixa de 140 → 2 na rodada 18, falência na 2ª temporada) e o carro piorava. Correções:
  manutenção da fábrica pela metade; o teto de gastos reserva a operação e a manutenção do resto do ano (`cap_left_rd`); o
  diretor técnico (Essencial) tem verba mensal (caixa acima de US$ 25 mi + o que a temporada ainda rende, dividido pelos meses,
  limitado ao teto) e gasta 70% em **pesquisa de peças** (a árvore agora só dá conhecimento); o diretor comercial fecha as
  zonas de patrocínio livres. Resultado (tools/season_audit.gd, Williams, 3 temporadas): caixa sempre positivo (111 → 82 → 72
  no fim de cada ano), carro +2,4 / +1,9 / +1,3, meta cumprida.
- **IA de estratégia com plano de corrida** (2026-11-08, pedido do usuário + auditoria): cada carro da IA decide na largada
  quantas paradas e em que voltas (stints quase iguais, um pouco antes do meio; variação por equipe; quem aposta faz uma parada a
  mais ou um primeiro stint longo), refaz o plano depois de qualquer parada fora dele, não para nas 3 últimas voltas sem
  emergência e, no safety car, só aproveita se a janela estiver perto ou o pneu gasto (quem aposta fica fora). Auditoria
  (tools/strategy_audit.gd, 24 corridas curtas no seco): paradas nas últimas voltas 232 → 12; corridas inteiras com mistura de
  1, 2 e 3 paradas espalhadas. Equilíbrio mantido: carro 56,4% / piloto 22,1% / resto 21,5%.
- **Números e idade (implementado 2026-11-08)**: o campeão de pilotos usa o 1 no ano seguinte; quem tinha o 1 volta ao número
  de carreira (Norris = 4). Novato que chega à F1: 50% mantém o número da categoria de base, 50% herda o de um piloto que
  saiu (sem repetir número em uso). Menores de 18 anos (na temporada do contrato) não entram no mercado da F1, não assinam e
  não servem de reserva.
- **IA reage aos rivais** (2026-11-08): perto da janela planejada, a IA cobre o undercut de quem vinha logo atrás (<2,5 s) e
  parou (equipes conservadoras cobrem mais) ou tenta o undercut em quem a segura há 2+ voltas (as que apostam tentam mais).
  Nas últimas voltas não para por pneu gasto (salvo pneu no limite) e no safety car do fim só troca quem está com pneu muito
  gasto. Item 6 da fila: a parte da IA está feita; os planos táticos do JOGADOR (tela) continuam pendentes.
- **Treinos sempre simulados + engenheiros de corrida** (respostas de 2026-11-08): o treino livre não é mais jogado ao vivo; o
  jogador escolhe os programas e o acerto é sorteado pela capacidade — **diretor (engenharia de pista) 35%, engenheiro de
  corrida 30%, piloto 15%, sorte 20%**. Engenheiros de corrida: 1 por carro nas 11 equipes, **nomes reais quando houver fonte**
  (senão genéricos), com nota, salário e contrato no mercado de Pessoal (a IA também troca). Mockup antes.
- **Pneus do fim de semana, saídas da classificação e estratégia** (respostas de 2026-11-08; vale para **todos os modos**):
  distribuição **real** (13 jogos secos: 8 macios, 3 médios, 2 duros; sprint 12 = 6/4/2; 2 jogos devolvidos depois de cada
  treino; 1 macio guardado para o Q3) e **o treino gasta sozinho** pelos blocos do programa. Classificação: ao mandar para a
  pista abre uma tela com todos os jogos disponíveis; o jogador escolhe o jogo, a **atitude em 2 níveis** (garantir tempo ×
  buscar o limite) e **1 ou 2 voltas rápidas** na saída. Estratégia antes da corrida: **passo antes da largada** (GP, campanha e
  corrida rápida) com o **plano pronto dos engenheiros, que o jogador pode alterar**; na corrida o plano **só avisa** (a parada
  só acontece se o jogador confirmar no box). O cartão do piloto **mantém o pneu atual só como informação**; o pneu só se
  escolhe na tela do box. Mockup antes.
- **F2/F3 jogáveis — fase 2** (respostas de 2026-11-08): F1/F2/F3 nos modos (Campanha e Grande Prêmio);
  no GP só aparecem as **etapas do calendário da categoria** (F2 14, F3 10). Carro: **nível de operação da
  equipe** (engenharia, mecânicos, simulador; sem árvore de P&D — o chassi é o mesmo). Dinheiro: **pilotos pagantes +
  patrocínio** (quanto melhor o piloto, menos paga; orçamento de poucos milhões). Acesso: **sobe automático com verba de
  entrada** a cada subida. Fim de semana: treino simulado; **classificação (sessão única), sprint (grid invertido) e corrida
  principal ao vivo**, com estratégia e grid de largada. Pessoal: **chefe de engenharia + 1 engenheiro de corrida por carro**
  (2 na F2, 3 na F3), genéricos, mercado próprio. Corrida: **sem bateria**, com **DRS** automático nas zonas. Regras reais a
  usar: F2 com dois compostos e parada obrigatória na corrida principal (sprint sem parada, 10 primeiros invertidos); F3 com
  4 jogos secos de um composto, sem parada obrigatória, sprint com os 12 primeiros invertidos. Mockup antes.
- **Modo Corrida rápida removido** (usuário, 2026-11-08: "modo corrida rapida nem é pra existir mais"): o menu tem Campanha e
  Grande Prêmio (Corrida Caótica segue bloqueada). "Só a corrida" continua como formato dentro do Grande Prêmio.
- **Histórico e animação de campeão** (respostas de 2026-11-08): aba **Histórico** na campanha com **Lendas = os 15 maiores
  campeões já aposentados** (pilotos em atividade entram quando se aposentam na campanha), **Pilotos atuais = só o grid da
  F1** (números até 2025 + o que a campanha somar) e **Campeonatos** (campeões de cada ano). **Animação de campeão = pista +
  pôster** (câmera no carro do campeão, pista na cor da equipe, fogos/confete; depois pôster com foto grande, "CAMPEÃO
  MUNDIAL", número e números da temporada), para **pilotos e construtores de qualquer equipe** (mais festa quando é a sua).
  Mockup antes.
- **Missões do stint no lugar da bateria** (respostas de 2026-11-09): a bateria (Carregar/Equil./Usar) passa para o piloto,
  que dosa ritmo, bateria e pneus volta a volta conforme as notas (regularidade, gestão de pneus, ultrapassagem). O jogador
  dá **missões**: uma **de base** para o stint e **missões curtas com fim automático** (terminada a curta, volta à base).
  Missões: **Atacar o carro da frente**, **Defender a posição**, **Poupar pneus até a volta X**, **Abrir gap / undercut**,
  **Ritmo seguro (trazer o carro)**. O piloto **pode discordar pelo rádio** (aceitar ou insistir; sem barra de confiança por
  enquanto). Substitui Poupar/Normal/Atacar e a bateria no cartão do piloto. Mockup antes.
- **2026-11-09 — Pneus mais no limite + estouro.** Nas corridas curtas (25%) o pneu fica mais perto do limite: o desgaste
  cresce quase na proporção da duração e a perda de ritmo do pneu também aumenta (~2,5x com 25%), para que **2 paradas não
  sejam muito piores** em algumas pistas e o **duro tenha papel**. Cada pista tem o seu desgaste (alto: Lusail, Silverstone,
  Suzuka, Barcelona; baixo: Mônaco, Las Vegas, Monza, Baku, Montreal). **Estouro de pneu**: possível com **20% de vida ou
  menos**, chance maior quanto menos vida (≈2%/volta com 15%, ≈7% com 10%, 30% com 0%); volta lenta até o box com troca
  obrigatória e dano no assoalho, ou abandono (~15%), com VSC/SC pelos detritos. O rádio avisa do risco.
- **2026-11-09 — Redesenho dos menus (inspiração: campanha do MM3, sem copiar).** Diagnóstico: a campanha estava ao mesmo
  tempo cheia de texto (10 abas escritas, frases nos cartões) e monótona (uma cor, cartões iguais, poucas imagens).
  Escolhas: **Início em mosaico** de blocos grandes com imagem + **barra de ícones** com rótulo curto no lugar das abas +
  barra fixa no topo com dinheiro e um botão **CONTINUAR**. Arte/3D: **pista 3D no cartão do próximo GP**, **Sede 3D
  isométrica**, **carro grande** (equipe/mosaico, pilotos com número gigante) e **calendário em cartões** (arte da pista,
  pneus do fim de semana, afinidade). Recurso novo: **Sede com instalações** que evoluem por níveis (item 11 do roadmap).
  Alcance: **mockups do jogo todo de uma vez** (tela inicial, GP, fim de semana e campanha). Mais símbolos, menos escrita,
  uma cor de destaque por seção.
- **2026-11-09 — Mockups v26 aprovados (todos).** Pedido extra: a **bandeira do país** aparece em todo cartão de pista
  (próximo GP, agenda, Grande Prêmio, fim de semana). Pista 3D dos cartões: vista do próprio cenário do jogo.
- **2026-11-09 — Setores na classificação.** No cartão de cada piloto do jogador (só na classificação), três faixas
  finas (sem texto, como na transmissão) acendem quando o carro fecha cada setor da volta lançada: **roxo** = melhor setor da sessão, **verde** =
  melhor setor do piloto, **amarelo** = mais lento que o melhor dele. O problema da volta (tráfego/erro) cai no setor em
  que aparece; voltas apagadas mostram as cores mas não contam como melhor.
- **2026-11-09 — Pistas 3D mais detalhadas e boxes corrigidos.** Pedido: pistas bonitas, coloridas e legíveis de longe,
  com a entrada dos boxes demarcada (referência de nível de detalhe: jogos de gestão; nada copiado). Feito em Godot, gerado
  em código (`CircuitDressing`): gramado aparado em listras, escapes (asfalto + brita) e barreiras de pneus nas curvas,
  muros com placas coloridas, pit lane com diagonais de entrada/saída zebradas, muro e tela do pit, linhas de limite de
  velocidade, prédio dos boxes com as cores das equipes, torre de controle, pórtico de largada, paddock com motorhomes,
  arquibancadas cobertas, passarelas, linha de chegada quadriculada; árvores de dois tipos; luz e cores mais vivas.
  Circuitos de rua (`"street": true`: Mônaco, Baku, Singapura, Las Vegas, Madri) têm calçada e muros colados na pista.
  Mônaco ganhou relevo (subida do Cassino) e porto com iates ao lado dos boxes; Silverstone, hangares do antigo aeródromo.
  **Boxes corrigidos** (entrada/saída reais): Interlagos 0,87 → 0,12 (depois da Junção até a Curva do Sol), Mônaco
  0,905 → 0,07 (piscina/Rascasse até depois da Sainte Devote), Silverstone 0,93 → 0,06 (depois do Vale até depois de
  Abbey). As outras 19 pistas ainda usam a entrada genérica (0,95 → 0,05) e precisam de revisão. O lado do pit lane é
  configurável (`pit_side`), padrão esquerda.
- **2026-11-09 — Cores das zebras por circuito** (tabela enviada pelo usuário; referência geral, não curva a curva):
  Albert Park verde/amarelo, Spa vermelho/amarelo, Interlagos verde/amarelo/branco, Monza verde/branco/vermelho,
  Madring vermelho/amarelo/branco; as demais vermelho/branco (Silverstone preto/branco (confirmado pelo usuário)). Campo `scenery.kerbs`.
- **2026-11-10 — Marcos visuais por circuito** (lista do usuário; prioridade para os que funcionam em tela pequena).
  `Landmarks3D`, lista em `scenery.landmarks`, formas originais e sem logotipos, ampliadas (~1,5–3,4×) para aparecer na
  vista geral: roda-gigante (Suzuka, Singapura), escultura de touro em bronze genérica (Áustria), esfera de telão (Las
  Vegas), torre de observação (Austin), iates (Mônaco, Miami, Abu Dhabi), torres-chama (Baku), três torres com a
  prancha no topo (Singapura), domo geodésico (Montreal), estádio (Miami, Cidade do México), oval inclinado (Monza),
  hotel com casca sobre treliça (Abu Dhabi), arquibancada com asas (Xangai), palmeiras, dunas (Zandvoort), hotéis com
  néon (Las Vegas), torres de iluminação (Lusail), além dos já existentes (lago e skyline, hangares, montanhas).
  Ainda faltam: túnel de Mônaco, Muro dos Campeões, teto do Silverstone Wing, subida da Eau Rouge (relevo de Spa),
  muralhas de Baku, trecho dentro do estádio no México e a curva inclinada do Madring. Sepang não está no calendário do jogo.
- **2026-11-10 — Item 7: mercado vivo, componentes e finanças** (escolhas do usuário). **Componentes**: limite por
  temporada de unidade de potência e câmbio; passou do limite = punição de grid; a IA também sofre e decide quando
  trocar. **Mercado vivo** durante a temporada: contratos futuros da IA (anunciados nas notícias), rivais fazem proposta
  pelos seus pilotos/técnicos (cobrir, aceitar a multa ou deixar ir no fim do contrato) e pedidos de renovação/aumento
  perto do fim do contrato (recusar baixa a moral). Sem boatos. **Finanças**: patrocínio garantido × bônus por meta,
  prêmio oficial por posição com tabela visível e projeção, compromissos (gastos já assumidos) e gráfico do caixa até o
  fim do ano. Ordem: **mercado vivo primeiro**, depois componentes, depois finanças.
- **2026-11-10 — Componentes: valores aplicados** (PROVISÓRIO): 4 motores e 4 câmbios por carro na temporada; o motor
  gasta 18%/corrida e o câmbio 13%; 5º motor = 10 posições, seguintes = 5; câmbio além do limite = 5; mais de 15
  posições = largada do fundo. Vale só para a corrida principal (não a sprint). Motor/câmbio acima de 80% de desgaste
  quebram mais. A IA troca a 70% de desgaste dentro do limite e, no limite, só perto de 95%. A tela de peças mostra
  "usados X de 4" e avisa a punição; os seus carros punidos viram notícia.
- **2026-11-10 — Cartão do piloto na corrida.** Sem o aviso "falta usar outro composto seco" (a regra continua valendo
  na simulação). "MISSÃO" e "P/ BOX" viraram símbolos (alvo e chave). Ordens de equipe sempre à mostra embaixo, por
  carro e valendo até mudar: **Briga liberada**, **Não defender do companheiro** (abre quando ele encosta atrás) e
  **Não atacar companheiro** (não tenta passá-lo). O piloto às vezes recusa. Ritmo e bateria viraram ícones na linha da
  missão de base.
- **2026-11-10 — Fonte e caixa alta.** O jogo inteiro (menus e corrida) usa a **Kanit** (OFL; escolhida numa comparação
  com Rubik, Russo One, Teko, Oswald e Montserrat — os jogos famosos usam fontes próprias que não podemos incluir) e
  **todo texto fica em caixa alta** (`AllCaps`, ligado no `Session`; um nó com a meta `keep_case` fica como está).
- **2026-11-10 — Cartão do piloto com as cores da equipe.** Na corrida e na classificação o cartão usa vidro tingido
  com a cor da equipe (mais transparente que antes: a pista aparece), faixa lateral e botões na cor de destaque da
  equipe (Haas/Audi/Cadillac, de cor principal cinza ou escura, usam a secundária). A **bandeira do país** fica logo
  depois do sobrenome, num recorte inclinado (mesmo ângulo dos botões), na altura das maiúsculas (`NameFlag`).
- **2026-11-10 — Folhas sempre cabem na tela.** Com a fonte Kanit em caixa alta a folha de missões passou da largura da
  tela, o X de fechar saiu e o fundo escuro bloqueava o toque (o jogo parecia travado). `ScreenKit.sheet` agora reduz o
  painel para caber. **Área segura**: `SafeArea` (recortes do sistema, ex.: furo da câmera do Galaxy S23) encolhe cada
  tela inteira; sem recorte nada muda; `--cutout=44` simula no PC.
- **2026-11-10 — Missões num só OK.** A folha escolhe a missão de base e a curta juntas, com um único botão CONFIRMAR
  (a curta é opcional: "Sem missão curta").
- **2026-11-10 — Pneus estilizados** (`TyreBadge`): borracha com banda de rodagem, faixa lateral na cor do composto com
  brilho, aro e letra, em todo o jogo.
- **2026-11-10 — Resultado entre as partes da classificação** (mockup v28 aprovado): ao fim do Q1/Q2 a sessão para e
  mostra quem passa e, em vermelho, os eliminados (com a distância para o corte); ao fim do Q3, a pole em destaque e o
  grid do 2º ao 10º. Sempre pede CONTINUAR. "Simular o resto" não para nas partes do meio.
- **2026-11-10 — Modo "Campeonato Mundial F1"** (mockup v29 aprovado). Temporada completa de 2026 (22 GPs) com pontos,
  tabelas e estatísticas, **sem desenvolvimento de carro**; pilotos e contratos reais, eventos só do fim de semana,
  controle de motor/câmbio com punição de grid (`WorldParts`, mesmas regras do `CarParts`: limite 4, troca automática).
  Força dos carros por pista = **temporada real** (`data/real_form_2026.json`, gerado por `tools/make_real_form.py` a partir
  de `tools/real_results_2026.json`: top 10 de 19 GPs levantados por busca na web, PARCIAL e sujeito a divergência entre
  fontes), com o grid **~40% mais equilibrado** e ajuste fino calibrado em `tools/world_report.gd`. Rodadas ainda sem
  resultado real usam só a nota base. Bloco próprio no menu inicial e **save separado** (`user://world_championship.json`);
  a Campanha continua intacta. O **campeonato ao vivo da corrida** (pop-ups "se terminar assim" e as animações de campeão de pilotos/construtores) também vale no Mundial (mesmo contrato da campanha; sem a frase do número 1 do ano seguinte). Fica para depois: mais temporadas, controle manual das peças.
- **2026-11-10 — Mundial: tabela, resultado de cada GP e estatísticas** (mockups v30 aprovados). A tabela do painel mostra foto,
  **nome e sobrenome**, equipe, vitórias e pódios (sem a sigla antes do nome). Depois de cada corrida abre o menu de resultado
  (`WorldResult`): aba RESULTADO (pódio, pole com tempo, melhor volta, do 4º em diante com posições ganhas e pontos), CAMPEONATO
  (pilotos e construtores com quem subiu/desceu) e ESTATÍSTICAS (vitórias, poles, pódios e abandonos, por piloto ou por equipe);
  as estatísticas também abrem pelo botão do painel.

- **2026-11-10 — Acabamento (mockups v32 aprovados).** `Settings` (volume geral/efeitos/música, sons de toque, tamanho da letra
  pequena/normal/grande, velocidade inicial da corrida, pausar em decisões, dicas) em `user://settings.json`, com tela de
  Configurações (engrenagem no menu). **3 slots de save** (`SaveSlots`; cada slot guarda uma Campanha OU um Mundial), com
  `save_version` (save de versão futura é recusado) e migração automática do save antigo para o slot 1. **Ajuda** consultável
  (`data/help.json`) e **dicas de primeira vez** por tela (podem ser desligadas). **Sons de menu** originais (toque, confirmar,
  voltar) e música leve nos menus (`UiSound`, gerados por `tools/make_sounds.py`; a música cala na corrida e na classificação).
  **Abertura** com a logo.
- **2026-11-10 — Nova logo** (opção A escolhida): a curva com a linha branca do limite da pista; o carro laranja passa por
  **fora** da linha (zona vermelha) e o azul-marinho por dentro, lembrando o lance Verstappen × Norris em Austin 2024 ("guidelines").
  Carros genéricos, sem patrocínios nem marcas. Gerada por `tools/make_logo_v2.py` (texto em contornos, fonte Kanit).
- **2026-11-10 — Menos texto explicativo.** Como o jogo agora tem Ajuda e dicas, foram removidas as frases explicativas
  espalhadas pelas telas (P&D, Conselho, Fábrica, Finanças, Estúdio, criação de equipe, estratégia, box etc.); ficam só avisos
  necessários (regra do composto, limites, erros). Texto novo nas telas: só o necessário.
- **2026-11-10 — Dados reais (item 11).** `teams_2026.json` ganhou sede, ano da equipe atual, herança e diretor técnico/chefe de
  equipe (`tools/enrich_team_info.py`; chefes de 2026 conferidos por busca: Aston Martin = Newey, Alpine = Steve Nielsen como
  diretor-geral). Resumos curtos de pilotos e técnicos (`Bio`) usam só dados existentes (nada inventado). **Atualização a cada GP:**
  `tools/add_real_round.py <circuito> <p1..p10>` acrescenta o resultado real e regenera `real_form_2026.json` (Mundial).
- **2026-11-10 — Finanças aplicadas (mockups v31 aprovados).** A tela Caixa ganhou abas: **Caixa** (o que já existia), **Receitas**,
  **Prêmio** e **Compromissos**. Patrocínio: a oferta abre a folha "**Garantido × Por meta**" — garantido paga o valor cheio por
  corrida; por meta paga 60% por corrida e, se a equipe terminar entre os N primeiros dos construtores (N = meta da diretoria),
  um bônus igual ao total anual do garantido (cumprida, rende 160%); o bônus é pago no fim da temporada (`Sponsorship.settle_goals`).
  **Prêmio oficial**: tabela por posição com a sua posição, o que vale subir/descer e a distância em pontos. **Compromissos**:
  folha, operação, parcelas de empréstimo, adiantamento e juros até o fim da temporada; **caixa livre = caixa − compromissos**,
  com a projeção do caixa. Obras e peças já saem do caixa na encomenda, então não são compromissos futuros.
- **2026-11-10 — Salvamento automático entre as sessões (todos os modos).** Ao fim de cada sessão do fim de semana (TL1/TL2/TL3,
  classificação, sprint) e também após a corrida (para o painel de resultado) o jogo grava `weekend.sav` no slot ativo
  (`SaveSlots.save_weekend`; Campanha e Mundial por slot, Grande Prêmio avulso em `gp_weekend.sav`). A **corrida em andamento não
  é salva**: se travar, o jogador volta ao painel já na sessão seguinte (grid, previsão, acertos e jogos de pneus preservados; a
  corrida retomada dá o mesmo resultado, pois o estado do sorteio também é salvo). Retomada **automática** ao abrir a Campanha ou o
  Mundial do slot; no Grande Prêmio, a ficha do bloco pergunta CONTINUAR × Novo. O save é descartado ao terminar o fim de semana
  (resultado registrado) ou se pertencer a outra rodada (`ctx_round`). Gravação em arquivo temporário + renomeação (não corrompe se
  o app fechar no meio). Dev: `--worldrace` (corrida do Mundial direto), `--worldresume` (retoma o save do Mundial).
- **2026-11-10 — Voltar do box sem perder a pista.** A pista 3D não é mais movida (`reparent`) para a miniatura do box: a miniatura
  espelha a imagem da pista (`TrackView3D.view_texture()`). Não foi possível reproduzir o sumiço fora do aparelho; precisa de
  validação no S23.
- **2026-11-10 — Largada com sorte e habilidade (`StartModel`).** O grid fica em **duas filas escalonadas** (pole à esquerda, 2º à
  direita, 14 m entre um carro e o seguinte, 4,2 m do eixo; antes 10 m e 3 m) e, depois das luzes, os carros abrem para o eixo da
  pista aos poucos. Cada piloto sorteia um **fator de largada** por corrida (semente determinística): a maioria sai no padrão
  (~70% termina a largada a ±1 posição do grid); uma minoria faz largada **muito boa** (ganha até ~8 posições) ou **muito ruim**
  (perde até ~9). Chances-base 6% / 6%; a **habilidade de largada** de `data/start_skill.json` (PROVISÓRIO, inspirada nas
  largadas reais de 2026 — ex.: Sainz entre os que mais ganham; Hülkenberg, Hadjar e Verstappen entre os que mais perdem) sobe ou
  desce as chances; chuva aumenta a chance de largada ruim. Durante os 10 primeiros segundos os carros **não se bloqueiam** (a
  posição vem só da distância, senão o carro lento virava "rolha" e afundava até o último); ao fim, o espaço mínimo é devolvido.
  Todos arrancam do zero (rampa igual). A tela avisa quem ganhou/perdeu ≥ 2 posições de verdade e o jogador.
- **2026-11-10 — Batidas com consequência.** Antes, um toque entre carros só dava dano leve na asa (e investigação), então
  quase não custava tempo. Agora cada toque sorteia um desfecho para quem foi prejudicado (60% o atacante, 40% o defensor):
  **leve 38%** (perde 0,8–2,2 s e um pouco de asa; o outro carro perde algo em 40% dos casos), **danos 27%** (asa, às vezes
  assoalho, e 1–3 s parado), **rodada 17%** (4–9 s parados e dano), **pneu furado 10%** (volta lenta até o box) e **batida forte
  8%** (abandona; em 20% dos casos o outro carro também; pode vir safety car/VSC). Também há chance de toque nos cruzamentos da
  largada (5× a de uma ultrapassagem comum). A frequência de toques (~5 por corrida) e a investigação seguem como antes;
  `incident_rate = 0` continua sem toques. Em `RaceControl._contact_outcome` (PROVISÓRIO, ajustável).
- **2026-11-10 — Danos por peça e carro no cartão do piloto (mockup v33 aprovado).** O carro tem **5 peças** com dano de 0 a 100%:
  asa dianteira, asa traseira, assoalho, suspensão e motor/câmbio (`CarState.add_damage/part_state/damage_loss_s`). **Só a asa
  dianteira se troca no box**; o resto fica até o fim da prova (o "reparo parcial do assoalho" foi removido). Impacto **médio e que
  soma**: com a peça 100% danificada, asa dianteira −1,0 s/volta, asa traseira −0,8, assoalho −1,0, suspensão −0,9, motor/câmbio
  −0,4 (`RaceControl.PART_PENALTY_S`, PROVISÓRIO; a quebra parcial por problema mecânico continua somando). Quanto mais **dano
  permanente** (tudo menos a asa dianteira), maior a chance de quebra mais tarde (+120% por ponto de dano; suspensão machucada
  passa a poder causar a quebra). Em toque, quem **ataca** danifica a frente (asa dianteira, suspensão) e quem é **atingido**
  danifica a traseira/lateral (asa traseira, assoalho, suspensão). **Cartão do piloto:** sai o desgaste do pneu da parte de cima e
  as ordens de equipe; entra o mini-carro (`CarDiagram`) com **!** amarelo (desgaste) ou vermelho (dano) nas peças, o pneu (barra e
  %) e o que o dano custa por volta; tocar nele (ou no botão do carro) abre a folha com o desenho grande, as peças com problema, o
  pneu, a perda total, o risco de quebra e **TROCAR ASA**. As **ordens de equipe** (briga liberada, não defender, não atacar) viraram
  a aba "Ordens de equipe" da folha de Missões (base e curta continuam juntas na aba "Missões"). **Sem textos explicativos** nessas
  telas: só o carro, números e ícones (pedido do usuário).
- **2026-11-10 — Classificação sem aviso de evolução da pista.** O texto "Pista evoluindo: +x s" saiu da tela (a evolução continua na simulação, de forma implícita); só aparece o aviso quando a pista está molhada.
- **2026-11-10 — Sem ajuste técnico de asa no box.** Saiu a opção de ajustar a asa dianteira (−1…+2: "mais asa, mais rápido, gasta mais
  pneu"): não existe mais `wing_step`, nem o efeito no ritmo e no desgaste do pneu, nem o custo em tempo parado. No box só resta
  **trocar a asa dianteira quando está danificada** (a opção nem aparece sem dano), além do pneu e da punição de tempo.
- **2026-11-10 — Tabelas do Mundial completas, ampliadas e estatísticas clicáveis (mockup v34 aprovado).** A tabela de pilotos/construtores
  do painel mostra **todos** (22 pilotos / 11 equipes) e **rola arrastando** (`DragScroll`); o cartão ganhou o botão de **ampliar**, que abre
  o campeonato em **tela cheia** (`WorldTableScreen`) com abas Pilotos, Construtores e Estatísticas (foto, nome completo, vitórias, poles,
  pódios, pontos e diferença). O botão "Estatísticas" do topo abre a mesma tela já na aba de estatísticas. Lá os quatro quadros
  (vitórias, poles, pódios, abandonos) são **clicáveis**: tocar abre o **ranking completo** daquela estatística (com quem tem zero no fim),
  trocando de estatística pelas abas e de pilotos para equipes pelo seletor. O componente `WorldTables` também serve às abas
  Campeonato/Estatísticas do resultado de cada GP. Dev: `--world --team=<id> --rounds=<n> --ui=wtable|wteams|wstats|wrank`.
- **2026-11-11 — Pista 3D que some (depois do grid ou do box): mitigação.** Sintoma no S23: a corrida começa só com os painéis e o
  fundo da equipe, sem pista nem carros. Não reproduz fora do aparelho. Suspeito: o alvo de renderização do 3D (SubViewport com MSAA no
  GLES/Compatibility) fica vazio ou com tamanho errado ao trocar de tela. Mudanças em `TrackView3D`: no celular o 3D roda **sem MSAA**,
  o alvo **sempre atualiza** e um vigia (`heal_viewport`, a cada 20 quadros) recalcula o tamanho se ele não bater com a área. Precisa
  de validação no aparelho; se voltar a acontecer, o próximo passo é registrar um log no aparelho.
- **2026-11-11 — Duelo de companheiros no Mundial (mockup v35).** Nova aba **Companheiros** na tela cheia do campeonato: um cartão por
  equipe (a sua em destaque) com os dois pilotos (vitórias, pódios, abandonos), o placar de **classificação** (quem ficou à frente),
  de **corrida** (quem chegou à frente; se só um abandona, vence o outro; se os dois abandonam, não conta) e de **pontos**, mais a
  **vantagem média de tempo na classificação**. O histórico de cada GP passou a guardar a melhor volta de classificação de cada piloto
  (`quali`); em GPs de saves antigos, sem esse dado, o placar usa a posição no grid e a média ignora aquele GP
  (`WorldChampionship.teammate_duel`). Dev: `--ui=wmates`.
- **2026-11-11 — Relevo em mais pistas 3D** (escolha do usuário; revisão em lote por capturas). Perfis de altura aproximados, modelados
  à mão (`elevation` no JSON da pista, como já havia em Mônaco e Interlagos): **Spa** (desce da La Source até a Eau Rouge, sobe o
  Raidillon até Les Combes, ~+62 m, e cai até Stavelot, ~−38 m), **Austin** (subida de ~30 m até a curva 1), **Spielberg** (sobe ~62 m
  até a curva 3) e **Suzuka** (desce para a curva 1, sobe nos S e na Spoon). Em Suzuka as duas pistas ficam na **mesma altura no
  cruzamento**: com alturas diferentes o terreno enterra a de baixo, e falta uma ponte no cenário (pendente). Interlagos já tinha relevo.
- **2026-11-11 — Menos verde e biomas por pista** (pedido do usuário: árvores e grama exagerados; variar conforme o lugar real).
  Densidade de árvores cortada quase pela metade em todos os temas e cada pista pode definir `scenery.trees`, `scenery.city` (prédios)
  e `scenery.ground` (cor do terreno): Austin e Barcelona com terreno seco e poucas árvores, Interlagos cercado de cidade, Miami com
  terreno urbano, Madring e Silverstone com terreno próprio, Suzuka com menos floresta e alguma cidade; México e Xangai quase sem
  árvores; Monza continua a mais arborizada (parque). Valores PROVISÓRIOS, revisados por captura em lote.
- **2026-11-11 — Sem prédios dentro do traçado.** Os prédios do cenário só nascem do lado de fora da pista (`Track3D.inside`); nas pistas de rua (`street`) a regra não vale, porque a cidade fica em volta e dentro.
- **2026-11-11 — Marcos em cima do traçado.** Novos marcos que acompanham um trecho da pista (`scenery.spans[chave] = [início, fim]`,
  frações da volta, PROVISÓRIAS): **túnel** de Mônaco, **muro branco** na saída da última chicane de Montreal, **cobertura em asa** sobre
  os boxes de Silverstone, **muralha com torres** em Baku, **arquibancadas dos dois lados** (estádio) no México e **curva inclinada** no
  Madring. Formas genéricas, sem marcas. Ainda falta: ponte de Suzuka e conferir de perto o muro de Montreal.
- **2026-11-12 — Boxes das outras 19 pistas.** A entrada e a saída do pit lane deixaram de ser genéricas (0,95 → 0,05): foram calculadas
  pela geometria de cada traçado (entrada logo depois do fim da última curva, saída pouco antes da primeira), com Monza (0,93) e
  Zandvoort (0,95) ajustadas à mão. PROVISÓRIO: é uma aproximação; pistas com entrada de box antes da última curva na vida real
  ainda podem precisar de ajuste individual, como foi feito em Interlagos, Mônaco e Silverstone.
- **2026-11-12 — Ponte de Suzuka e cobertura de Silverstone.** Em Suzuka a reta de trás volta a passar ~12 m acima da saída da Degner:
  onde dois trechos se cruzam em alturas diferentes o terreno segue o de **baixo** (`Track3D.nearest`), o trecho de cima ganha tabuleiro,
  muretas e pilares (marco `bridge`, `scenery.spans.bridge`) e fica sem gramado lateral para não cobrir a pista de baixo. A cobertura dos
  boxes de Silverstone passou a ter duas abas (uma sobe para trás, outra levanta sobre o pit lane) e pilares.
- **2026-11-12 — Ajustes de cenário depois da validação das 22 pistas.** Montreal virou ilha (água dos dois lados: `scenery.water_sides`
  e `water_gap`); a água do mar/rio subiu para aparecer acima do terreno distante; Albert Park com menos prédios; Zandvoort com areia
  mais escura; México sem o estádio oval solto (fica só o trecho com arquibancadas dos dois lados). Suíte completa: 66 arquivos sem falha.
- **2026-11-12 — Safety car mais imersivo** (pedido do usuário, no lugar da ideia de "corrida mais profunda"). A corrida **desacelera
  para 1× só quando entra SC ou VSC** e volta à velocidade anterior com a bandeira verde (se o jogador não mudou nada). Na volta em que o
  SC recolhe (e nos últimos 20 s do VSC) o selo do topo mostra **"SAFETY CAR · TERMINANDO"** (`RaceControl.neutralization_ending`).
  O carro do SC deixou de ser uma caixa amarela: carro genérico branco com faixas amarelas, para-brisa escuro, rodas e **barra de luzes
  que pisca**, 1,6× maior que o real para ser visto de longe. Na volta de recolher ele **entra no pit lane** ao chegar à entrada dos boxes
  e segue por ele até sumir, mesmo depois da bandeira verde.
- **2026-11-12 — Missões reformuladas: Ritmo e Abordagem na direção (mockup v36 aprovado com ajustes).** As missões de base viraram
  **Ritmo**, com 5 modos e símbolos: **Trazendo pra casa** (era Ritmo seguro), **Conservador** (era Poupar pneus, com a volta-alvo),
  **Ritmo normal**, **Agressivo** (era Atacar) e **Potência máxima** (era Abrir gap/undercut); o comportamento de cada um não mudou.
  "Defender" e as missões curtas saíram da folha do jogador (a IA e o rádio ainda usam as curtas internamente). Nova **Abordagem na
  direção** com 3 níveis: **Sem riscos** (−10 na nota de ultrapassagem e defesa, chance de toque ao atacar ×0,6), **Normal** (a nota do
  piloto) e **Agressivo** (+10, toque ×1,5); vale até o jogador trocar e vale para atacar e para se defender (`RaceSim.racecraft_of`).
  Não foi criado atributo novo de agressividade. Na tela, Ritmo e Abordagem mostram barrinhas amarelas de intensidade, sem números.
  **A corrida começa sempre em Ritmo normal e Abordagem normal** (o plano dos engenheiros deixou de virar "poupar" automático).
- **2026-11-12 — A IA usa a mesma gerência de corrida do jogador** (sem nada na tela). **Ritmo:** Trazendo pra casa com o carro
  machucado ou com folga nas últimas 3 voltas; Potência máxima nas 2 voltas antes da parada (undercut) e na volta de saída com rival
  perto; Agressivo colada no da frente com pneu bom; Conservador se o pneu não chega à parada planejada; senão Ritmo normal.
  **Abordagem:** Sem riscos com dano ou protegendo um pódio com rival atrás no fim; Agressivo só brigando por posição nos 30% finais e
  com ultrapassagem ≥ 80 (aberta demais, os toques quase dobravam); senão Normal. **Ordens de equipe:** com a dupla colada (< 1,2 s), o
  carro da frente recebe "não defender" se o companheiro é bem mais rápido (> 0,25 s/volta ou pneu bem melhor); nas 5 últimas voltas
  com a dupla nos pontos, o de trás recebe "não atacar"; separados, briga liberada. O piloto pode recusar (mesma regra do jogador) e a
  equipe só pede de novo na volta seguinte (`Missions.ai_choose`/`ai_team_orders`). Calibração: média de ~6,7 toques por corrida em 7
  corridas (antes ~5,5).
- **2026-11-12 — Temporada extra 2012: base (pacote de temporada + regulamento).** Cada temporada é uma pasta `data/seasons/<id>/`
  (`season.json` com equipes, pilotos, calendário, forma real e categoria de regras; classe `Season`). O Mundial guarda `season_id` no
  save e passa equipes, pilotos e regras ao fim de semana (nada de chave global); o **Grande Prêmio** também aceita a temporada
  (`Session.gp_season`); a **Campanha não mudou** (pedido do usuário). Regras `F1_2012` (escolhas do usuário): **KERS por volta** — carga
  cheia a cada volta (~6,7 s de uso, +4,5% de velocidade ≈ 0,3 s/volta, +0,12 s na briga para quem está com ele ligado), o piloto decide
  quando gastar conforme o Ritmo (Trazendo pra casa/Conservador guardam para defender; Normal usa antes das zonas de ultrapassagem;
  Agressivo gasta atrás do rival; Potência máxima gasta tudo); no cartão, barra amarela que esvazia a cada uso + bloco **DRS** que fica
  verde com a asa aberta, no lugar da bateria de 2026. Sem a bateria/modo de ultrapassagem de 2026. **DRS** a menos de 1 s. **Dois
  compostos por pista** (par real da Pirelli em cada GP, convertido para os compostos do jogo; 5 jogos do mais macio + 6 do mais duro).
  Motor/câmbio iguais a 2026. **Sem** regra dos 107%. Calendário real de 20 GPs com 6 pistas ainda inexistentes (Sepang, Bahrein,
  Valência, Hockenheim, Coreia, Índia). Ainda faltam: equipes, pilotos e forma real de 2012, as pistas, a escolha da temporada na tela
  (mockup) e as fotos (vão para `game/local/`, fora do git). Dev: `--season=2012`.
- **2026-11-12 — Pistas de 2012: Sepang, Bahrein e Hockenheim** (mesmo acabamento das melhores de 2026, a pedido do usuário):
  traçado aberto (bacinger/f1-circuits, MIT) no comprimento oficial, zonas de ultrapassagem pelas 3 maiores retas, boxes pela
  geometria, perfil, relevo leve, bioma do lugar (Sepang: mata; Bahrein: deserto com palmeiras; Hockenheim: floresta com as
  arquibancadas do Motodrom), zebras, bandeiras (flag-icons, MIT) e arte do cartão (`tools/add_extra_circuits.py`). **No Mundial** cada
  pista só aparece no calendário da sua temporada; **no Grande Prêmio** as pistas extras somam-se às gerais e valem para qualquer
  temporada e categoria (2026, 2012, F2, F3). Valência, Coreia e Índia **não têm traçado aberto** no repositório usado e o OpenStreetMap
  não respondeu daqui: continuam pendentes (`missing` no calendário de 2012). Valores de desempenho PROVISÓRIOS.
