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
- `src/sim/` — simulação **sem dependência de tela** (RaceSim, TrackModel, TyreModel, StrategyAI).
  Passo fixo `DT`, semente determinística. Regras novas entram aqui, com teste.
- `src/ui/` — telas montadas em código (os `.tscn` só apontam para o script). Tema em `UiStyle`.
- `src/core/session.gd` — autoload `Session` (escolhas do menu + opções de desenvolvimento).
- `test/unit`, `test/integration` — GUT. `tools/race_report.gd` — relatório de corridas simuladas.
- Raiz: `tools/make_logo.py` (logo), `tools/geojson_to_track.py` (traçados).

## Comandos verificados (rodar dentro de `game/`)
```bash
godot --headless --import                                   # após adicionar arquivos
godot --headless -d -s --path "$PWD" addons/gut/gut_cmdln.gd -gexit   # testes (usa .gutconfig.json)
godot --headless -s tools/race_report.gd -- --pct=1.0 --seeds=1,2,3    # balanceamento
DISPLAY=:99 godot --resolution 1280x720 -- --race --team=williams --advance=420 --screenshot=/caminho/x.png --frames=60
```
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
