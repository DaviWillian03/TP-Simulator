#!/bin/sh
# Gera a arte 3D de cada circuito (cartões do Início, agenda e GP; mockups v26) a partir do próprio cenário do jogo.
# Uso (na raiz, com display): Xvfb :99 & DISPLAY=:99 sh tools/make_track_art.sh
set -e
cd "$(dirname "$0")/../game"
TMP=$(mktemp -d)
for f in data/circuits/*.json; do
	id=$(basename "$f" .json)
	godot --resolution 1280x720 -- --race --view-only --circuit="$id" --pause --screenshot="$TMP/$id.png" --frames=40 >/dev/null 2>&1 || true
	python3 -c "from PIL import Image; Image.open('$TMP/$id.png').convert('RGB').resize((800,450), Image.LANCZOS).save('assets/tracks/$id.jpg', quality=80)"
	echo "$id"
done
rm -rf "$TMP"
