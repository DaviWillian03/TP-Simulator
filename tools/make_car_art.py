"""Gera a ilustração lateral do carro (original, regras 2026) nas cores de cada equipe.
Uso: python tools/make_car_art.py   ->  game/assets/cars/<id_da_equipe>.svg

Arte vetorial própria do projeto (não imita carro real nem usa marcas). Sem texto, filtros ou
<use> no SVG, para importar bem no Godot (ThorVG). O número do piloto é desenhado pelo jogo.
"""
import json
import math
import pathlib

ROOT = pathlib.Path(__file__).resolve().parent.parent
OUT = ROOT / "game/assets/cars"
TEAMS = json.loads((ROOT / "game/data/teams_2026.json").read_text(encoding="utf-8"))["teams"]

BODY = ['M40 214C120 206 230 190 330 176L330 214 60 222Z',
        'M300 178L430 160 520 150 560 156 560 236 300 236Z',
        'M470 168C560 158 650 160 720 178L760 214C700 236 560 238 470 236Z',
        'M505 120C560 112 620 118 700 150 780 176 850 192 902 200L902 214 720 214 520 162Z',
        'M600 121L882 102 882 170 720 150Z',
        'M886 96L976 96 986 232 900 232Z']


def wheel(cx, c2, tyre="#F5C400"):
    spokes = "".join(f'<line x1="{cx}" y1="200" x2="{cx + 34 * math.cos(a * 1.2566):.1f}" y2="{200 + 34 * math.sin(a * 1.2566):.1f}" '
                     f'stroke="#3b4049" stroke-width="5"/>' for a in range(5))
    return (f'<circle cx="{cx}" cy="200" r="63" fill="#121316"/><circle cx="{cx}" cy="200" r="52" fill="none" stroke="{tyre}" stroke-width="4"/>'
            f'<circle cx="{cx}" cy="200" r="36" fill="#262a31"/>{spokes}<circle cx="{cx}" cy="200" r="9" fill="{c2}"/>')


def car(c1, c2):
    body = "".join(f'<path d="{d}" fill="{c1}"/>' for d in BODY)
    shine = "".join(f'<path d="{d}" fill="url(#hl)"/>' for d in BODY)
    return f'''<svg xmlns="http://www.w3.org/2000/svg" width="1000" height="280" viewBox="0 0 1000 280">
<defs><linearGradient id="hl" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#ffffff" stop-opacity=".34"/><stop offset=".55" stop-color="#ffffff" stop-opacity="0"/><stop offset="1" stop-color="#000000" stop-opacity=".25"/></linearGradient></defs>
<path d="M150 236H906V246H150Z M860 236L918 220 918 236Z" fill="#15171b"/>
<path d="M18 236H150V244L18 246Z" fill="#1d2026"/><path d="M30 226L142 221 142 229 30 234Z" fill="{c2}"/>
<path d="M18 204H46L52 246H18Z" fill="#1d2026"/>
{body}
<path d="M60 216C200 200 330 186 470 186 600 186 720 196 902 204L902 210C720 203 600 195 470 195 330 195 200 208 60 222Z" fill="{c2}" fill-opacity=".95"/>
<path d="M480 236C560 222 680 222 760 214L760 236Z" fill="#0f1013" fill-opacity=".85"/>
{shine}
<path d="M500 104L540 100 548 124 505 128Z" fill="#0d0e11"/>
<rect x="874" y="94" width="112" height="15" rx="2" fill="{c2}"/><rect x="880" y="113" width="104" height="10" rx="2" fill="#16181d"/>
<rect x="900" y="214" width="82" height="8" fill="#16181d"/>
<circle cx="468" cy="140" r="21" fill="{c2}"/><path d="M452 136h30v9h-30z" fill="#101215"/>
<path d="M392 158C420 128 480 120 530 128" stroke="#15171b" stroke-width="9" fill="none" stroke-linecap="round"/>
<path d="M530 128V154" stroke="#15171b" stroke-width="8"/><rect x="418" y="146" width="24" height="8" rx="2" fill="#15171b"/>
{wheel(215, c2)}{wheel(802, c2)}
</svg>
'''


if __name__ == "__main__":
    OUT.mkdir(parents=True, exist_ok=True)
    for t in TEAMS:
        c2 = t["color2"]
        if c2.upper() in ("#111111", "#1A1A1A") :  # detalhes escuros somem no carro: usa branco
            c2 = "#F2F2F2"
        (OUT / f'{t["id"]}.svg').write_text(car(t["color"], c2), encoding="utf-8")
    print(f"{len(TEAMS)} carros em {OUT}")
