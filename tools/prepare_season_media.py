#!/usr/bin/env python3
"""Instala fotos de pilotos e logos de equipe de uma temporada extra (ex.: 2012) no APK PESSOAL do jogador.
As imagens vão só para game/local/ (ignorada pelo git): fotos de imprensa e logos oficiais NUNCA entram no repositório.

Uso: python3 tools/prepare_season_media.py <pasta_extraida> [temporada=2012]
Entrada: <pasta>/Pilotos/<equipe>/<Nome_do_Piloto>.png (retrato de rosto e ombros, fundo transparente)
         <pasta>/Equipes/<Nome_da_Equipe>.png (logo da época)
Saída:   game/local/drivers/<temporada>/<id>_face.png (384x384) e game/local/emblems/<temporada>/<id>.png (quadrado 512)
O id vem de game/data/seasons/<temporada>/drivers.json e teams.json (pelo nome, sem acentos).
"""
import json
import pathlib
import shutil
import sys
import unicodedata

from PIL import Image

ROOT = pathlib.Path(__file__).resolve().parent.parent
FACE = 384
EMBLEM = 512
# nomes de arquivo da época -> id do jogo
TEAM_ALIASES = {"vodafone_mclaren_mercedes": "mclaren", "mercedes_amg_petronas": "mercedes", "scuderia_ferrari": "ferrari",
                "red_bull_racing": "redbull", "sahara_force_india": "forceindia", "scuderia_toro_rosso": "tororosso",
                "lotus_f1_team": "lotus", "sauber_f1_team": "sauber", "williams_f1_team": "williams",
                "caterham_f1_team": "caterham", "marussia_f1_team": "marussia", "hrt_f1_team": "hrt"}
DRIVER_ALIASES = {"jerome_dambrosio": "dambrosio"}  # substituto (GP da Itália): foto guardada, fora do grid titular


def slug(name: str) -> str:
    s = unicodedata.normalize("NFKD", name).encode("ascii", "ignore").decode().lower()
    return "".join(c if c.isalnum() else "_" for c in s).strip("_")


def face_crop(im: Image.Image) -> Image.Image:
    """Retrato de rosto e ombros: quadrado do topo da foto (boné ao queixo/pescoço), sem a marca d'água de baixo."""
    side = min(im.width, im.height)
    x0 = (im.width - side) // 2
    return im.crop((x0, 0, x0 + side, side)).resize((FACE, FACE), Image.LANCZOS)


def square_logo(im: Image.Image) -> Image.Image:
    bb = im.getbbox() or (0, 0, im.width, im.height)
    im = im.crop(bb)
    k = (EMBLEM * 0.92) / max(im.width, im.height)
    im = im.resize((max(1, int(im.width * k)), max(1, int(im.height * k))), Image.LANCZOS)
    out = Image.new("RGBA", (EMBLEM, EMBLEM), (0, 0, 0, 0))
    out.alpha_composite(im, ((EMBLEM - im.width) // 2, (EMBLEM - im.height) // 2))
    return out


def main(src: pathlib.Path, season: str) -> None:
    data = ROOT / "game/data/seasons" / season
    drivers = json.loads((data / "drivers.json").read_text(encoding="utf-8"))["drivers"]
    by_slug = {slug(d["name"]): d["id"] for d in drivers} | {d["id"]: d["id"] for d in drivers} | DRIVER_ALIASES
    teams = {t["id"] for t in json.loads((data / "teams.json").read_text(encoding="utf-8"))["teams"]}
    ddir = ROOT / "game/local/drivers" / season
    edir = ROOT / "game/local/emblems" / season
    ddir.mkdir(parents=True, exist_ok=True)
    edir.mkdir(parents=True, exist_ok=True)
    done, unknown = [], []
    for f in sorted((src / "Pilotos").rglob("*.png")):
        did = by_slug.get(slug(f.stem))
        if not did:
            unknown.append(f.name)
            continue
        face_crop(Image.open(f).convert("RGBA")).save(ddir / f"{did}_face.png")
        done.append(did)
    for f in sorted((src / "Equipes").glob("*.png")):
        tid = TEAM_ALIASES.get(slug(f.stem), slug(f.stem))
        if tid not in teams:
            unknown.append(f.name)
            continue
        square_logo(Image.open(f).convert("RGBA")).save(edir / f"{tid}.png")
        done.append(tid)
    for extra in ("Fontes.csv", "Leia-me.txt"):
        if (src / extra).exists():
            shutil.copy(src / extra, ddir / extra)
    print(f"{len(done)} imagens instaladas; sem correspondência: {unknown}")


if __name__ == "__main__":
    main(pathlib.Path(sys.argv[1]), sys.argv[2] if len(sys.argv) > 2 else "2012")
