"""Gera os emblemas ORIGINAIS das equipes (SVG com texto convertido em contornos).

Os logos reais das equipes são marcas registradas e não fazem parte do jogo; o jogador pode
colocar a própria imagem em user://import/emblems/<id>.png e o jogo usa essa no lugar.

Requer: fonttools. Uso: python tools/make_emblems.py   (lê game/data/teams_2026.json)
Saída: game/assets/emblems/<id>.svg (96x96 px, desenho em viewBox 24x24).
"""
import json
import pathlib
from fontTools.ttLib import TTFont
from fontTools.pens.svgPathPen import SVGPathPen
from fontTools.pens.transformPen import TransformPen

ROOT = pathlib.Path(__file__).resolve().parent.parent
FONT = ROOT / "game/assets/fonts/ArchivoBlack-Regular.ttf"
OUT = ROOT / "game/assets/emblems"


def text_d(text: str, size: float, cx: float, baseline: float) -> str:
    font = TTFont(FONT)
    gs, cmap, hmtx = font.getGlyphSet(), font.getBestCmap(), font["hmtx"]
    scale = size / font["head"].unitsPerEm
    width = sum(hmtx[cmap[ord(c)]][0] for c in text) * scale
    pen, x = SVGPathPen(gs), cx - width / 2
    for c in text:
        g = cmap[ord(c)]
        gs[g].draw(TransformPen(pen, (scale, 0, 0, -scale, x, baseline)))
        x += hmtx[g][0] * scale
    return pen.getCommands()


def emblem(team: dict) -> str:
    c, c2 = team["color"], team["color2"]
    shape, txt = team["emblem"]["shape"], team["emblem"]["text"]
    shapes = {
        "chevron": f'<path d="M2 4h13l7 8-7 8H2l7-8z" fill="{c}"/>',
        "ring": f'<circle cx="12" cy="12" r="10" fill="{c2}" stroke="{c}" stroke-width="3"/>',
        "shield": f'<path d="M3 2h18v9c0 6-4 9-9 11C7 20 3 17 3 11z" fill="{c}" stroke="{c2}" stroke-width="1.5"/>',
        "diamond": f'<path d="M12 1l11 11-11 11L1 12z" fill="{c}" stroke="{c2}" stroke-width="1.5"/>',
        "square": f'<rect x="2" y="2" width="20" height="20" rx="3" fill="{c}" stroke="{c2}" stroke-width="1.5"/>',
        "hex": f'<path d="M7 2h10l5 10-5 10H7L2 12z" fill="{c}" stroke="{c2}" stroke-width="1.5"/>',
        "pill": f'<rect x="1" y="5" width="22" height="14" rx="7" fill="{c}" stroke="{c2}" stroke-width="1.5"/>',
        "peak": f'<circle cx="12" cy="12" r="11" fill="{c}"/><path d="M5 17l7-11 7 11" fill="none" stroke="{c2}" stroke-width="2.5"/>',
        "octagon": f'<path d="M8 1h8l7 7v8l-7 7H8l-7-7V8z" fill="{c}" stroke="{c2}" stroke-width="1.5"/>',
    }
    fg = c if shape == "ring" else ("#E10600" if team["id"] == "haas" else "#FFFFFF")
    label = f'<path d="{text_d(txt, 11 if len(txt) > 1 else 14, 12, 16.5)}" fill="{fg}"/>' if txt else ""
    return f'<svg xmlns="http://www.w3.org/2000/svg" width="96" height="96" viewBox="0 0 24 24">{shapes[shape]}{label}</svg>\n'


if __name__ == "__main__":
    OUT.mkdir(parents=True, exist_ok=True)
    teams = json.loads((ROOT / "game/data/teams_2026.json").read_text(encoding="utf-8"))["teams"]
    for t in teams:
        (OUT / f"{t['id']}.svg").write_text(emblem(t), encoding="utf-8")
    print(f"{len(teams)} emblemas em {OUT}")
