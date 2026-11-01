# Referências por finalidade

Versões de referência: Godot 4.7.2-stable · GUT 9.7.1 · godot-mcp 0.1.1.

## Claude Code
- Boas práticas: https://code.claude.com/docs/en/best-practices
- MCP (escopos, `.mcp.json`, variáveis): https://code.claude.com/docs/en/mcp
- Skills: https://code.claude.com/docs/en/skills
- Memória / CLAUDE.md / `.claude/rules/`: https://code.claude.com/docs/en/memory
- Ambientes de nuvem (rede, setup): https://code.claude.com/docs/en/cloud-environments

## Godot (engine e documentação)
- Download: https://godotengine.org/download/ · releases: https://github.com/godotengine/godot/releases
- Manual: https://docs.godotengine.org/en/stable/
  - Fonte do manual (acessível na nuvem): https://github.com/godotengine/godot-docs (branch `stable` = 4.7)
- Exportar para Android: https://docs.godotengine.org/en/stable/tutorials/export/exporting_for_android.html
- Referência de classes com descrições: https://github.com/godotengine/godot/tree/4.7.2-stable/doc/classes
  (`godot --headless --doctool <pasta>` gera só as assinaturas da versão instalada)

## Dados de circuitos
- Traçados (GeoJSON, MIT): https://github.com/bacinger/f1-circuits — inclui
  `championships/f1-locations-2026.json`. Conversor: `tools/geojson_to_track.py`.

## Integrações
- Godot MCP: https://github.com/Coding-Solo/godot-mcp
- Context7: https://github.com/upstash/context7 (não configurado — ver ENVIRONMENT.md)

## Exemplos oficiais
- https://github.com/godotengine/godot-demo-projects — usar a tag `4.7-6ad6167` (Godot 4.7).
  `master` acompanha a versão em desenvolvimento. Consultar demos específicos (ex.: `gui/`,
  `mobile/`); baixar para `refs/` ou fora do repositório, nunca para o código do jogo.

## Testes
- GUT: https://github.com/bitwes/Gut · docs: https://gut.readthedocs.io/ (tag `v9.7.1` para 4.7.x)

## Android
- Android Studio / SDK: https://developer.android.com/studio
- sdkmanager: https://developer.android.com/tools/sdkmanager
- adb: https://developer.android.com/tools/adb
- Android para jogos: https://developer.android.com/games
- Assinatura de apps (futuro): https://developer.android.com/studio/publish/app-signing

## Git e GitHub
- Git: https://git-scm.com/doc
- GitHub: https://docs.github.com/
- GitHub CLI: https://cli.github.com/manual/

## Recursos visuais (opções futuras — nada baixado, direção artística não definida)
- Kenney: https://kenney.nl/assets
- Poly Haven: https://polyhaven.com/

Ao usar qualquer asset externo, registrar em `docs/THIRD_PARTY.md`: arquivo/pacote, URL de
origem, autor, licença e data.

## Alternativa: Unity (só se a engine escolhida mudar)
- Unity MCP: https://github.com/CoplayDev/unity-mcp
- Manual: https://docs.unity3d.com/Manual/
Nada instalado. Não preparar em paralelo ao Godot.
