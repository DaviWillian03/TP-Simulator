"""Gera os mockups HTML de direção visual da tela de corrida do F1 Guidelines.

Método (inspirado em github.com/halilc4/tabbyspaces): explorar várias direções em HTML
puro, separado do código do jogo; o usuário escolhe/combina; só depois implementar no Godot.

Uso: python design/mockups/build.py   (gera NN-nome.html e index.html nesta pasta)
"""
import json
import math
import pathlib

HERE = pathlib.Path(__file__).parent
ROOT = HERE.parent.parent
track = json.loads((ROOT / "game/data/circuits/interlagos.json").read_text(encoding="utf-8"))
teams = {t["id"]: t for t in json.loads((ROOT / "game/data/teams_2026.json").read_text(encoding="utf-8"))["teams"]}
drivers = {d["code"]: d for d in json.loads((ROOT / "game/data/drivers_2026.json").read_text(encoding="utf-8"))["drivers"]}

# --- dados de exemplo (meio de corrida, jogador = Williams) ------------------------------
ORDER = [("NOR", "Líder", "M", 69), ("VER", "+3.5", "M", 80), ("ANT", "+4.6", "M", 79), ("SAI", "+8.3", "M", 68),
         ("ALB", "+10.4", "M", 68), ("LIN", "+12.6", "M", 79), ("BOR", "+14.4", "H", 63), ("RUS", "+23.6", "H", 2),
         ("PIA", "+24.6", "H", 3), ("LEC", "+25.3", "H", 11), ("HAM", "+26.6", "H", 2), ("ALO", "+28.2", "H", 11),
         ("HUL", "+29.6", "H", 10), ("BEA", "+31.0", "H", 2), ("HAD", "+31.6", "H", 2), ("STR", "+32.5", "H", 10),
         ("OCO", "+33.2", "H", 13), ("GAS", "+33.6", "H", 13), ("BOT", "+34.1", "H", 1), ("LAW", "+35.2", "H", 1),
         ("COL", "+35.3", "H", 1), ("PER", "+36.0", "H", 1)]
PLAYER_TEAM = "williams"
TYRE = {"S": "#E8261C", "M": "#F5C400", "H": "#F2F2F2"}

# Emblemas ORIGINAIS (forma + sigla nas cores da equipe). Logos reais só via importação pessoal.
EMBLEM = {
    "mclaren": ("chevron", "Mc"), "mercedes": ("ring", "Me"), "ferrari": ("shield", "F"),
    "redbull": ("diamond", "R"), "williams": ("square", "W"), "racingbulls": ("hex", "RB"),
    "astonmartin": ("pill", "AM"), "haas": ("square", "H"), "alpine": ("peak", "A"),
    "audi": ("hex", "Au"), "cadillac": ("octagon", "C"),
}


def emblem(team_id: str, size: int = 22) -> str:
    t = teams[team_id]
    shape, txt = EMBLEM[team_id]
    c, c2 = t["color"], t["color2"]
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
    fg = c2 if shape in ("ring",) else ("#FFFFFF" if team_id not in ("haas",) else "#E10600")
    if shape == "ring":
        fg = c
    if shape == "peak":
        txt = ""
    fs = 9 if len(txt) > 1 else 12
    label = f'<text x="12" y="16" text-anchor="middle" font-family="Arial Black,Arial" font-weight="900" font-size="{fs}" fill="{fg}">{txt}</text>' if txt else ""
    return f'<svg class="emb" width="{size}" height="{size}" viewBox="0 0 24 24">{shapes[shape]}{label}</svg>'


# --- pista ----------------------------------------------------------------------------
PTS = track["points"]
xs, ys = [p[0] for p in PTS], [p[1] for p in PTS]
MINX, MINY, W, H = min(xs), min(ys), max(xs) - min(xs), max(ys) - min(ys)
cum = [0.0]
for i in range(len(PTS)):
    a, b = PTS[i], PTS[(i + 1) % len(PTS)]
    cum.append(cum[-1] + math.dist(a, b))
TOTAL = cum[-1]


def at(frac: float):
    d = (frac % 1.0) * TOTAL
    i = max(j for j in range(len(PTS)) if cum[j] <= d)
    a, b = PTS[i], PTS[(i + 1) % len(PTS)]
    t = (d - cum[i]) / max(cum[i + 1] - cum[i], 1e-9)
    return a[0] + (b[0] - a[0]) * t, a[1] + (b[1] - a[1]) * t


PATH = "M" + " L".join(f"{x - MINX:.1f},{y - MINY:.1f}" for x, y in PTS) + " Z"
FRACS = [0.36 - i * 0.012 - (0.01 if i > 6 else 0) for i in range(len(ORDER))]


def track_svg(asphalt="#2B3954", edge="#C9D4E8", width=26, edge_w=34, dot=16, extra="", label_color="#fff", label_bg="#000"):
    pad = 60
    cars = []
    for (code, *_), f in reversed(list(zip(ORDER, FRACS))):
        x, y = at(f)
        tm = teams[drivers[code]["team"]]
        mine = drivers[code]["team"] == PLAYER_TEAM
        r = dot * (1.25 if mine else 1.0)
        halo = f'<circle cx="{x - MINX:.1f}" cy="{y - MINY:.1f}" r="{r + 9}" fill="none" stroke="#fff" stroke-width="4"/>' if mine else ""
        lab = (f'<text x="{x - MINX - 22:.1f}" y="{y - MINY - r - 12:.1f}" font-size="34" font-weight="800" fill="{label_color}" '
               f'stroke="{label_bg}" stroke-width="8" paint-order="stroke" class="carlab">{code}</text>') if mine else ""
        cars.append(f'{halo}<circle cx="{x - MINX:.1f}" cy="{y - MINY:.1f}" r="{r + 3}" fill="{tm["color2"]}"/>'
                    f'<circle cx="{x - MINX:.1f}" cy="{y - MINY:.1f}" r="{r}" fill="{tm["color"]}"/>{lab}')
    sx, sy = at(0.0)
    return (f'<svg class="track" viewBox="{-pad} {-pad} {W + 2 * pad:.0f} {H + 2 * pad:.0f}" preserveAspectRatio="xMidYMid meet">'
            f'{extra}<path d="{PATH}" fill="none" stroke="{edge}" stroke-width="{edge_w}" stroke-linejoin="round"/>'
            f'<path d="{PATH}" fill="none" stroke="{asphalt}" stroke-width="{width}" stroke-linejoin="round"/>'
            f'<circle cx="{sx - MINX:.1f}" cy="{sy - MINY:.1f}" r="10" fill="#fff"/>{"".join(cars)}</svg>')


def tower_rows(name_mode="surname"):
    rows = []
    for i, (code, gap, tyre, wear) in enumerate(ORDER):
        d = drivers[code]
        surname = d["name"].split(" ")[-1].upper() if name_mode == "surname" else code
        mine = " me" if d["team"] == PLAYER_TEAM else ""
        lead = " lead" if i == 0 else ""
        hot = " hot" if wear >= 70 else ""
        rows.append(f'<div class="row{mine}{lead}"><span class="pos">{i + 1}</span>{emblem(d["team"])}'
                    f'<span class="name">{surname}</span><span class="gap">{gap}</span>'
                    f'<span class="tyre" style="--t:{TYRE[tyre]}">{tyre}</span><span class="wear{hot}">{wear}%</span></div>')
    return "\n".join(rows)


def car_panel(code, pos, tyre_txt, wear, battery):
    d = drivers[code]
    return f'''<div class="car">
  <div class="car-head">{emblem(d["team"], 26)}<span class="num">#{d["number"]}</span><span class="cname">{d["name"]}</span><span class="cpos">P{pos}</span></div>
  <div class="car-info"><span class="lbl">PNEU</span><span class="tyrebadge" style="--t:{TYRE['M']}">M</span><span class="ttxt">{tyre_txt}</span>
    <div class="bar"><i style="width:{wear}%;--t:{TYRE['M']}"></i></div><span class="lbl">BATERIA</span><div class="bar bat"><i style="width:{battery}%"></i></div></div>
  <div class="btns"><b>Poupar</b><b class="on">Normal</b><b>Atacar</b><em></em><b>Carregar</b><b class="on">Equilíbrio</b><b>Bateria</b></div>
  <div class="pit"><b class="c s">S</b><b class="c m">M</b><b class="c h on">H</b><b class="box">CHAMAR P/ BOX</b><span class="hint">Regra: falta usar outro composto seco.</span></div>
</div>'''


FONTS = """
@font-face{font-family:Titillium;font-weight:900;src:url(fonts/TitilliumWeb-Black.ttf)}
@font-face{font-family:Titillium;font-weight:700;src:url(fonts/TitilliumWeb-Bold.ttf)}
@font-face{font-family:Titillium;font-weight:600;src:url(fonts/TitilliumWeb-SemiBold.ttf)}
@font-face{font-family:SairaC;font-weight:700;src:url(fonts/SairaCondensed-Bold.ttf)}
@font-face{font-family:SairaC;font-weight:800;src:url(fonts/SairaCondensed-ExtraBold.ttf)}
@font-face{font-family:BarlowC;font-weight:600;src:url(fonts/BarlowCondensed-SemiBold.ttf)}
@font-face{font-family:BarlowC;font-weight:800;font-style:italic;src:url(fonts/BarlowCondensed-ExtraBoldItalic.ttf)}
@font-face{font-family:Barlow;font-weight:500;src:url(fonts/Barlow-Medium.ttf)}
@font-face{font-family:Chakra;font-weight:600;src:url(fonts/ChakraPetch-SemiBold.ttf)}
@font-face{font-family:Chakra;font-weight:700;src:url(fonts/ChakraPetch-Bold.ttf)}
@font-face{font-family:Oxanium;font-weight:200 800;src:url("fonts/Oxanium[wght].ttf")}
@font-face{font-family:ArchivoBlack;src:url(fonts/ArchivoBlack-Regular.ttf)}
@font-face{font-family:ArchivoN;font-weight:400 700;src:url("fonts/ArchivoNarrow[wght].ttf")}
@font-face{font-family:Bebas;src:url(fonts/BebasNeue-Regular.ttf)}
@font-face{font-family:SpaceMono;font-weight:700;src:url(fonts/SpaceMono-Bold.ttf)}
@font-face{font-family:Plex;font-weight:600;src:url(fonts/IBMPlexMono-SemiBold.ttf)}
@font-face{font-family:Russo;src:url(fonts/RussoOne-Regular.ttf)}
@font-face{font-family:Kanit;font-weight:900;font-style:italic;src:url(fonts/Kanit-BlackItalic.ttf)}
@font-face{font-family:Kanit;font-weight:600;font-style:italic;src:url(fonts/Kanit-SemiBoldItalic.ttf)}
"""

BASE = """
*{box-sizing:border-box;margin:0;padding:0}
html,body{width:1280px;height:720px;overflow:hidden}
.screen{width:1280px;height:720px;position:relative;display:grid;gap:8px;padding:8px}
.track{width:100%;height:100%;display:block}
.tower{display:flex;flex-direction:column;overflow:hidden}
.row{display:flex;align-items:center;gap:6px;height:24px;flex:0 0 auto}
.row .pos{width:24px;text-align:center}.row .name{flex:1;white-space:nowrap;overflow:hidden}
.row .gap{width:52px;text-align:right}.row .tyre{width:16px;text-align:center;color:var(--t)}.row .wear{width:34px;text-align:right}
.emb{flex:0 0 auto}
.btns,.pit,.car-info,.car-head{display:flex;align-items:center;gap:5px}
.btns b,.pit b{flex:1;display:flex;align-items:center;justify-content:center;height:36px;cursor:pointer}
.btns em{width:6px}
.pit .c{flex:0 0 40px}.pit .box{flex:0 0 132px}.pit .hint{flex:1;font-size:11px;line-height:1.2}
.car-info .ttxt{width:150px}.bar{flex:1;height:8px;position:relative}.bar i{position:absolute;left:0;top:0;bottom:0;background:var(--t,#3DDC84)}
.car-head .cname{flex:1}.car{display:flex;flex-direction:column;gap:7px}
.toast{position:absolute;z-index:5}
.screen>*{min-width:0;min-height:0}
.main{position:relative;overflow:hidden}.main>.track{position:absolute;inset:0}
.right .main{grid-column:1;grid-row:2}.right .tower{grid-column:2;grid-row:2/4}.right .panels{grid-column:1;grid-row:3}
.left .tower{grid-column:1;grid-row:2/4}.left .main{grid-column:2;grid-row:2}.left .panels{grid-column:2;grid-row:3}
"""


def page(title, css, body):
    return (f'<!doctype html><html lang="pt-BR"><head><meta charset="utf-8"><title>{title}</title>'
            f'<style>{FONTS}{BASE}{css}</style></head><body>{body}</body></html>')


CARS = car_panel("ALB", 5, "Médio · 5 voltas · 68%", 68, 22) + car_panel("SAI", 4, "Médio · 5 voltas · 68%", 68, 30)

# =============================================================================================
VARIANTS = []


def variant(slug, title, pitch):
    def deco(fn):
        VARIANTS.append((slug, title, pitch, fn))
        return fn
    return deco


@variant("01-transmissao", "Transmissão", "Torre igual à da TV: vidro preto, itálico largo, caixa vermelha do líder, status em vermelho.")
def v1():
    css = """
body{background:radial-gradient(ellipse at 30% 20%,#2a2f3a,#0a0c10 70%);font-family:Titillium;color:#fff}
.screen{grid-template-columns:300px 1fr;grid-template-rows:1fr 168px}
.tower{grid-row:1/3;background:rgba(10,12,16,.86);clip-path:polygon(0 0,100% 0,100% 100%,0 100%);border-top:4px solid #E10600}
.tw-head{padding:10px 14px 6px;text-align:center}.tw-head img{height:30px}
.lap{font-size:22px;font-weight:600;letter-spacing:1px;padding:6px 0;border-top:1px solid #333;border-bottom:1px solid #333;text-align:center}.lap b{font-weight:900;font-size:28px}
.status{color:#E10600;font-weight:900;font-size:19px;text-align:center;padding:6px 0;letter-spacing:.5px;font-style:italic}
.row{height:22.5px;font-weight:900;font-style:italic;font-size:15.5px;letter-spacing:.3px;padding-right:8px}
.row .pos{background:#fff;color:#000;font-style:normal;height:100%;display:flex;align-items:center;justify-content:center;width:30px;font-size:14px}
.row.lead .pos{background:#E10600;color:#fff}.row.me{background:linear-gradient(90deg,rgba(24,104,219,.55),transparent)}
.row .gap{font-weight:600;font-style:normal;font-size:12.5px;color:#cfd3da}.row .wear{font-size:11px;font-weight:600;font-style:normal;color:#8a909b}.row .wear.hot{color:#ff4d4d}
.row .tyre{font-style:normal;font-size:13px}
.main{position:relative;background:linear-gradient(180deg,#14171d,#0b0d11);border-radius:2px;overflow:hidden}
.main::before{content:"";position:absolute;inset:0;background:repeating-linear-gradient(90deg,rgba(255,255,255,.02) 0 2px,transparent 2px 6px)}
.topbar{position:absolute;top:10px;left:14px;right:14px;display:flex;justify-content:space-between;align-items:center;z-index:2}
.gp{font-weight:900;font-style:italic;font-size:22px;text-transform:uppercase}.gp small{display:block;font-size:12px;font-weight:600;font-style:normal;color:#9aa0aa;letter-spacing:2px}
.speed{display:flex;gap:4px}.speed b{width:44px;height:34px;display:flex;align-items:center;justify-content:center;background:rgba(255,255,255,.08);font-weight:900;font-style:italic}.speed b.on{background:#E10600}
.panels{display:grid;grid-template-columns:1fr 1fr;gap:8px}
.car{background:rgba(10,12,16,.9);padding:9px 10px;border-left:4px solid #1868DB}
.car-head .cname{font-weight:900;font-style:italic;font-size:17px;text-transform:uppercase}.cpos{font-weight:900;font-style:italic;font-size:22px;color:#E10600}.num{font-weight:900;color:#9aa0aa}
.lbl{font-size:10px;letter-spacing:1.5px;color:#9aa0aa}.ttxt{font-size:13px}.tyrebadge{color:var(--t);font-weight:900}
.bar{background:#22262e}.btns b,.pit b{background:#1c2028;font-weight:700;font-size:13.5px;text-transform:uppercase;font-style:italic}.btns b.on,.pit b.on{background:#E10600}
.pit .c{font-weight:900;font-size:16px;font-style:normal}.pit .s{color:#E8261C}.pit .m{color:#F5C400}.pit .h{color:#fff}.pit .box{background:#fff;color:#000}.hint{color:#ff6b6b}
.toast{top:60px;left:20px;background:#E10600;padding:7px 14px;font-weight:900;font-style:italic;text-transform:uppercase;font-size:14px}
"""
    body = f'''<div class="screen"><div class="tower"><div class="tw-head"><img src="../../game/assets/branding/logo.svg"></div>
<div class="lap">VOLTA <b>6</b> / 18</div><div class="status">AR LIVRE · PISTA SECA</div>{tower_rows()}</div>
<div class="main"><div class="topbar"><div class="gp">GP de São Paulo<small>INTERLAGOS · 4.309 KM</small></div><div class="speed"><b>II</b><b>1×</b><b class="on">2×</b><b>4×</b><b>8×</b></div></div>
<div class="toast">SAINZ passa VERSTAPPEN · Reta Oposta</div>{track_svg(asphalt="#3a3f4a", edge="#e6e8ec", dot=15)}</div>
<div class="panels">{CARS}</div></div>'''
    return page("Transmissão", css, body)


@variant("02-pit-wall", "Pit Wall", "Monitor de engenharia: fibra escura, fonte mono, leituras âmbar/verde, grade fina de telemetria.")
def v2():
    css = """
body{background:#0b0d10;color:#d6dbe1;font-family:Plex}
.screen{grid-template-columns:1fr 300px;grid-template-rows:40px 1fr 172px;gap:6px}
.top{grid-column:1/3;display:flex;align-items:center;gap:14px;border:1px solid #2a2f36;padding:0 12px;background:#101317}
.top .t{font-family:SairaC;font-weight:800;font-size:20px;letter-spacing:2px;color:#fff}.top .k{color:#FFB000;font-size:13px}
.top .sp{margin-left:auto;display:flex;gap:3px}.top .sp b{border:1px solid #2a2f36;padding:4px 10px;font-size:13px}.top .sp b.on{border-color:#FFB000;color:#FFB000}
.main{position:relative;border:1px solid #2a2f36;background:#0e1114;background-image:linear-gradient(#171b20 1px,transparent 1px),linear-gradient(90deg,#171b20 1px,transparent 1px);background-size:32px 32px}
.main .corner{position:absolute;font-size:10px;color:#5d6773;letter-spacing:1px}
.tower{grid-row:2/4;grid-column:2;border:1px solid #2a2f36;background:#0e1114;padding:4px 6px;font-size:12.5px}
.tw-h{display:flex;justify-content:space-between;color:#5d6773;font-size:10px;letter-spacing:1px;border-bottom:1px solid #2a2f36;padding:4px 0;margin-bottom:2px}
.row{height:24.6px;border-bottom:1px solid #161a1f}.row .pos{color:#5d6773}.row .name{font-family:SairaC;font-weight:700;font-size:15px;letter-spacing:1px;color:#fff}
.row.me{background:rgba(255,176,0,.08);box-shadow:inset 2px 0 #FFB000}.row .gap{color:#3DDC84}.row .wear{color:#8a96a3}.row .wear.hot{color:#FF5C39}
.panels{display:grid;grid-template-columns:1fr 1fr;gap:6px}
.car{border:1px solid #2a2f36;background:#101317;padding:8px}
.car-head .cname{font-family:SairaC;font-weight:800;font-size:17px;letter-spacing:1px;color:#fff;text-transform:uppercase}.cpos{color:#FFB000;font-family:SairaC;font-weight:800;font-size:22px}.num{color:#5d6773}
.lbl{font-size:10px;color:#5d6773;letter-spacing:1px}.ttxt{font-size:12px}.tyrebadge{color:var(--t)}
.bar{background:#1a1f25;height:6px}.bar i{background:#FFB000}.bat i{background:#3DDC84}
.btns b,.pit b{border:1px solid #2a2f36;font-size:12px;color:#aab3bd}.btns b.on,.pit b.on{border-color:#FFB000;color:#FFB000;background:rgba(255,176,0,.07)}
.pit .s{color:#E8261C}.pit .m{color:#F5C400}.pit .h.on{color:#fff}.pit .box{border-color:#3DDC84;color:#3DDC84}.hint{color:#FF5C39}
.toast{top:12px;left:12px;border:1px solid #3DDC84;color:#3DDC84;background:#0b0d10;padding:6px 10px;font-size:12px}
"""
    body = f'''<div class="screen right"><div class="top"><span class="t">GP SÃO PAULO // INTERLAGOS</span><span class="k">VOLTA 06/18</span><span class="k" style="color:#3DDC84">PISTA 34°C · AR 22°C · SECO</span>
<div class="sp"><b>II</b><b>1×</b><b class="on">2×</b><b>4×</b><b>8×</b></div></div>
<div class="main"><span class="corner" style="top:6px;right:10px">MAPA AO VIVO · SETOR 2</span><span class="corner" style="bottom:6px;left:10px">LAT -23.70 · LON -46.70</span>
<div class="toast">&gt; SAI P4 ↑ ultrapassou VER · Reta Oposta</div>{track_svg(asphalt="#232a33", edge="#4a5562", dot=15, label_color="#FFB000", label_bg="#0b0d10")}</div>
<div class="tower"><div class="tw-h"><span>POS PILOTO</span><span>INT · PNEU · DESG.</span></div>{tower_rows()}</div>
<div class="panels">{CARS}</div></div>'''
    return page("Pit Wall", css, body)


@variant("03-paddock", "Paddock (revista)", "Editorial claro: papel, tinta preta, um vermelho de destaque, números enormes e fios grossos.")
def v3():
    css = """
body{background:#efe9de;color:#141414;font-family:ArchivoN}
.screen{grid-template-columns:1fr 296px;grid-template-rows:62px 1fr 170px;gap:0;padding:14px 16px}
.mast{grid-column:1/3;display:flex;align-items:flex-end;border-bottom:5px solid #141414;padding-bottom:6px;gap:16px}
.mast h1{font-family:ArchivoBlack;font-size:38px;line-height:.9;letter-spacing:-1px}.mast .lap{margin-left:auto;font-family:ArchivoBlack;font-size:38px;color:#E10600;line-height:.9}
.mast .meta{font-size:13px;font-weight:600;text-transform:uppercase;letter-spacing:1px}
.main{position:relative;border-right:2px solid #141414;margin-top:8px}
.tower{grid-row:2/4;padding:8px 0 0 12px}
.row{height:24.5px;border-bottom:1px solid #c9c1b2;font-weight:700}.row .pos{font-family:ArchivoBlack;font-size:15px}.row .name{font-family:ArchivoBlack;font-size:13px;letter-spacing:.3px}
.row.lead .pos{color:#E10600}.row.me{background:#141414;color:#efe9de}.row.me .wear{color:#efe9de}.row .gap{font-weight:600;font-size:12.5px}.row .wear{font-size:11px;color:#6d665a}.row .wear.hot{color:#E10600}
.row .tyre{font-family:ArchivoBlack;text-shadow:0 0 1px #141414}
.panels{display:grid;grid-template-columns:1fr 1fr;gap:14px;padding:10px 14px 0 0;border-top:2px solid #141414;margin-top:6px}
.car-head .cname{font-family:ArchivoBlack;font-size:18px;letter-spacing:-.3px}.cpos{font-family:ArchivoBlack;font-size:30px;color:#E10600}.num{font-weight:700}
.lbl{font-size:10px;font-weight:700;letter-spacing:2px}.ttxt{font-size:13px;font-weight:600}.tyrebadge{font-family:ArchivoBlack;text-shadow:0 0 1px #141414;color:var(--t)}
.bar{background:#d8d0c1;height:6px}.bar i{background:#141414}.bat i{background:#E10600}
.btns b,.pit b{border:2px solid #141414;font-weight:700;font-size:13px;text-transform:uppercase}.btns b.on,.pit b.on{background:#141414;color:#efe9de}
.pit .c{font-family:ArchivoBlack}.pit .box{background:#E10600;border-color:#E10600;color:#fff}.hint{color:#E10600;font-weight:600}
.toast{top:10px;left:4px;font-family:ArchivoBlack;font-size:15px;background:#E10600;color:#fff;padding:6px 12px;transform:rotate(-1.5deg)}
.speed{display:flex;gap:4px;margin-left:24px}.speed b{border:2px solid #141414;padding:3px 9px;font-weight:700}.speed b.on{background:#141414;color:#efe9de}
.big{position:absolute;right:16px;bottom:6px;font-family:ArchivoBlack;font-size:120px;color:transparent;-webkit-text-stroke:2px #141414;opacity:.15;line-height:1}
"""
    body = f'''<div class="screen right"><div class="mast"><h1>GP DE SÃO PAULO</h1><span class="meta">Interlagos · 18 voltas · seco</span>
<div class="speed"><b>II</b><b>1×</b><b class="on">2×</b><b>4×</b><b>8×</b></div><span class="lap">6/18</span></div>
<div class="main"><div class="toast">SAINZ PASSA VERSTAPPEN!</div><span class="big">P4</span>{track_svg(asphalt="#141414", edge="#efe9de", width=20, edge_w=20, dot=15, label_color="#141414", label_bg="#efe9de")}</div>
<div class="tower">{tower_rows()}</div><div class="panels">{CARS}</div></div>'''
    return page("Paddock", css, body)


@variant("04-retro70", "Retrô 70", "Corrida clássica: creme, faixas laranja e azul, itálico grosso, posições em 'roundel' de carro antigo.")
def v4():
    css = """
body{background:#f1e4c8;color:#1f2a44;font-family:Kanit;font-style:italic}
.screen{grid-template-columns:304px 1fr;grid-template-rows:56px 1fr 170px}
.stripes{grid-column:1/3;display:flex;align-items:center;gap:14px;background:linear-gradient(180deg,#1f3a5f 0 58%,#f1e4c8 58% 64%,#e8641b 64% 82%,#f1e4c8 82% 86%,#7fb7d9 86%);padding:0 16px 14px;border-radius:14px;color:#f1e4c8}
.stripes h1{font-weight:900;font-size:26px;letter-spacing:.5px}.stripes .lap{margin-left:auto;font-weight:900;font-size:24px}
.speed{display:flex;gap:4px}.speed b{background:#f1e4c8;color:#1f3a5f;border-radius:20px;padding:2px 11px;font-weight:900}.speed b.on{background:#e8641b;color:#fff}
.tower{grid-row:2/4;background:#fbf4e3;border:3px solid #1f3a5f;border-radius:16px;padding:6px 8px}
.row{height:24px;font-weight:900;font-size:15px}.row .pos{width:24px;height:22px;border-radius:50%;background:#fff;border:2px solid #1f3a5f;font-size:11px;display:flex;align-items:center;justify-content:center;font-style:normal}
.row.lead .pos{background:#e8641b;color:#fff;border-color:#e8641b}.row.me{background:#7fb7d9;border-radius:12px}.row .gap{font-weight:600;font-size:12.5px}.row .wear{font-weight:600;font-size:11px;color:#8a7a5c}.row .wear.hot{color:#d23a1a}
.row .tyre{text-shadow:0 0 1px #1f2a44}
.main{position:relative;background:#e9d8b4;border-radius:16px;border:3px solid #1f3a5f;overflow:hidden}
.main::after{content:"";position:absolute;left:-40px;right:-40px;bottom:30px;height:26px;background:repeating-linear-gradient(90deg,#e8641b 0 40px,#f1e4c8 40px 80px);transform:rotate(-4deg);opacity:.35}
.panels{display:grid;grid-template-columns:1fr 1fr;gap:8px}
.car{background:#fbf4e3;border:3px solid #1f3a5f;border-radius:16px;padding:8px 10px}
.car-head .cname{font-weight:900;font-size:18px}.cpos{font-weight:900;font-size:24px;color:#e8641b}.num{font-weight:900;color:#e8641b}
.lbl{font-size:10px;letter-spacing:1px;font-style:normal;font-weight:600}.ttxt{font-size:13px;font-weight:600}.tyrebadge{color:var(--t);text-shadow:0 0 1px #1f2a44;font-weight:900}
.bar{background:#e6d6b2;border-radius:6px;overflow:hidden}.bar i{background:#e8641b}.bat i{background:#2e8b57}
.btns b,.pit b{background:#efe0bd;border-radius:20px;font-weight:600;font-size:13.5px}.btns b.on,.pit b.on{background:#1f3a5f;color:#f1e4c8}
.pit .c{font-weight:900}.pit .s{color:#d23a1a}.pit .m{color:#c79a00}.pit .box{background:#e8641b;color:#fff}.hint{color:#d23a1a;font-weight:600}
.toast{top:12px;left:12px;background:#1f3a5f;color:#f1e4c8;border-radius:20px;padding:6px 16px;font-weight:900}
"""
    body = f'''<div class="screen left"><div class="stripes"><h1>GRANDE PRÊMIO DE SÃO PAULO</h1><div class="speed"><b>II</b><b>1×</b><b class="on">2×</b><b>4×</b><b>8×</b></div><span class="lap">VOLTA 6 · 18</span></div>
<div class="tower">{tower_rows()}</div>
<div class="main"><div class="toast">Sainz passa Verstappen na Reta Oposta!</div>{track_svg(asphalt="#1f3a5f", edge="#fbf4e3", dot=16, label_color="#1f3a5f", label_bg="#f1e4c8")}</div>
<div class="panels">{CARS}</div></div>'''
    return page("Retrô 70", css, body)


@variant("05-noite", "Corrida noturna", "GP noturno: azul profundo, neon ciano e magenta, painéis de vidro com brilho, pista que acende.")
def v5():
    css = """
body{background:radial-gradient(ellipse at 60% 40%,#14204a,#05070f 70%);color:#e8f6ff;font-family:Oxanium;font-weight:500}
.screen{grid-template-columns:1fr 286px;grid-template-rows:46px 1fr 172px}
.glass{background:rgba(20,32,74,.35);border:1px solid rgba(0,229,255,.25);border-radius:14px;box-shadow:0 0 24px rgba(0,229,255,.08),inset 0 0 20px rgba(255,43,214,.05);backdrop-filter:blur(8px)}
.top{grid-column:1/3;display:flex;align-items:center;gap:16px;padding:0 16px}.top .t{font-weight:800;font-size:19px;letter-spacing:3px}
.top .lap{color:#00E5FF;font-weight:800;font-size:20px;text-shadow:0 0 10px #00E5FF}.sp{margin-left:auto;display:flex;gap:4px}.sp b{padding:4px 11px;border-radius:8px;border:1px solid rgba(0,229,255,.3)}.sp b.on{background:#FF2BD6;border-color:#FF2BD6;box-shadow:0 0 12px #FF2BD6}
.main{position:relative}.track path:nth-of-type(1){filter:drop-shadow(0 0 10px #00E5FF)}
.tower{grid-row:2/4;padding:8px}.row{height:24.3px;font-weight:700;font-size:14px;letter-spacing:.5px;border-radius:6px;padding-right:4px}
.row .pos{color:#7d8bb5}.row.lead .pos{color:#FF2BD6;text-shadow:0 0 8px #FF2BD6}.row.me{background:linear-gradient(90deg,rgba(0,229,255,.25),transparent)}
.row .gap{color:#9fe9ff;font-size:12px}.row .wear{font-size:11px;color:#7d8bb5}.row .wear.hot{color:#FF2BD6}
.panels{display:grid;grid-template-columns:1fr 1fr;gap:8px}.car{padding:9px 10px}
.car-head .cname{font-weight:800;font-size:17px;letter-spacing:1px}.cpos{font-weight:800;font-size:24px;color:#00E5FF;text-shadow:0 0 10px #00E5FF}.num{color:#FF2BD6}
.lbl{font-size:10px;letter-spacing:2px;color:#7d8bb5}.ttxt{font-size:12.5px}.tyrebadge{color:var(--t);font-weight:800}
.bar{background:rgba(255,255,255,.08);border-radius:4px;overflow:hidden}.bar i{box-shadow:0 0 8px var(--t)}.bat i{background:#00E5FF;box-shadow:0 0 8px #00E5FF}
.btns b,.pit b{border-radius:8px;border:1px solid rgba(0,229,255,.25);font-size:13px;background:rgba(255,255,255,.03)}.btns b.on,.pit b.on{border-color:#00E5FF;color:#00E5FF;box-shadow:0 0 10px rgba(0,229,255,.4)}
.pit .s{color:#ff5a5a}.pit .m{color:#ffd84a}.pit .box{background:linear-gradient(90deg,#FF2BD6,#7a3cff);border:none;font-weight:800}.hint{color:#FF2BD6}
.toast{top:12px;left:12px;padding:7px 14px;border-radius:10px;background:rgba(255,43,214,.18);border:1px solid #FF2BD6;box-shadow:0 0 14px rgba(255,43,214,.4);font-weight:700}
"""
    cars = CARS.replace('class="car"', 'class="car glass"')
    body = f'''<div class="screen right"><div class="top glass"><span class="t">GP SÃO PAULO · INTERLAGOS</span><span class="lap">VOLTA 6/18</span><div class="sp"><b>II</b><b>1×</b><b class="on">2×</b><b>4×</b><b>8×</b></div></div>
<div class="main glass"><div class="toast">SAI ultrapassa VER — P4</div>{track_svg(asphalt="#0b1230", edge="#00E5FF", width=22, edge_w=28, dot=15, label_color="#00E5FF", label_bg="#05070f")}</div>
<div class="tower glass">{tower_rows()}</div><div class="panels">{cars}</div></div>'''
    return page("Noturna", css, body)


@variant("06-asfalto", "Asfalto & Zebra", "Tátil e esportivo: textura de asfalto, zebras vermelho/branco como divisores, faixas amarelas, letras condensadas.")
def v6():
    css = """
body{background:#1c1e22;color:#f2f2f0;font-family:BarlowC;font-weight:600}
.screen{grid-template-columns:1fr 290px;grid-template-rows:52px 1fr 176px;gap:10px}
.asphalt{background-color:#26292e;background-image:radial-gradient(rgba(255,255,255,.05) 1px,transparent 1px),radial-gradient(rgba(0,0,0,.25) 1px,transparent 1px);background-size:5px 5px,7px 7px;background-position:0 0,2px 3px}
.kerb{height:8px;background:repeating-linear-gradient(90deg,#d71920 0 22px,#f2f2f0 22px 44px)}
.top{grid-column:1/3;display:flex;align-items:center;gap:16px;padding:0 14px;position:relative}.top::after{content:"";position:absolute;left:0;right:0;bottom:0;height:6px;background:repeating-linear-gradient(90deg,#d71920 0 22px,#f2f2f0 22px 44px)}
.top .t{font-family:Bebas;font-size:34px;letter-spacing:1.5px;line-height:1}.top .lap{font-family:Bebas;font-size:34px;color:#ffd200;margin-left:auto}
.sp{display:flex;gap:4px}.sp b{font-family:Bebas;font-size:20px;padding:2px 12px;background:#3a3e45}.sp b.on{background:#ffd200;color:#111}
.main{position:relative;border-left:6px solid #ffd200}
.tower{grid-row:2/4;padding:0;border-top:8px solid transparent;border-image:repeating-linear-gradient(90deg,#d71920 0 18px,#f2f2f0 18px 36px) 8}
.row{height:24.4px;font-size:16px;padding:0 8px 0 0;border-bottom:1px solid #33363c}.row .pos{font-family:Bebas;font-size:19px;background:#33363c;height:100%;display:flex;align-items:center;justify-content:center;width:28px}
.row.lead .pos{background:#ffd200;color:#111}.row .name{font-family:Bebas;font-size:20px;letter-spacing:1px}.row.me{background:rgba(255,210,0,.12);box-shadow:inset -4px 0 #ffd200}
.row .gap{font-size:14px}.row .wear{font-size:13px;color:#9a9ea6}.row .wear.hot{color:#ff4b3e}
.panels{display:grid;grid-template-columns:1fr 1fr;gap:10px}.car{padding:9px 10px;border-top:6px solid;border-image:repeating-linear-gradient(90deg,#d71920 0 18px,#f2f2f0 18px 36px) 6}
.car-head .cname{font-family:Bebas;font-size:26px;letter-spacing:1px;line-height:1}.cpos{font-family:Bebas;font-size:32px;color:#ffd200;line-height:1}.num{font-family:Bebas;font-size:20px;color:#9a9ea6}
.lbl{font-size:12px;letter-spacing:2px;color:#9a9ea6}.ttxt{font-size:15px}.tyrebadge{color:var(--t);font-family:Bebas;font-size:20px}
.bar{background:#3a3e45;height:8px}.bat i{background:#2fd16f}
.btns b,.pit b{background:#3a3e45;font-family:Bebas;font-size:19px;letter-spacing:1px}.btns b.on,.pit b.on{background:#ffd200;color:#111}
.pit .c{font-size:22px}.pit .s{color:#ff4b3e}.pit .m{color:#ffd200}.pit .box{background:repeating-linear-gradient(135deg,#d71920 0 14px,#b8141a 14px 28px)}.hint{color:#ff4b3e;font-size:13px}
.toast{top:12px;left:14px;background:#ffd200;color:#111;padding:4px 14px;font-family:Bebas;font-size:22px;letter-spacing:1px}
"""
    cars = CARS.replace('class="car"', 'class="car asphalt"')
    body = f'''<div class="screen right"><div class="top asphalt"><span class="t">GP DE SÃO PAULO · INTERLAGOS</span><span class="lap">VOLTA 6 / 18</span><div class="sp"><b>II</b><b>1×</b><b class="on">2×</b><b>4×</b><b>8×</b></div></div>
<div class="main asphalt"><div class="toast">SAINZ PASSA VERSTAPPEN · RETA OPOSTA</div>{track_svg(asphalt="#3b3f46", edge="#f2f2f0", dot=15, label_color="#ffd200", label_bg="#111")}</div>
<div class="tower asphalt">{tower_rows()}</div><div class="panels">{cars}</div></div>'''
    return page("Asfalto", css, body)


@variant("07-prancheta", "Prancheta de estratégia", "Planta técnica: papel azul com grade, traços brancos de desenho técnico, cotas e anotações.")
def v7():
    grid = '<defs><pattern id="g" width="80" height="80" patternUnits="userSpaceOnUse"><path d="M80 0H0V80" fill="none" stroke="rgba(255,255,255,.07)" stroke-width="2"/></pattern></defs>'
    css = """
body{background:#0f3b73;color:#eaf2ff;font-family:Chakra;font-weight:600;background-image:linear-gradient(rgba(255,255,255,.06) 1px,transparent 1px),linear-gradient(90deg,rgba(255,255,255,.06) 1px,transparent 1px),linear-gradient(rgba(255,255,255,.03) 1px,transparent 1px),linear-gradient(90deg,rgba(255,255,255,.03) 1px,transparent 1px);background-size:80px 80px,80px 80px,16px 16px,16px 16px}
.screen{grid-template-columns:304px 1fr;grid-template-rows:48px 1fr 170px;gap:10px}
.box{border:1.5px solid rgba(234,242,255,.8);position:relative}.box::before{content:attr(data-t);position:absolute;top:-9px;left:10px;background:#0f3b73;padding:0 6px;font-family:SpaceMono;font-size:10px;letter-spacing:1px;color:#9fc3ff}
.top{grid-column:1/3;display:flex;align-items:center;gap:14px;padding:0 14px}.top .t{font-family:SpaceMono;font-size:17px;letter-spacing:1px}.top .lap{margin-left:auto;font-weight:700;font-size:20px;color:#ffe066}
.sp{display:flex;gap:4px}.sp b{border:1.5px solid rgba(234,242,255,.6);padding:3px 10px;font-size:13px}.sp b.on{background:#eaf2ff;color:#0f3b73}
.tower{grid-row:2/4;padding:10px 8px 6px}.row{height:24px;font-size:14px;border-bottom:1px dashed rgba(234,242,255,.25)}.row .pos{font-family:SpaceMono;color:#9fc3ff}.row .name{font-weight:700;letter-spacing:1px}
.row.lead .pos{color:#ffe066}.row.me{background:rgba(255,224,102,.14);outline:1.5px solid #ffe066}.row .gap{font-family:SpaceMono;font-size:12px}.row .wear{font-family:SpaceMono;font-size:11px;color:#9fc3ff}.row .wear.hot{color:#ff8a8a}
.main{position:relative}.dim{position:absolute;font-family:SpaceMono;font-size:11px;color:#9fc3ff}
.panels{display:grid;grid-template-columns:1fr 1fr;gap:10px}.car{padding:10px}
.car-head .cname{font-weight:700;font-size:17px;letter-spacing:1px;text-transform:uppercase}.cpos{font-weight:700;font-size:24px;color:#ffe066}.num{font-family:SpaceMono;color:#9fc3ff}
.lbl{font-family:SpaceMono;font-size:10px;color:#9fc3ff}.ttxt{font-size:13px}.tyrebadge{color:var(--t);font-weight:700}
.bar{border:1px solid rgba(234,242,255,.6);height:9px}.bar i{background:repeating-linear-gradient(135deg,#eaf2ff 0 3px,transparent 3px 6px)}.bat i{background:repeating-linear-gradient(135deg,#7dffb0 0 3px,transparent 3px 6px)}
.btns b,.pit b{border:1.5px solid rgba(234,242,255,.6);font-size:13px}.btns b.on,.pit b.on{background:#eaf2ff;color:#0f3b73}
.pit .s{color:#ff8a8a}.pit .m{color:#ffe066}.pit .box{border-color:#ffe066;color:#ffe066}.hint{color:#ff8a8a;font-family:SpaceMono;font-size:10px}
.toast{top:14px;left:14px;border:1.5px dashed #ffe066;color:#ffe066;padding:6px 12px;font-family:SpaceMono;font-size:12px}
"""
    cars = CARS.replace('class="car"', 'class="car box" data-t="CARRO"')
    body = f'''<div class="screen left"><div class="top box" data-t="FOLHA 01/01"><span class="t">GP SÃO PAULO — INTERLAGOS — 4.309 m</span><span class="lap">VOLTA 06 / 18</span><div class="sp"><b>II</b><b>1×</b><b class="on">2×</b><b>4×</b><b>8×</b></div></div>
<div class="tower box" data-t="CLASSIFICAÇÃO">{tower_rows()}</div>
<div class="main box" data-t="TRAÇADO · SENTIDO ANTI-HORÁRIO"><div class="toast">NOTA: SAI ganhou P4 (Reta Oposta)</div><span class="dim" style="right:14px;bottom:10px">ESC 1:6000 · N ↑</span>
{track_svg(asphalt="#0f3b73", edge="#eaf2ff", width=16, edge_w=22, dot=15, extra=grid, label_color="#ffe066", label_bg="#0f3b73")}</div>
<div class="panels">{cars}</div></div>'''
    return page("Prancheta", css, body)


@variant("08-cockpit", "Cockpit", "Display de volante: fibra de carbono, barra de LEDs no topo (progresso da corrida), botões redondos com aro colorido.")
def v8():
    leds = "".join(f'<i style="background:{c}"></i>' for c in (["#2fe36b"] * 5 + ["#ff3b30"] * 5 + ["#3b82ff"] * 5)[:15])
    css = """
body{background:#0a0a0b;color:#f4f4f5;font-family:SairaC;font-weight:700}
.carbon{background-color:#141416;background-image:linear-gradient(45deg,rgba(255,255,255,.035) 25%,transparent 25%,transparent 75%,rgba(255,255,255,.035) 75%),linear-gradient(45deg,rgba(255,255,255,.035) 25%,transparent 25%,transparent 75%,rgba(255,255,255,.035) 75%);background-size:8px 8px;background-position:0 0,4px 4px;border-radius:18px;border:1px solid #2a2a2e}
.screen{grid-template-columns:1fr 280px;grid-template-rows:54px 1fr 170px}
.top{grid-column:1/3;display:flex;align-items:center;gap:14px;padding:0 18px}.leds{display:flex;gap:6px}.leds i{width:22px;height:10px;border-radius:5px;box-shadow:0 0 8px currentColor;opacity:.95}.leds i:nth-child(n+7){opacity:.18;box-shadow:none}
.top .t{font-family:Russo;font-size:18px;letter-spacing:1px}.top .lap{font-family:Russo;font-size:24px;color:#2fe36b;margin-left:auto}
.sp{display:flex;gap:6px}.sp b{width:36px;height:36px;border-radius:50%;display:flex;align-items:center;justify-content:center;border:3px solid #3a3a40;font-size:13px}.sp b.on{border-color:#2fe36b;color:#2fe36b}
.main{position:relative}.tower{grid-row:2/4;padding:8px 8px}
.screen-in{background:#050506;border-radius:10px;border:1px solid #2a2a2e;height:100%;padding:6px 6px}
.row{height:24.2px;font-size:15.5px;letter-spacing:.8px}.row .pos{font-family:Russo;font-size:13px;color:#8b8b93}.row.lead .pos{color:#2fe36b}.row.me{background:rgba(59,130,255,.18);border-radius:6px}
.row .gap{font-size:13px;color:#d4d4d8}.row .wear{font-size:12px;color:#8b8b93}.row .wear.hot{color:#ff3b30}
.panels{display:grid;grid-template-columns:1fr 1fr;gap:8px}.car{padding:9px 12px}
.car-head .cname{font-family:Russo;font-size:16px;letter-spacing:.5px;text-transform:uppercase}.cpos{font-family:Russo;font-size:24px;color:#2fe36b}.num{font-family:Russo;color:#3b82ff}
.lbl{font-size:11px;letter-spacing:2px;color:#8b8b93}.ttxt{font-size:14px}.tyrebadge{color:var(--t);font-family:Russo}
.bar{background:#050506;height:8px;border-radius:4px;overflow:hidden;border:1px solid #2a2a2e}.bat i{background:#3b82ff}
.btns b,.pit b{border-radius:22px;border:3px solid #3a3a40;font-size:14px;letter-spacing:.5px;background:#0d0d0f}.btns b.on{border-color:#2fe36b;color:#2fe36b}.pit b.on{border-color:#fff}
.pit .c{border-radius:50%;flex:0 0 38px;height:38px;font-family:Russo}.pit .s{border-color:#E8261C;color:#E8261C}.pit .m{border-color:#F5C400;color:#F5C400}.pit .box{border-color:#ff3b30;background:#ff3b30;color:#fff}.hint{color:#ff3b30}
.toast{top:12px;left:14px;background:#050506;border:1px solid #2fe36b;color:#2fe36b;padding:6px 14px;border-radius:10px;font-family:Russo;font-size:13px}
"""
    cars = CARS.replace('class="car"', 'class="car carbon"')
    body = f'''<div class="screen right"><div class="top carbon"><div class="leds" style="color:#2fe36b">{leds}</div><span class="t">GP SÃO PAULO</span><span class="lap">LAP 6/18</span><div class="sp"><b>II</b><b>1×</b><b class="on">2×</b><b>4×</b><b>8×</b></div></div>
<div class="main carbon"><div class="toast">SAI +1 · P4</div>{track_svg(asphalt="#1f1f23", edge="#3a3a40", dot=15, label_color="#2fe36b", label_bg="#050506")}</div>
<div class="tower carbon"><div class="screen-in">{tower_rows()}</div></div><div class="panels">{cars}</div></div>'''
    return page("Cockpit", css, body)


def index():
    cards = "".join(f'<a href="{s}.html"><img src="png/{s}.png"><b>{s[:2]} · {t}</b><span>{p}</span></a>' for s, t, p, _ in VARIANTS)
    return f'''<!doctype html><html lang="pt-BR"><head><meta charset="utf-8"><title>F1 Guidelines — direções visuais</title>
<style>body{{margin:0;background:#111;color:#eee;font-family:system-ui;padding:24px}}h1{{margin:0 0 4px}}p{{color:#aaa;margin:0 0 20px}}
.g{{display:grid;grid-template-columns:repeat(2,1fr);gap:18px}}a{{color:inherit;text-decoration:none;background:#1b1b1b;border-radius:10px;padding:10px;display:flex;flex-direction:column;gap:6px}}
a img{{width:100%;border-radius:6px}}a span{{color:#aaa;font-size:14px}}</style></head><body>
<h1>F1 Guidelines — direções visuais da tela de corrida</h1><p>Escolha uma ou combine elementos ("tabela do 01 com as cores do 06").</p><div class="g">{cards}</div></body></html>'''


if __name__ == "__main__":
    for slug, _, _, fn in VARIANTS:
        (HERE / f"{slug}.html").write_text(fn(), encoding="utf-8")
    (HERE / "index.html").write_text(index(), encoding="utf-8")
    print("\n".join(s for s, *_ in VARIANTS))
