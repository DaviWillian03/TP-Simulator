# TP-Simulator

Futuro jogo mobile Android de gestão de automobilismo. **Fase atual: só ambiente preparado.**
Nome, visual, mecânicas, arquitetura e escopo ainda NÃO foram decididos — não invente
requisitos; espere as ideias do usuário e pergunte quando faltar informação.

Usuário: estudante de Sistemas de Informação. Responda em português, explicando o porquê
das escolhas técnicas.

## Stack (hipótese inicial, revisável)
- Godot **4.7.2-stable** + GDScript (não usar versões dev/beta).
- Testes: GUT **9.7.1** (a versão do GUT tem de acompanhar a do Godot).
- Detalhes, versões e limitações: `docs/ENVIRONMENT.md`. Estado: `docs/SETUP_STATUS.md`.
- Links por finalidade: `docs/REFERENCES.md`.

## Comandos verificados
```bash
scripts/setup-godot.sh                          # instala o editor (fora do repo)
scripts/setup-godot.sh --with-android-templates # + templates Android (~1,3 GB de download)
godot --headless --version
godot --headless --path <proj> --import         # importa recursos / gera .uid
godot --headless --path <proj> --quit-after 3   # roda alguns frames e mostra print/erros
godot --headless -d -s --path <proj> addons/gut/gut_cmdln.gd -gdir=res://test -ginclude_subdirs -gexit
```
O GUT sai com código 0 se tudo passar e 1 se algo falhar.

## Godot MCP (`.mcp.json`, servidor `godot`)
- Funciona: versão, info do projeto, criar cena, adicionar nó, salvar cena, UID, rodar projeto
  e ler saída/erros (`get_debug_output`).
- `create_scene` **sobrescreve cena existente sem avisar** — confira se o arquivo existe antes.
- `run_project` abre janela: sem display (nuvem) ele morre em silêncio. Use
  `Xvfb :99 -screen 0 1280x720x24 &` e `DISPLAY=:99` antes de iniciar a sessão, ou rode
  headless pelo terminal.
- Ler logs NÃO é ver a tela nem testar jogabilidade. Validação visual/UX é do usuário.

## Documentação sob demanda (não carregue tudo)
- API exata da versão instalada: `godot --headless --doctool <pasta-fora-do-repo>` gera os XML
  das classes; consulte só a classe necessária.
- Manual: fonte em `https://raw.githubusercontent.com/godotengine/godot-docs/stable/<caminho>.rst`
  (branch `stable` = 4.7). `docs.godotengine.org` está bloqueado na rede da nuvem.
- Demos oficiais: tag `4.7-6ad6167` de godot-demo-projects. Consultar exemplos pontuais; não
  copiar arquitetura inteira.

## Regras do repositório
- Referências baixadas ficam fora do código do jogo (`/refs/` ou fora do repo; está no .gitignore).
- Nunca versionar keystores, senhas, `.env` ou `.godot/`. Sem credencial de publicação por enquanto.
- Assets externos: registrar origem e licença (ver `docs/REFERENCES.md`).
- Não criar repositórios remotos, publicar ou conectar contas sem pedido explícito.
