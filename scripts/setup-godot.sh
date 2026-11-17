#!/usr/bin/env bash
# Instala o editor Godot (versão estável fixada) fora do repositório,
# verificando o SHA-512 oficial publicado na release do GitHub.
#
# Uso:
#   scripts/setup-godot.sh                    # só o editor
#   scripts/setup-godot.sh --with-android-templates [--with-windows-templates]
#
# Variáveis opcionais:
#   GODOT_VERSION   (padrão abaixo)  ex.: 4.7.2
#   TOOLS_DIR       (padrão: ~/.local/opt)
#
# Efeitos (todos no diretório do usuário, reversíveis):
#   $TOOLS_DIR/godot/<versão>/godot                      binário do editor
#   ~/.local/bin/godot                                   link simbólico
#   ~/.local/share/godot/export_templates/<v>.stable/    templates Android
# Para desfazer: apague esses três caminhos.
set -euo pipefail

GODOT_VERSION="${GODOT_VERSION:-4.7.2}"
TAG="${GODOT_VERSION}-stable"
TOOLS_DIR="${TOOLS_DIR:-$HOME/.local/opt}"
DEST="$TOOLS_DIR/godot/$GODOT_VERSION"
BASE="https://github.com/godotengine/godot/releases/download/$TAG"
EDITOR_ZIP="Godot_v${TAG}_linux.x86_64.zip"
TEMPLATES_TPZ="Godot_v${TAG}_export_templates.tpz"
TEMPLATES_DIR="$HOME/.local/share/godot/export_templates/${GODOT_VERSION}.stable"

WITH_TEMPLATES=0
WITH_WINDOWS=0
for arg in "$@"; do
  [[ "$arg" == "--with-android-templates" ]] && WITH_TEMPLATES=1
  [[ "$arg" == "--with-windows-templates" ]] && WITH_WINDOWS=1  # versão de PC (2026-11-17)
done

case "$(uname -s)-$(uname -m)" in
  Linux-x86_64) ;;
  *) echo "Este script cobre apenas Linux x86_64. Em outro SO, use o instalador oficial." >&2; exit 1 ;;
esac

work="$(mktemp -d)"
trap 'rm -rf "$work"' EXIT

fetch() { curl -fsSL --retry 4 --retry-delay 2 -o "$work/$1" "$BASE/$1"; }
verify() {
  local expected
  expected="$(grep "  $1\$" "$work/SHA512-SUMS.txt" | cut -d' ' -f1)"
  [[ -n "$expected" ]] || { echo "Checksum de $1 não encontrado." >&2; exit 1; }
  echo "$expected  $work/$1" | sha512sum -c -
}

fetch SHA512-SUMS.txt

if [[ ! -x "$DEST/godot" ]]; then
  echo ">> Baixando editor $TAG"
  fetch "$EDITOR_ZIP"
  verify "$EDITOR_ZIP"
  mkdir -p "$DEST"
  unzip -q -o "$work/$EDITOR_ZIP" -d "$work/editor"
  install -m 0755 "$work/editor/Godot_v${TAG}_linux.x86_64" "$DEST/godot"
else
  echo ">> Editor já presente em $DEST"
fi
mkdir -p "$HOME/.local/bin"
ln -sfn "$DEST/godot" "$HOME/.local/bin/godot"

need=()
if [[ $WITH_TEMPLATES -eq 1 ]]; then
  if [[ -f "$TEMPLATES_DIR/android_debug.apk" ]]; then
    echo ">> Templates Android já presentes em $TEMPLATES_DIR"
  else
    need+=('templates/android_*')
  fi
fi
if [[ $WITH_WINDOWS -eq 1 ]]; then
  if [[ -f "$TEMPLATES_DIR/windows_release_x86_64.exe" ]]; then
    echo ">> Templates Windows já presentes em $TEMPLATES_DIR"
  else
    need+=('templates/windows_*')
  fi
fi
if [[ ${#need[@]} -gt 0 ]]; then
  echo ">> Baixando templates de exportação (~1,3 GB; serão mantidos só os pedidos)"
  fetch "$TEMPLATES_TPZ"
  verify "$TEMPLATES_TPZ"
  mkdir -p "$TEMPLATES_DIR"
  # O .tpz é um zip com a pasta templates/; extrai só as plataformas pedidas + version.txt.
  unzip -q -o -j "$work/$TEMPLATES_TPZ" 'templates/version.txt' "${need[@]}" -d "$TEMPLATES_DIR"
  rm -f "$work/$TEMPLATES_TPZ"
fi

echo ">> Versão instalada: $("$DEST/godot" --headless --version)"
