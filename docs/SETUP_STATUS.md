# Status da preparação

Atualizado em 2026-11-01. Legenda: ✅ sim · ❌ não · — não se aplica.
"Verificado" = testado de fato com operação pequena e não destrutiva (projetos descartáveis
fora do repositório), não apenas configurado.

| Ferramenta | Referência | Instalada | Configurada | Verificada | Observação |
|---|---|---|---|---|---|
| Git | ✅ | ✅ 2.43.0 | ✅ `.gitignore`, `.gitattributes` | ✅ | Branch `claude/laughing-gates-lqgubb`; nenhum repositório remoto criado |
| GitHub CLI | ✅ | ✅ 2.89.0 | — | — | Sem uso necessário por ora |
| Claude Code | ✅ | ✅ 2.1.316 | ✅ `CLAUDE.md`, `.mcp.json` | ✅ servidor detectado | Aguarda sua aprovação do MCP na 1ª sessão interativa |
| Godot 4.7.2-stable | ✅ | ✅ (nuvem, efêmero) | ✅ script reproduzível | ✅ SHA-512 + `--version` + rodar cena | Reinstalar em nova sessão com `scripts/setup-godot.sh` |
| Templates Android 4.7.2 | ✅ | ✅ (nuvem, efêmero) | ✅ | ✅ reconhecidos pelo export | Só os arquivos de Android foram mantidos |
| Godot MCP 0.1.1 | ✅ | ✅ via npx | ✅ `.mcp.json` | ✅ parcial (ver tabela em ENVIRONMENT.md) | `run_project` exige display (Xvfb na nuvem) |
| GUT 9.7.1 | ✅ | ❌ no repo (não há projeto) | — | ✅ em projeto descartável | Instalar quando o projeto Godot existir |
| JDK | ✅ | ✅ OpenJDK 21 | ❌ (falta caminho no editor) | ✅ `java -version` | 17 recomendado, 21 suportado |
| Android SDK | ✅ | ❌ | ❌ | ❌ export falha por falta dele | **Bloqueado**: dl.google.com fora da rede da nuvem |
| adb / aparelho real | ✅ | ❌ | ❌ | ❌ | Só possível na sua máquina local, via USB/Wi-Fi |
| Context7 | ✅ | ❌ | ❌ | ❌ | **Bloqueado**: context7.com fora da rede; instruções em ENVIRONMENT.md |
| godot-demo-projects | ✅ tag `4.7-6ad6167` | — | — | ✅ tag e pastas existem | Consulta sob demanda, fora do código do jogo |
| Doc Godot (manual) | ✅ | — | — | ✅ fonte via raw.githubusercontent | docs.godotengine.org bloqueado na nuvem |
| Doc Godot (API) | ✅ | — | — | ✅ `--doctool` gera 1.076 classes | Versão idêntica ao executável |
| Kenney / Poly Haven | ✅ | — | — | — | Apenas registro; nada baixado |
| Unity / Unity MCP | ✅ | — | — | — | Só se a engine mudar |

## Pendências reais

1. **Android SDK** (bloqueio de rede na nuvem). Opções — escolha sua:
   - liberar `dl.google.com` na rede do ambiente de nuvem e instalar via `sdkmanager`; ou
   - instalar Android Studio/SDK na sua máquina local (necessário de qualquer forma para testar
     em aparelho real).
2. **Aprovar o MCP `godot`** quando abrir uma sessão interativa do Claude Code neste repositório.
3. **Onde você vai desenvolver** (local, nuvem ou ambos) — define se vale um hook `SessionStart`
   para reinstalar o Godot automaticamente na nuvem, e qual SO o script precisa cobrir.
4. **Local da pasta do projeto Godot** (raiz do repositório ou subpasta) — decidir junto com o
   início do projeto; aí entram GUT, `export_presets.cfg` e o template de build.

## Opcional
- Liberar `docs.godotengine.org`, `context7.com`, `mcp.context7.com`, `gut.readthedocs.io`
  na rede da nuvem para consulta direta (há alternativas funcionando, listadas acima).
