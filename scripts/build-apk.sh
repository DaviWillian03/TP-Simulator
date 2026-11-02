#!/usr/bin/env bash
# Gera o APK de teste (debug) do jogo. Requer: Godot 4.7.2 + templates Android (scripts/setup-godot.sh),
# JDK 17+ e o Android SDK configurados em Editor > Configurações > Exportar > Android.
# Uso (na raiz do repositório): scripts/build-apk.sh
set -euo pipefail
cd "$(dirname "$0")/../game"
mkdir -p ../build
godot --headless --import
godot --headless --path "$PWD" --export-debug "Android" ../build/f1guidelines-debug.apk
echo "APK: $(cd .. && pwd)/build/f1guidelines-debug.apk"
echo "Instalar (celular com depuração USB): adb install -r build/f1guidelines-debug.apk"
