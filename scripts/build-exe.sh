#!/usr/bin/env bash
# Gera a versão de PC (Windows, 64 bits) do jogo: um .exe único com tudo embutido, zipado para enviar.
# Requer: Godot 4.7.2 + templates Windows (scripts/setup-godot.sh --with-windows-templates).
# Uso (na raiz do repositório): scripts/build-exe.sh
set -euo pipefail
cd "$(dirname "$0")/../game"
mkdir -p ../build/windows
godot --headless --import
godot --headless --path "$PWD" --export-release "Windows" ../build/windows/F1Guidelines.exe
cd ../build
rm -f f1guidelines-windows.zip
zip -q -j f1guidelines-windows.zip windows/F1Guidelines.exe
echo "EXE: $(pwd)/windows/F1Guidelines.exe"
echo "ZIP: $(pwd)/f1guidelines-windows.zip"
