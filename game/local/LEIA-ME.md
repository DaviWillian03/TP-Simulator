# Pasta local (não vai para o GitHub)

Tudo nesta pasta, exceto este arquivo, é ignorado pelo git (`.gitignore`). Use para imagens que
devem existir só na sua cópia do jogo — por exemplo, logos de equipes para o APK do seu celular.

**Emblemas das equipes:** coloque `game/local/emblems/<id_da_equipe>.png` (ou `.svg`, `.webp`,
`.jpg`). Ids: `mclaren`, `mercedes`, `ferrari`, `redbull`, `williams`, `racingbulls`,
`astonmartin`, `haas`, `alpine`, `audi`, `cadillac`. Imagem quadrada, fundo transparente,
256×256 ou maior. Abra o projeto no Godot (ou rode `godot --headless --import` em `game/`) e
exporte o APK: as imagens substituem os emblemas originais em todas as telas.

Alternativa sem reexportar: copiar as imagens para `user://import/emblems/` no aparelho.

**Lendas do Histórico:** `game/local/legends/<id>.png` (ids em `game/data/legends.json`: `schumacher`, `fangio`, `prost`...),
quadrado com o rosto. Fotos do Wikimedia Commons com licença livre; autor e licença de cada uma em `legends/FONTES.md`.

**Temporadas extras (ex.: 2012):** fotos em `game/local/drivers/2012/<id>_face.png` e logos da época em
`game/local/emblems/2012/<id>.png`. Instale a partir do pacote extraído com
`python3 tools/prepare_season_media.py <pasta> 2012` (recorta o rosto e deixa o logo quadrado). Ids das equipes de 2012:
`redbull`, `ferrari`, `mclaren`, `lotus`, `mercedes`, `sauber`, `forceindia`, `williams`, `tororosso`, `caterham`,
`marussia`, `hrt`. Numa temporada extra o jogo NÃO usa as fotos de 2026 (o Hamilton de 2012 tem a foto de 2012; sem foto
da época, aparecem as iniciais).
