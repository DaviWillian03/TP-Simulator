# Ambiente de desenvolvimento

Levantamento feito em 2026-11-01, numa sessão do Claude Code na nuvem.

## Onde isto roda

| Item | Valor |
|---|---|
| SO | Ubuntu 24.04.5 LTS, x86_64, 4 CPUs, 15 GiB RAM |
| Tipo | Container de nuvem **efêmero**: o que for instalado fora do repositório some quando o container é reciclado. Só o que é commitado e enviado ao GitHub persiste. |
| Claude Code | 2.1.316 |
| Git / GitHub CLI | git 2.43.0 / gh 2.89.0 (gh só para buscas nesta sessão; operações GitHub via integração do Claude) |
| Node.js / npm | v22.23.4 / 10.9.9 (requisito do Godot MCP: Node ≥ 18) |
| Python / uv | 3.13.18 / 0.11.32 |
| Java | OpenJDK 21.0.12 (`JAVA_HOME=/usr/lib/jvm/java-21-openjdk-amd64`) |
| Xvfb | presente (`/usr/bin/Xvfb`) — display virtual para rodar o jogo com janela |
| Docker | 29.9.2 (não utilizado) |

### Rede da nuvem
Acessíveis: github.com (git e downloads de releases), raw.githubusercontent.com, registry.npmjs.org,
developer.android.com, code.claude.com.
**Bloqueados:** godotengine.org, docs.godotengine.org, dl.google.com (Android SDK), context7.com,
mcp.context7.com, gut.readthedocs.io, kenney.nl, polyhaven.com, docs.unity3d.com.
Para liberar: menu do ambiente de nuvem (barra de título da sessão) → Edit → Network access →
adicionar os domínios em *Allowed domains*. Passos: https://code.claude.com/docs/en/cloud-environments#network-access

## Godot

- Versão: **4.7.2-stable** (`4.7.2.stable.official.ed1daf0bf`), a estável mais recente na data.
  Fonte: releases de `godotengine/godot` no GitHub (o binário oficial também é publicado lá),
  com SHA-512 conferido contra `SHA512-SUMS.txt` da mesma release.
- Instalação: `scripts/setup-godot.sh` (reproduzível, só no diretório do usuário):
  - binário: `~/.local/opt/godot/4.7.2/godot`, link em `~/.local/bin/godot`
  - templates Android: `~/.local/share/godot/export_templates/4.7.2.stable/`
    (`android_debug.apk`, `android_release.apk`, `android_source.zip`, `version.txt`)
  - Desfazer: apagar esses caminhos.
- Mudar de versão: `GODOT_VERSION=4.x.y scripts/setup-godot.sh`, e trocar junto a versão do GUT.
- Em Windows/macOS, use o instalador oficial (https://godotengine.org/download/); o script cobre
  só Linux x86_64.

### Rodar sem tela (nuvem)
- Headless (sem janela): `godot --headless --path <proj> --quit-after <frames>` mostra `print` e
  erros com backtrace GDScript.
- Com janela virtual: `Xvfb :99 -screen 0 1280x720x24 &` e `export DISPLAY=:99`. O Godot cai de
  Vulkan para OpenGL (llvmpipe) e o áudio usa driver nulo — avisos esperados, não são erros do jogo.

### Referência da API, na versão exata
`godot --headless --doctool <pasta>` gera ~1.076 XML (7 MB) com a referência de todas as classes
do executável instalado. Gere fora do repositório (ex.: `refs/godot-api/`, ignorado pelo Git) e
consulte apenas a classe necessária.

## Godot MCP (Coding-Solo/godot-mcp)

- Pacote `@coding-solo/godot-mcp@0.1.1` (npm, publicado 2026-02-03; repositório com commit de
  2026-04-16). Versão fixada em `.mcp.json` para reprodutibilidade.
- Configuração: escopo de projeto em `.mcp.json`; `GODOT_PATH` usa a variável do ambiente ou
  `godot` do PATH. Na primeira sessão interativa o Claude Code pede aprovação do servidor
  (`claude mcp list` mostra "Pending approval" até lá).
- Capacidades testadas via protocolo MCP (JSON-RPC), em projeto descartável:

| Ferramenta | Resultado |
|---|---|
| `get_godot_version`, `list_projects`, `get_project_info` | funcionam |
| `create_scene`, `add_node` (com propriedades), `save_scene` | funcionam; **`create_scene` sobrescreve cena existente sem aviso** |
| `get_uid` | funciona para arquivos com `.uid` (scripts) após `--import`; cenas guardam UID no próprio `.tscn` |
| `run_project` + `get_debug_output` + `stop_project` | funcionam **com display** (Xvfb): capturam `print`, `push_error` e backtrace. **Sem display o processo morre e a saída se perde.** |
| `launch_editor`, `load_sprite`, `export_mesh_library`, `update_project_uids` | não testados |

- Limites: o servidor não captura tela nem simula toque. Ler logs não equivale a ver o jogo ou
  avaliar jogabilidade. Ele sempre roda o Godot em modo debug (`-d`) e só registra logs extras
  do servidor com `DEBUG=true`.

## GUT (testes)

- Versão compatível com Godot 4.7.x: **9.7.1** (tag `v9.7.1`, branch `godot_4_7`), conforme a
  tabela do README do GUT.
- Integração (quando existir o projeto): copiar `addons/gut` da tag `v9.7.1` para
  `<projeto>/addons/gut`, habilitar o plugin em Project Settings → Plugins, rodar `--import` uma vez.
- Execução por linha de comando (verificada em projeto descartável; código de saída 0/1):
  `godot --headless -d -s --path <proj> addons/gut/gut_cmdln.gd -gdir=res://test -ginclude_subdirs -gexit`
- Documentação: `documentation/docs/Command-Line.md` no repositório (readthedocs bloqueado aqui).

## Android

Requisitos do Godot 4.7 (página oficial "Exporting for Android", fonte `godot-docs` branch stable):
- OpenJDK 17 recomendado; versões maiores são suportadas → **JDK 21 já instalado serve**.
- Android SDK: Platform-Tools ≥ 35.0.0, Build-Tools 35.0.1, Platform 35, Command-line Tools
  (latest), CMake 3.10.2.4988404, NDK r28b (28.1.13356709). Comando oficial:
  `sdkmanager --sdk_root=<android_sdk_path> "platform-tools" "build-tools;35.0.1" "platforms;android-35" "cmdline-tools;latest" "cmake;3.10.2.4988404" "ndk;28.1.13356709"`
- No Linux, não usar o SDK dos repositórios da distribuição (desatualizado).
- Editor Settings → Export → Android: `Java SDK Path` e `Android SDK Path`.
- Para APK de teste (sem Gradle), NDK/CMake não são usados; são necessários para build Gradle
  (AAB, exigido pela Google Play).
- Keystore de debug: o Godot gera/usa uma de debug; credencial de publicação **não** será criada agora.

Situação aqui: exportação testada em projeto descartável falha apenas por falta do SDK
("Missing 'build-tools'… 'platform-tools'… apksigner… adb"). Templates e Java estão OK.
`dl.google.com` está bloqueado, então o SDK não pode ser baixado nesta nuvem. Teste em aparelho
real (adb/USB) só é possível na máquina local do usuário.

### Três etapas diferentes
1. **Preparar ambiente**: Godot + templates + JDK + SDK configurados no editor.
2. **Gerar build**: `godot --headless --path <proj> --export-debug "Android" build/<nome>.apk`
   (requer `export_presets.cfg` criado pelo editor).
3. **Validar no aparelho**: `adb install`, rodar, observar desempenho e toque — sempre com o usuário.

## Context7

- Não configurado: `context7.com` e `mcp.context7.com` bloqueados nesta nuvem.
- Para usar (na máquina local, ou após liberar os domínios), opção de escopo do usuário, sem
  chave em arquivos versionados:
  - Remoto: `claude mcp add --scope user --transport http context7 https://mcp.context7.com/mcp --header "Authorization: Bearer $CONTEXT7_API_KEY"`
    (chave opcional, recomendada para limites maiores; gerar em context7.com/dashboard e guardar
    em variável de ambiente local).
  - Ou o assistente oficial: `npx ctx7 setup --claude` (OAuth; desfaz com `npx ctx7 remove`).
- Ferramentas expostas: `resolve-library-id`, `query-docs`. Conferir se a biblioteca retornada
  corresponde à versão 4.7 antes de confiar no conteúdo; preferir a doc oficial/doctool.

## Configuração do Claude Code neste repositório

- `CLAUDE.md`: contexto curto (doc oficial recomenda < 200 linhas). Detalhes ficam nestes docs.
- `.mcp.json`: só o servidor Godot. Sem MCPs equivalentes duplicados.
- Skills e hooks: **nenhum por enquanto** — ainda não há procedimento repetitivo concreto.
  Candidatos futuros, quando houver projeto: skill para "rodar testes GUT + checar erros headless"
  e, se o trabalho for principalmente na nuvem, hook `SessionStart` que execute
  `scripts/setup-godot.sh` (custo: ~5 s por sessão só o editor; ~45 s com templates).
- Preferências pessoais: `CLAUDE.local.md` (ignorado pelo Git).
