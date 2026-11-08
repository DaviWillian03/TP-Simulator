# F1 Guidelines (repositório TP-Simulator)

Jogo mobile Android de gestão de automobilismo (temporada 2026). **Fase: implementação.**
- Decisões do usuário: `docs/DECISIONS.md` (fonte oficial). Histórico das ideias: `docs/IDEAS.md`.
- Próximos marcos: `docs/ROADMAP.md`. Ambiente e limitações: `docs/ENVIRONMENT.md`.
- Novas ideias do usuário: registrar em `docs/IDEAS.md`; dúvidas sempre em **múltipla escolha**
  (AskUserQuestion). Não invente requisitos.

Usuário: estudante de Sistemas de Informação. Responda em português, explicando o porquê
das escolhas técnicas.

## Stack
- Godot **4.7.2-stable** + GDScript, renderizador Compatibility, tela paisagem 1280×720 (expand).
- Testes: GUT **9.7.1** em `game/addons/gut` (a versão do GUT acompanha a do Godot).

## Estrutura (`game/` é o projeto Godot)
- `data/` — JSON orientado a dados (equipes, pilotos, pneus, circuitos). Valores de desempenho
  marcados PROVISÓRIO até a pesquisa de atributos.
- `src/sim/` — simulação **sem dependência de tela**: RaceSim (orquestra), TrackModel, TyreModel,
  WeatherModel (clima/radar), RaceControl (incidentes, bandeiras, punições), RadioSystem (rádio),
  StrategyAI (IA); fim de semana: WeekendSim (sessões, previsão, grids, pontos), CarSetup (acerto),
  PracticeSession (programas de blocos), TyreAllocation (jogos de pneus reais do fim de semana), RaceStrategy (planos dos
  engenheiros; na corrida só avisam), QualiSim (Q1/Q2/Q3; cortes pelo nº de carros);
  campanha: `Campaign` (equipe real ou criada = 12ª equipe, 24 carros; salva em
  user://campaign.json; na F2/F3 usa `FeederCareer` + `campaign_feeder_hub_screen`, e a F1 roda simulada rápida), `CategoryRules`
  (regras F1/F2/F3 em `data/categories.json`), `CarDevelopment` (árvore de P&D em `data/rd_tree.json`, gerada por
  `tools/make_rd_tree.py`, e fábrica em `data/factory.json`). Passo fixo `DT`, semente
  determinística. Regras novas entram aqui, com teste.
- Telas do GP: `gp_setup_screen`, `weekend_screen` (treino é sempre simulado: engenheiro, chance de acerto e folha de resultado), `quali_screen` (folha de saída: jogo, atitude, voltas), `strategy_screen` (estratégia antes da largada) e
  `grid_screen` (grid fila a fila) antes de toda corrida/sprint jogada (peças comuns
  em `ScreenKit`); o fim de semana ativo fica em `Session.weekend`.
  Módulos que guardam o RaceSim usam `WeakRef` (ciclo de referência vazaria memória).
- `src/ui/` — telas montadas em código (os `.tscn` só apontam para o script). **Todas** as
  cores/fontes/raios/espaços vêm de `UiStyle` — nada de cor solta nas telas. Direção atual:
  **Garagem** (seção "Garagem" do UiStyle + peças em `ScreenKit`, `GarageBackdrop`, `CutButton`,
  `CarHero`); migradas: tudo (tela inicial, GP, fim de semana, treino, classificação, corrida, box e campanha)
  (`TimingTable` com estilo "garage"). Todas as telas jogáveis já são Garagem (corrida, box, classificação, resultados e campanha).
  Mínimos: texto 12 px, alvo de toque 44 px (ação principal 56). Tamanho de fonte **sempre** via `UiStyle.fs()`
  (escala global da letra). Listas/colunas que podem passar da tela: `DragScroll` (arrastar rola; nunca ScrollContainer puro)
  ou `ScreenKit.scroll_column`. Emblemas sempre via
  `TeamEmblems` (prioridade: `user://import/emblems/`, depois `game/local/emblems/` — ignorada
  pelo git, para logos pessoais —, depois os originais).
- `src/audio/race_audio.gd` — som da corrida (sons originais de `tools/make_sounds.py` em `assets/audio/`).
  Na pista 3D cada carro é um disco plano na cor da equipe com o número do piloto (`CarMarker3D`; do jogador: maior, com anel);
  zoom só por pinça. A pista mostra corrida ou classificação via `TrackFeed` (adaptador). Corrida e classificação usam a pista em
  tela cheia com painéis de vidro (`UiStyle.G_GLASS`, `ScreenKit.top_shade`/`glass_*`); radar de chuva fica em Dados > Clima.
- `src/core/session.gd` — autoload `Session` (escolhas do menu + opções de desenvolvimento).
- `test/unit`, `test/integration` — GUT. `tools/race_report.gd` — relatório de corridas simuladas. `tools/balance_report.gd` —
  calibra carro × piloto × resto (meta 55/25/20; `--incidents=0 --weather=dry`). `CarForm` = forma da equipe em cada GP.
- Notas: pilotos F1 em `tools/enrich_drivers.py` (PROFILE), base/agentes livres em `tools/rescale_feeder_ratings.py`, carros em `tools/enrich_teams.py`.
- Raiz: `tools/make_logo.py` (logo), `tools/make_emblems.py` (emblemas), `tools/make_car_art.py`
  (carro ilustrado por equipe), `tools/make_icons.py` (ícones), `tools/geojson_to_track.py`.
- `design/mockups/` — mockups HTML (gerador `build.py`). **Tela nova = mockup primeiro**, usuário
  aprova, depois Godot, depois captura de tela comparando com o mockup.

## Comandos verificados (rodar dentro de `game/`)
```bash
godot --headless --import                                   # após adicionar arquivos
godot --headless -d -s --path "$PWD" addons/gut/gut_cmdln.gd -gexit   # testes (usa .gutconfig.json)
godot --headless -s tools/race_report.gd -- --pct=1.0 --seeds=1,2,3    # balanceamento
DISPLAY=:99 godot --resolution 1280x720 -- --race --team=williams --advance=420 --screenshot=/caminho/x.png --frames=60
```
Opções de desenvolvimento (depois de `--`): `--rain-at=<s> --rain=<0..1>`, `--weather=dry`,
`--incidents=<mult>`, `--sc` (aciona safety car), `--data` (abre o menu DADOS), `--seed`, `--pct`,
`--pause` (começa pausado: grid parado), `--circuit=<id>`, câmera 3D `--cam=<n> --yaw --pitch --dist`
(a câmera vai direto ao alvo nas capturas). Grande Prêmio: `--gp` (configuração), `--weekend`
(painel) e `--play` (sessão atual ao vivo; num treino, simula e abre a folha de resultado), com `--skip=<n>` para simular as n primeiras sessões
(ex.: `--play --circuit=shanghai --skip=2` abre a sprint; `--grid` abre a animação do grid; `--live` vai direto à corrida com o plano dos engenheiros; `--team=f2_<equipe>` joga a F2/F3); `--advance` vale também na
classificação. Capturas de interface: `--ui=team` (folha da tela inicial), `--ui=out` (folha de saída da classificação), `--ui=plan` (aviso da estratégia na corrida), `--ui=champ|champ-poster|champ-teams` (animação de campeão), `--ui=gallery`
(estados dos componentes), `--view-only` (só o 3D, base de mockups). Escolha de equipe: `--teamselect=campaign|gp` (com `--team=<id>`). Campanha: `--campaign`, `--history [--demo-history] [--tab=legends|current|seasons]`, `--car` (peças), `--rd` (árvore),
`--creator [--ui=<passo 0..3>]`, `--hub` e `--camp-race` (usam a campanha salva; `tools/make_demo_campaign.gd -- --round=<n>` grava uma campanha de reta final).
Testes de regras usam `{"weather": "dry", "incident_rate": 0.0}` salvo quando testam clima/incidentes.
- Captura de tela precisa de display: `Xvfb :99 -screen 0 1280x720x24 &`. Use para conferir
  layout depois de mexer na interface (ler logs não mostra a tela).
- O GUT sai com 0 se tudo passar e 1 se algo falhar. Erro de áudio ALSA no container é esperado.
- Instalar o Godot numa sessão nova: `scripts/setup-godot.sh --with-android-templates` (na raiz).

## Godot MCP (`.mcp.json`, servidor `godot`)
- `create_scene` **sobrescreve cena existente sem avisar**. `run_project` precisa de display.
- Ler logs NÃO é ver a tela nem testar jogabilidade. Validação de toque/UX é do usuário no aparelho.

## Documentação sob demanda (não carregue tudo)
- Referência de classes com descrições: `https://raw.githubusercontent.com/godotengine/godot/4.7.2-stable/doc/classes/<Classe>.xml`.
  `godot --doctool <pasta>` gera só assinaturas (sem descrições) — útil para conferir parâmetros.
- Manual: `https://raw.githubusercontent.com/godotengine/godot-docs/stable/<caminho>.rst` (stable = 4.7).
- Traçados de circuitos: `bacinger/f1-circuits` (MIT) via git; converter com `tools/geojson_to_track.py`.
- Na nuvem, godotengine.org, wikipedia, formula1.com e fia.com estão bloqueados; WebSearch funciona.

## Regras do repositório
- Nomes reais de pilotos/equipes no jogo (decisão do usuário). **Nunca** incluir fotos oficiais,
  logos oficiais de equipes/F1/marcas, nem retratos realistas imitando pessoas reais.
  Eventos criminais/escandalosos só com personagens e marcas fictícios.
- Assets e código de terceiros: registrar origem e licença em `docs/THIRD_PARTY.md`.
- Nunca versionar keystores, senhas, `.env` ou `.godot/`. Versionar `.import` e `.uid`.
- Não criar repositórios remotos, publicar ou conectar contas sem pedido explícito.
