"""Prepara logos de equipes para o APK PESSOAL do jogador (nunca vão para o repositório).
Uso: python tools/prepare_logos.py <pasta_com_pngs> [pasta_de_saida]
Padrão de saída: game/local/emblems (ignorada pelo git).

Renomeia para os ids do jogo, recorta a margem transparente e centraliza num quadrado
512x512 (o jogo compõe o quadradinho na cor da equipe).
"""
import pathlib
import sys

from PIL import Image

IDS = {"mclaren": "mclaren", "mercedes": "mercedes", "ferrari": "ferrari", "redbull": "redbull", "redbullracing": "redbull",
       "williams": "williams", "racingbulls": "racingbulls", "astonmartin": "astonmartin", "haas": "haas", "haasf1team": "haas",
       "alpine": "alpine", "audi": "audi", "cadillac": "cadillac"}
SIZE = 512
MARGIN = 0.04


def main(src: pathlib.Path, dst: pathlib.Path) -> None:
    dst.mkdir(parents=True, exist_ok=True)
    done = []
    for f in sorted(src.glob("*.png")):
        tid = IDS.get(f.stem.lower().replace("-", "").replace("_", ""))
        if not tid:
            print("ignorado:", f.name)
            continue
        im = Image.open(f).convert("RGBA")
        bb = im.getbbox()
        if bb:
            im = im.crop(bb)
        k = SIZE * (1 - 2 * MARGIN) / max(im.size)
        im = im.resize((max(1, round(im.width * k)), max(1, round(im.height * k))), Image.LANCZOS)
        out = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))
        out.paste(im, ((SIZE - im.width) // 2, (SIZE - im.height) // 2), im)
        out.save(dst / f"{tid}.png")
        done.append(tid)
    print(f"{len(done)} logos em {dst}: {', '.join(sorted(done))}")
    missing = sorted(set(IDS.values()) - set(done))
    if missing:
        print("faltando:", ", ".join(missing))


if __name__ == "__main__":
    s = pathlib.Path(sys.argv[1])
    d = pathlib.Path(sys.argv[2]) if len(sys.argv) > 2 else pathlib.Path(__file__).resolve().parent.parent / "game/local/emblems"
    main(s, d)
