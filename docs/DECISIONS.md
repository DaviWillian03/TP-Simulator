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
  destaques; vermelho = marca e ação principal; fonte Titillium Web (OFL).
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
