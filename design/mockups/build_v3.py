"""Reformulação visual — três direções para a tela inicial e a configuração do GP.
Uso: python design/mockups/build_v3.py   (gera v3-*.html nesta pasta)

Dados reais do jogo (calendário, circuitos, equipes, pilotos). Imagens 3D = capturas reais do
Godot (png/3d/clean_*.png). O carro em destaque é uma ILUSTRAÇÃO VETORIAL ORIGINAL proposta
(não existe no jogo ainda). Fontes: OFL, em fonts/.
"""
import json
import pathlib
import sys

sys.path.insert(0, str(pathlib.Path(__file__).parent))
import build as B  # noqa: E402
import scenery as S  # noqa: E402

HERE = B.HERE
ROOT = B.ROOT
CIRC = {p.stem: json.loads(p.read_text(encoding="utf-8")) for p in (ROOT / "game/data/circuits").glob("*.json")}
CAL = json.loads((ROOT / "game/data/calendar_2026.json").read_text(encoding="utf-8"))["rounds"]
DRIVERS = json.loads((ROOT / "game/data/drivers_2026.json").read_text(encoding="utf-8"))["drivers"]
TEAM = B.teams["williams"]
MY = [d for d in DRIVERS if d["team"] == "williams"]
SEL = "interlagos"
C = CIRC[SEL]
EMB = "../../game/assets/emblems/{}.svg"
MONTHS = ["", "JAN", "FEV", "MAR", "ABR", "MAI", "JUN", "JUL", "AGO", "SET", "OUT", "NOV", "DEZ"]
SPRINTS = sum(1 for r in CAL if r["sprint"])


def page(title, css, body):
    return (f'<!doctype html><html lang="pt-BR"><head><meta charset="utf-8"><title>{title}</title><style>{B.FONTS}'
            '*{box-sizing:border-box;margin:0;padding:0}html,body{width:1280px;height:720px;overflow:hidden}'
            f'.scene{{width:1280px;height:720px;position:relative;overflow:hidden}}{css}</style></head><body>{body}</body></html>')


def outline(cid, w, h, stroke, width, pad=14, extra=""):
    pts = S.fit(CIRC[cid]["points"], w, h, pad)
    poly = " ".join(f"{x:.1f},{y:.1f}" for x, y in pts)
    return (f'<svg width="{w}" height="{h}" viewBox="0 0 {w} {h}">{extra}<polygon points="{poly}" fill="none" stroke="{stroke}" '
            f'stroke-width="{width}" stroke-linejoin="round"/></svg>')


def start_dot(cid, w, h, pad=14):
    x, y = S.fit(CIRC[cid]["points"], w, h, pad)[0]
    return x, y


# --- ícones de linha (24×24) ---------------------------------------------------------------
def ico(name, size=22, color="currentColor", sw=2.2):
    p = {
        "lock": '<rect x="5" y="11" width="14" height="9" rx="2"/><path d="M8 11V8a4 4 0 0 1 8 0v3"/>',
        "chev": '<path d="M9 5l7 7-7 7"/>',
        "back": '<path d="M15 5l-7 7 7 7"/>',
        "sun": '<circle cx="12" cy="12" r="4"/><path d="M12 2v3M12 19v3M2 12h3M19 12h3M5 5l2 2M17 17l2 2M19 5l-2 2M7 17l-2 2"/>',
        "rain": '<path d="M7 15a4 4 0 1 1 1-7.9A5 5 0 0 1 17.5 9 3.5 3.5 0 0 1 17 16H7"/><path d="M9 19l-1 2M13 19l-1 2M17 19l-1 2"/>',
        "mix": '<circle cx="8" cy="8" r="3"/><path d="M8 2v1M2 8h1M3.8 3.8l.7.7"/><path d="M10 17a3.5 3.5 0 1 1 .9-6.9A4.5 4.5 0 0 1 19.5 12 3 3 0 0 1 19 18H10"/>',
        "globe": '<circle cx="12" cy="12" r="9"/><path d="M3 12h18M12 3c3 3 3 15 0 18M12 3c-3 3-3 15 0 18"/>',
        "flag": '<path d="M5 21V4h11l-2 4 2 4H5"/>',
        "clock": '<circle cx="12" cy="12" r="9"/><path d="M12 7v5l3 2"/>',
        "bolt": '<path d="M13 2L4 14h7l-1 8 9-12h-7z"/>',
        "swap": '<path d="M4 8h13l-3-3M20 16H7l3 3"/>',
    }[name]
    return (f'<svg width="{size}" height="{size}" viewBox="0 0 24 24" fill="none" stroke="{color}" stroke-width="{sw}" '
            f'stroke-linecap="round" stroke-linejoin="round">{p}</svg>')


# --- carro: ilustração vetorial original (perfil lateral, regras 2026) --------------------
def car_svg(c1, c2, number, tyre="#F5C400", width=820, uid="a"):
    body = ('<path d="M40 214C120 206 230 190 330 176L330 214 60 222Z"/>'
            '<path d="M300 178L430 160 520 150 560 156 560 236 300 236Z"/>'
            '<path d="M470 168C560 158 650 160 720 178L760 214C700 236 560 238 470 236Z"/>'
            '<path d="M505 120C560 112 620 118 700 150 780 176 850 192 902 200L902 214 720 214 520 162Z"/>'
            '<path d="M600 121L882 102 882 170 720 150Z"/>'
            '<path d="M886 96L976 96 986 232 900 232Z"/>')
    wheel = lambda cx: (f'<circle cx="{cx}" cy="200" r="63" fill="#121316"/><circle cx="{cx}" cy="200" r="52" fill="none" stroke="{tyre}" stroke-width="4"/>'
                        f'<circle cx="{cx}" cy="200" r="36" fill="#262a31"/>'
                        + "".join(f'<line x1="{cx}" y1="200" x2="{cx + 34 * __import__("math").cos(a * 1.2566)}" y2="{200 + 34 * __import__("math").sin(a * 1.2566)}" stroke="#3b4049" stroke-width="5"/>' for a in range(5))
                        + f'<circle cx="{cx}" cy="200" r="9" fill="{c2}"/>')
    return f'''<svg width="{width}" viewBox="0 0 1000 280">
<defs><linearGradient id="hl{uid}" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#fff" stop-opacity=".34"/><stop offset=".55" stop-color="#fff" stop-opacity="0"/><stop offset="1" stop-color="#000" stop-opacity=".25"/></linearGradient>
<filter id="bl{uid}"><feGaussianBlur stdDeviation="9"/></filter><g id="b{uid}">{body}</g></defs>
<ellipse cx="510" cy="262" rx="480" ry="13" fill="#000" opacity=".6" filter="url(#bl{uid})"/>
<path d="M150 236H906V246H150Z M860 236L918 220 918 236Z" fill="#15171b"/>
<path d="M18 236H150V244L18 246Z" fill="#1d2026"/><path d="M30 226L142 221 142 229 30 234Z" fill="{c2}"/>
<path d="M18 204H46L52 246H18Z" fill="#1d2026"/>
<use href="#b{uid}" fill="{c1}"/>
<path d="M60 216C200 200 330 186 470 186 600 186 720 196 902 204L902 210C720 203 600 195 470 195 330 195 200 208 60 222Z" fill="{c2}" opacity=".95"/>
<path d="M480 236C560 222 680 222 760 214L760 236Z" fill="#0f1013" opacity=".85"/>
<use href="#b{uid}" fill="url(#hl{uid})"/>
<path d="M500 104L540 100 548 124 505 128Z" fill="#0d0e11"/>
<rect x="874" y="94" width="112" height="15" rx="2" fill="{c2}"/><rect x="880" y="113" width="104" height="10" rx="2" fill="#16181d"/>
<rect x="900" y="214" width="82" height="8" fill="#16181d"/>
<circle cx="468" cy="140" r="21" fill="{c2}"/><path d="M452 136h30v9h-30z" fill="#101215"/>
<path d="M392 158C420 128 480 120 530 128" stroke="#15171b" stroke-width="9" fill="none" stroke-linecap="round"/>
<path d="M530 128V154" stroke="#15171b" stroke-width="8"/><rect x="418" y="146" width="24" height="8" rx="2" fill="#15171b"/>
<text x="640" y="182" font-family="Titillium" font-weight="900" font-size="34" fill="{c2}" font-style="italic">{number}</text>
{wheel(215)}{wheel(802)}
</svg>'''


def team_pill(cls="pill"):
    names = " · ".join(d["name"].split(" ")[-1] for d in MY)
    return f'<div class="{cls}"><img src="{EMB.format("williams")}" width="30" height="30"><div><b>{TEAM["name"]}</b><small>{names}</small></div></div>'


def round_info(r):
    c = CIRC[r["id"]]
    return c, f'{r["date"][8:]} {MONTHS[int(r["date"][5:7])]}'


def stats_list():
    diff = float(C["overtaking_difficulty"])
    ov = "FÁCIL" if diff < 0.3 else ("MÉDIA" if diff < 0.6 else "DIFÍCIL")
    km = f'{C["length_m"] / 1000:.3f}'.replace(".", ",")
    return [(km, "KM"), (str(C["laps"]), "VOLTAS"), (f'{round(C["rain_probability"] * 100)}%', "CHANCE DE CHUVA"), (ov, "ULTRAPASSAGEM")]


# =============================================================================================
# DIREÇÃO 1 — GARAGEM (o carro da sua equipe sob a luz, menus como peças de um box)
# =============================================================================================
G_CSS = """
.scene{background:#0b0c0f;color:#eef0f3;font-family:Titillium;font-weight:600}
.wall{position:absolute;inset:0 0 250px 0;background:linear-gradient(#1b1e24,#111318 80%)}
.wall:before{content:"";position:absolute;inset:0;background:repeating-linear-gradient(180deg,rgba(255,255,255,.035) 0 1px,transparent 1px 46px)}
.floor{position:absolute;left:0;right:0;bottom:0;height:250px;background:linear-gradient(#181a1f,#0a0b0d)}
.lamp{position:absolute;top:0;height:6px;background:#f4f6fa;border-radius:0 0 4px 4px;box-shadow:0 0 34px 10px rgba(240,245,255,.22)}
.glow{position:absolute;inset:0;background:radial-gradient(ellipse 46% 40% at 64% 66%,rgba(24,104,219,.42),transparent 70%)}
.cone{position:absolute;left:470px;top:0;width:560px;height:720px;background:linear-gradient(rgba(255,255,255,.07),rgba(255,255,255,0) 75%);clip-path:polygon(38% 0,62% 0,100% 100%,0 100%)}
.car{position:absolute}.refl{position:absolute;transform:scaleY(-1);opacity:.13;-webkit-mask:linear-gradient(transparent 55%,#000)}
.logo{position:absolute;left:52px;top:34px;height:74px}
.season{position:absolute;left:56px;top:118px;font-size:13px;letter-spacing:3px;color:#9aa3b2}
.modes{position:absolute;left:52px;top:168px;width:388px;display:flex;flex-direction:column;gap:12px}
.mode{display:flex;align-items:center;gap:16px;border-radius:16px;padding:0 20px;background:rgba(255,255,255,.06)}
.mode b{display:block;font-weight:900;font-size:24px;letter-spacing:.5px;line-height:1}.mode small{display:block;font-size:15px;color:#a8b0bd;margin-top:5px}
.mode .go{margin-left:auto;width:44px;height:44px;border-radius:50%;display:grid;place-items:center;background:rgba(255,255,255,.1)}
.mode.main{height:112px;background:#f3f4f6;color:#11141a;position:relative;overflow:hidden}
.mode.main:before{content:"";position:absolute;left:0;top:0;bottom:0;width:7px;background:#E10600}
.mode.main b{font-size:34px}.mode.main small{color:#4b5260}.mode.main .go{background:#E10600;color:#fff;width:54px;height:54px}
.mode.alt{height:84px}
.mode.lock svg{flex:none}.mode.lock{height:50px;white-space:nowrap;background:none;color:#6c7380;padding-left:20px}.mode.lock b{font-size:18px;color:#7b8290}
.tag{font-size:12px;letter-spacing:2px;border-radius:20px;padding:4px 10px;background:rgba(255,255,255,.07);color:#8a92a0;margin-left:auto}
.pill{display:flex;align-items:center;gap:12px;border-radius:40px;padding:8px 18px 8px 10px;background:rgba(255,255,255,.07)}
.pill b{display:block;font-size:17px;font-weight:900;letter-spacing:1px}.pill small{display:block;font-size:13px;color:#a8b0bd}
.top{position:absolute;right:44px;top:40px;display:flex;align-items:center;gap:12px}
.swap{width:44px;height:44px;border-radius:50%;display:grid;place-items:center;background:rgba(255,255,255,.07)}
.plates{position:absolute;right:56px;bottom:40px;display:flex;gap:44px}
.plate{display:flex;align-items:flex-end;gap:12px}.plate .n{font-weight:900;font-size:62px;line-height:.8;color:transparent;-webkit-text-stroke:2px #5c93ea}
.plate b{display:block;font-size:20px;font-weight:900}.plate small{display:block;font-size:13px;color:#9aa3b2;letter-spacing:1.5px}
.note{position:absolute;font-size:11px;letter-spacing:1.5px;color:#5d6574}
/* configuração */
.hdr{position:absolute;left:44px;top:30px;display:flex;align-items:center;gap:16px}
.round{width:52px;height:52px;border-radius:50%;display:grid;place-items:center;background:rgba(255,255,255,.08)}
.hdr b{font-size:15px;letter-spacing:3px;font-weight:700;color:#9aa3b2;display:block}.hdr h1{font-size:30px;font-weight:900;letter-spacing:1px}
.map{position:absolute;left:30px;top:96px;width:830px;height:420px}
.map svg.trk{position:absolute;left:340px;top:6px;filter:drop-shadow(0 0 10px rgba(110,170,255,.55))}
.badge{display:inline-flex;gap:8px;align-items:center;border-radius:20px;padding:5px 12px;font-size:13px;letter-spacing:2px;font-weight:700}
.gpname{position:absolute;left:14px;top:40px;width:420px}
.gpname h2{font-size:50px;font-weight:900;line-height:.95;margin:14px 0 8px}.gpname p{font-size:16px;color:#a8b0bd}
.stats{position:absolute;left:14px;top:268px;display:grid;grid-template-columns:repeat(2,170px);gap:22px 26px}
.stat b{display:block;font-size:40px;font-weight:900;line-height:1}.stat small{font-size:12px;letter-spacing:2px;color:#8f98a7}
.panel{position:absolute;right:40px;top:92px;width:360px;display:flex;flex-direction:column;gap:13px}
.lbl{font-size:12px;letter-spacing:2.5px;color:#8f98a7;margin-bottom:8px}
.seg{display:flex;background:rgba(255,255,255,.07);border-radius:28px;padding:4px;gap:4px}
.seg span{flex:1;height:44px;border-radius:24px;display:grid;place-items:center;font-size:16px;font-weight:700;color:#c3c9d3}
.seg span.on{background:#f3f4f6;color:#11141a}
.wx{display:flex;gap:8px}.wx span{flex:1;height:58px;border-radius:14px;background:rgba(255,255,255,.07);display:flex;flex-direction:column;align-items:center;justify-content:center;gap:3px;font-size:13px;color:#c3c9d3}
.wx span.on{background:#f3f4f6;color:#11141a}
.cta{height:60px;margin-top:2px;background:#E10600;color:#fff;display:flex;align-items:center;justify-content:center;gap:12px;font-size:22px;font-weight:900;letter-spacing:1px;clip-path:polygon(0 0,calc(100% - 18px) 0,100% 18px,100% 100%,0 100%);border-radius:14px 0 14px 14px}
.cal{position:absolute;left:0;right:0;bottom:16px;height:108px;display:flex;gap:12px;padding-left:44px}
.card{flex:0 0 172px;border-radius:16px;background:rgba(255,255,255,.055);padding:12px 14px;position:relative}
.card .rd{font-size:12px;letter-spacing:2px;color:#8f98a7}.card b{display:block;font-size:17px;font-weight:900;margin-top:2px;white-space:nowrap}
.card small{font-size:13px;color:#a8b0bd}.card svg{position:absolute;right:10px;bottom:10px;opacity:.75}
.card.on{background:#f3f4f6;color:#11141a}.card.on small,.card.on .rd{color:#4b5260}.card.on:before{content:"";position:absolute;left:14px;right:14px;top:0;height:4px;border-radius:0 0 4px 4px;background:#1868DB}
.chip{font-size:10px;letter-spacing:1.5px;border-radius:10px;padding:2px 7px;margin-left:4px;vertical-align:middle;font-weight:700}
.chip.s{background:#E10600;color:#fff}.chip.n{background:#26324a;color:#ffd36b}
.fade{position:absolute;right:0;bottom:0;width:160px;height:170px;background:linear-gradient(90deg,transparent,#0b0c0f)}
"""


def g_home():
    nums = "".join(f'<div class="plate"><span class="n">{d["number"]}</span><div><small>{d["nationality"].upper()}</small><b>{d["name"]}</b></div></div>' for d in MY)
    car = car_svg(TEAM["color"], TEAM["color2"], MY[0]["number"], uid="h")
    body = f'''<div class="scene"><div class="wall"></div><div class="floor"></div><div class="glow"></div><div class="cone"></div>
<div class="lamp" style="left:560px;width:380px"></div><div class="lamp" style="left:1010px;width:170px;opacity:.6"></div>
<div class="car" style="left:450px;top:300px">{car}</div><div class="refl" style="left:450px;top:532px">{car_svg(TEAM["color"], TEAM["color2"], "", uid="r")}</div>
<img class="logo" src="../../game/assets/branding/logo.svg"><div class="season">TEMPORADA 2026 · 22 GRANDES PRÊMIOS</div>
<div class="modes">
<div class="mode main"><div><b>GRANDE PRÊMIO</b><small>Treinos, classificação, sprint e corrida</small></div><span class="go">{ico("chev", 28, "#fff", 3)}</span></div>
<div class="mode alt"><div><b>CORRIDA RÁPIDA</b><small>{C["short_name"]} · direto para a largada</small></div><span class="go">{ico("chev", 24)}</span></div>
<div class="mode lock">{ico("lock", 20, "#6c7380")}<b>CAMPANHA</b><span class="tag">EM DESENVOLVIMENTO</span></div>
<div class="mode lock" style="margin-top:-8px">{ico("lock", 20, "#6c7380")}<b>CORRIDA CAÓTICA</b><span class="tag">EM DESENVOLVIMENTO</span></div>
</div>
<div class="top">{team_pill()}<span class="swap">{ico("swap", 22, "#dfe3ea")}</span></div>
<div class="plates">{nums}</div>
<div class="note" style="left:470px;top:270px">CARRO: ILUSTRAÇÃO VETORIAL PROPOSTA (NÃO EXISTE NO JOGO)</div></div>'''
    return page("V3 · Garagem · início", G_CSS, body)


def g_gp():
    i = next(k for k, r in enumerate(CAL) if r["id"] == SEL)
    cards = ""
    for r in CAL[i - 3:i + 4]:
        c, date = round_info(r)
        on = " on" if r["id"] == SEL else ""
        chips = ('<span class="chip s">SPRINT</span>' if r["sprint"] else "") + ('<span class="chip n">NOITE</span>' if r["night"] else "")
        stroke = "#11141a" if on else "#c9d0db"
        cards += f'<div class="card{on}"><div class="rd">RD {r["round"]} · {date}</div><b>{c["city"]}</b><small>{chips}</small>{outline(r["id"], 62, 50, stroke, 3, 4)}</div>'
    stats = "".join(f'<div class="stat"><b>{v}</b><small>{k}</small></div>' for v, k in stats_list())
    grid = '<defs><pattern id="gp" width="40" height="40" patternUnits="userSpaceOnUse"><path d="M40 0H0V40" fill="none" stroke="rgba(255,255,255,.05)"/></pattern></defs><rect width="100%" height="100%" fill="url(#gp)"/>'
    x, y = start_dot(SEL, 480, 400, 30)
    trk = outline(SEL, 480, 400, "#f4f7ff", 9, 30, grid + f'<circle cx="{x}" cy="{y}" r="9" fill="#E10600"/>').replace("<svg ", '<svg class="trk" ', 1)
    body = f'''<div class="scene"><div class="wall" style="bottom:0"></div><div class="glow" style="background:radial-gradient(ellipse 40% 45% at 52% 42%,rgba(24,104,219,.28),transparent 70%)"></div>
<div class="hdr"><span class="round">{ico("back", 26, "#eef0f3", 2.6)}</span><div><b>GRANDE PRÊMIO · TEMPORADA 2026</b><h1>ESCOLHA O FIM DE SEMANA</h1></div></div>
<div class="map">{trk}<div class="gpname"><span class="badge" style="background:#1868DB">{ico("flag", 16, "#fff")} RD {CAL[i]["round"]} · 08 NOV</span>
<h2>{C["grand_prix"].upper()}</h2><p>{C["name"]}<br>{C["short_name"]}, {C["country"]} · fim de semana normal</p></div><div class="stats">{stats}</div></div>
<div class="panel"><div><div class="lbl">SUA EQUIPE</div><div style="display:flex;gap:10px;align-items:center">{team_pill()}<span class="swap">{ico("swap", 22, "#dfe3ea")}</span></div></div>
<div><div class="lbl">DURAÇÃO DA CORRIDA</div><div class="seg"><span class="on">25%</span><span>50%</span><span>100%</span></div></div>
<div><div class="lbl">CLIMA</div><div class="wx"><span class="on">{ico("globe", 22)}Realista</span><span>{ico("sun", 22)}Seco</span><span>{ico("rain", 22)}Chuva</span><span>{ico("mix", 22)}Variável</span></div></div>
<div><div class="lbl">FORMATO</div><div class="seg"><span class="on">Fim de semana</span><span>Só a corrida</span></div></div>
<div class="cta">COMEÇAR FIM DE SEMANA {ico("chev", 26, "#fff", 3)}</div></div>
<div class="cal">{cards}</div><div class="fade"></div></div>'''
    return page("V3 · Garagem · configuração", G_CSS, body)


# =============================================================================================
# DIREÇÃO 2 — CENTRAL DA EQUIPE (luz do dia, cartões com fotos do jogo, dados claros)
# =============================================================================================
T_CSS = """
.scene{background:#edf0f4;color:#0f1a2e;font-family:Barlow;font-weight:500}
h1,h2,h3,.num{font-family:SairaC;font-weight:800;letter-spacing:.3px}
.bar{position:absolute;left:0;right:0;top:0;height:76px;display:flex;align-items:center;padding:0 36px;gap:24px}
.bar img.logo{height:50px}
.tabs{display:flex;gap:6px;margin-left:24px;background:#dfe4eb;border-radius:24px;padding:4px}
.tabs span{height:40px;padding:0 18px;border-radius:20px;display:grid;place-items:center;font-size:15px;color:#4a5568;font-weight:500}
.tabs span.on{background:#fff;color:#0f1a2e;box-shadow:0 1px 2px rgba(15,26,46,.12)}
.team{margin-left:auto;display:flex;align-items:center;gap:12px;background:#fff;border-radius:30px;padding:6px 16px 6px 8px;box-shadow:0 1px 2px rgba(15,26,46,.1)}
.team b{font-family:SairaC;font-weight:800;font-size:18px;display:block;line-height:1}.team small{font-size:13px;color:#5b6678}
.card{position:absolute;background:#fff;border-radius:18px;box-shadow:0 1px 2px rgba(15,26,46,.08),0 10px 28px rgba(15,26,46,.07);overflow:hidden}
.photo{position:absolute;inset:0;background-size:cover;background-position:center}
.scrim{position:absolute;inset:0;background:linear-gradient(180deg,rgba(8,14,28,0) 30%,rgba(8,14,28,.82) 100%)}
.kick{font-size:13px;letter-spacing:2.5px;font-weight:500}
.btn{display:inline-flex;align-items:center;gap:10px;height:54px;padding:0 26px;border-radius:28px;font-family:SairaC;font-weight:800;font-size:20px;letter-spacing:.5px}
.btn.red{background:#E10600;color:#fff}.btn.ghost{background:#eef1f5;color:#0f1a2e}
.meta{display:flex;gap:8px;margin-top:14px}.meta span{background:rgba(255,255,255,.16);color:#fff;border-radius:16px;padding:6px 12px;font-size:14px}
.drv{display:flex;align-items:center;gap:12px;padding:10px 0;border-top:1px solid #edf0f4}
.drv .no{width:44px;height:44px;border-radius:12px;background:#1868DB;color:#fff;display:grid;place-items:center;font-family:SairaC;font-weight:800;font-size:20px}
.drv b{display:block;font-size:17px;font-weight:600}.drv small{color:#5b6678;font-size:13px}
.locked{display:flex;align-items:center;gap:14px;color:#8390a3;padding:0 22px;height:64px}
.locked b{font-family:SairaC;font-weight:800;font-size:20px;color:#7a879a}.locked small{margin-left:auto;font-size:12px;letter-spacing:2px}
.note{position:absolute;font-size:11px;letter-spacing:1.5px;color:#8390a3}
/* configuração */
.steps{display:flex;align-items:center;gap:10px;margin-left:30px}
.steps span{display:flex;align-items:center;gap:8px;font-size:15px;color:#5b6678}.steps i{font-style:normal;width:28px;height:28px;border-radius:50%;display:grid;place-items:center;background:#dfe4eb;font-family:SairaC;font-weight:800;font-size:15px}
.steps span.on{color:#0f1a2e}.steps span.on i{background:#0f1a2e;color:#fff}.steps em{width:26px;height:2px;background:#cfd6e0}
.list{padding:8px 0}.month{font-size:12px;letter-spacing:2.5px;color:#8390a3;padding:12px 20px 6px}
.rrow{display:flex;align-items:center;gap:12px;height:50px;padding:0 20px;font-size:16px}
.rrow .n{width:30px;font-family:SairaC;font-weight:800;color:#8390a3;font-size:17px}.rrow .d{margin-left:auto;color:#5b6678;font-size:14px}
.rrow.on{background:#e8f0fc;box-shadow:inset 4px 0 0 #1868DB}.rrow.on .n{color:#1868DB}
.chip{font-size:10px;letter-spacing:1.5px;border-radius:8px;padding:2px 7px;font-weight:700;flex:none;white-space:nowrap}.chip.s{background:#E10600;color:#fff}.chip.n{background:#1d2840;color:#ffd36b}
.tiles{display:grid;grid-template-columns:1fr 1fr;gap:12px}.tile{background:#f4f6f9;border-radius:14px;padding:14px 16px}
.tile .num{font-size:36px;line-height:1}.tile small{font-size:12px;letter-spacing:2px;color:#5b6678}
.lbl{font-size:12px;letter-spacing:2.5px;color:#5b6678;margin:18px 0 8px}
.seg{display:flex;background:#eef1f5;border-radius:14px;padding:4px;gap:4px}.seg span{flex:1;height:44px;border-radius:11px;display:grid;place-items:center;font-size:16px;color:#4a5568}
.seg span.on{background:#fff;color:#0f1a2e;box-shadow:0 1px 3px rgba(15,26,46,.15);font-weight:600}
.wx{display:grid;grid-template-columns:repeat(4,1fr);gap:6px}.wx span{height:62px;border-radius:12px;background:#eef1f5;display:flex;flex-direction:column;align-items:center;justify-content:center;gap:2px;font-size:13px;color:#4a5568}
.wx span.on{background:#0f1a2e;color:#fff}
"""


def t_home():
    drv = "".join(f'<div class="drv"><span class="no">{d["number"]}</span><div><b>{d["name"]}</b><small>{d["nationality"]}</small></div></div>' for d in MY)
    body = f'''<div class="scene">
<div class="bar"><img class="logo" src="../../game/assets/branding/logo-light.svg"><div class="tabs"><span class="on">Início</span><span>Grande Prêmio</span><span>Corrida rápida</span></div>
<div class="team"><img src="{EMB.format("williams")}" width="34"><div><b>{TEAM["name"].upper()}</b><small>Motor {TEAM["power_unit"]}</small></div></div></div>
<div class="card" style="left:36px;top:92px;width:768px;height:468px"><div class="photo" style="background-image:url(png/3d/clean_grid.png)"></div><div class="scrim"></div>
<div style="position:absolute;left:36px;bottom:34px;right:36px;color:#fff"><div class="kick">MODO PRINCIPAL · TEMPORADA 2026</div>
<h1 style="font-size:64px;line-height:.95;margin:8px 0 4px">GRANDE PRÊMIO</h1><div style="font-size:18px;opacity:.9">Escolha entre 22 fins de semana — treinos, classificação, sprint e corrida</div>
<div style="display:flex;align-items:center;margin-top:18px"><div class="meta" style="margin:0"><span>{SPRINTS} sprints</span><span>Clima dinâmico</span><span>Pista em 3D</span></div>
<span class="btn red" style="margin-left:auto">JOGAR {ico("chev", 22, "#fff", 3)}</span></div></div></div>
<div class="card" style="left:824px;top:92px;width:420px;height:232px"><div class="photo" style="background-image:url(png/3d/clean_follow.png);height:128px;bottom:auto"></div>
<div style="position:absolute;left:22px;right:22px;bottom:18px;display:flex;align-items:flex-end"><div><div class="kick" style="color:#5b6678">CORRIDA RÁPIDA</div><h3 style="font-size:28px;line-height:1.05">{C["short_name"].upper()}</h3>
<div style="font-size:15px;color:#5b6678">18 voltas · largada imediata</div></div><span class="btn ghost" style="margin-left:auto;height:48px">LARGAR</span></div></div>
<div class="card" style="left:824px;top:340px;width:420px;height:220px;padding:18px 22px"><div style="display:flex;align-items:center;gap:12px;margin-bottom:6px"><img src="{EMB.format("williams")}" width="30">
<h3 style="font-size:22px">SEUS PILOTOS</h3></div>{drv}</div>
<div class="card" style="left:36px;top:580px;width:594px;height:64px"><div class="locked">{ico("lock", 22, "#8390a3")}<b>CAMPANHA</b><small>EM DESENVOLVIMENTO</small></div></div>
<div class="card" style="left:650px;top:580px;width:594px;height:64px"><div class="locked">{ico("lock", 22, "#8390a3")}<b>CORRIDA CAÓTICA</b><small>EM DESENVOLVIMENTO</small></div></div>
<div class="note" style="left:40px;top:668px">FOTOS: CAPTURAS REAIS DO 3D ATUAL (GODOT) · TAMANHO DOS CARTÕES E ABAS AINDA NÃO EXISTEM NO JOGO</div></div>'''
    return page("V3 · Central da equipe · início", T_CSS, body)


def t_gp():
    i = next(k for k, r in enumerate(CAL) if r["id"] == SEL)
    rows, last_m = "", ""
    for r in CAL[i - 5:i + 3]:
        c, date = round_info(r)
        m = MONTHS[int(r["date"][5:7])]
        if m != last_m:
            rows += f'<div class="month">{ {"SET": "SETEMBRO", "OUT": "OUTUBRO", "NOV": "NOVEMBRO", "DEZ": "DEZEMBRO"}.get(m, m)}</div>'
            last_m = m
        chips = ('<span class="chip s">SPRINT</span>' if r["sprint"] else "") + ('<span class="chip n">NOITE</span>' if r["night"] else "")
        on = " on" if r["id"] == SEL else ""
        rows += f'<div class="rrow{on}"><span class="n">{r["round"]}</span><span>{r["grand_prix"]}</span>{chips}<span class="d">{date.title()}</span></div>'
    tiles = "".join(f'<div class="tile"><div class="num">{v}</div><small>{k}</small></div>' for v, k in stats_list())
    x, y = start_dot(SEL, 300, 250, 16)
    body = f'''<div class="scene">
<div class="bar"><span style="width:44px;height:44px;border-radius:50%;background:#fff;display:grid;place-items:center;box-shadow:0 1px 2px rgba(15,26,46,.1)">{ico("back", 24, "#0f1a2e", 2.6)}</span>
<h2 style="font-size:30px">GRANDE PRÊMIO</h2><div class="steps"><span class="on"><i>1</i>Circuito</span><em></em><span class="on"><i>2</i>Equipe</span><em></em><span class="on"><i>3</i>Condições</span></div>
<div class="team"><img src="{EMB.format("williams")}" width="34"><div><b>{TEAM["name"].upper()}</b><small>Albon · Sainz</small></div><span style="margin-left:6px">{ico("swap", 20, "#5b6678")}</span></div></div>
<div class="card" style="left:36px;top:92px;width:360px;height:596px"><div class="list">{rows}</div></div>
<div class="card" style="left:412px;top:92px;width:448px;height:596px;padding:22px 24px">
<div class="kick" style="color:#1868DB">RD {CAL[i]["round"]} · 08 DE NOVEMBRO</div><h2 style="font-size:40px;line-height:1;margin:4px 0 2px">{C["grand_prix"].upper()}</h2>
<div style="color:#5b6678;font-size:16px">{C["name"]} · {C["country"]}</div>
<div style="margin:10px auto 8px;width:300px">{outline(SEL, 300, 250, "#0f1a2e", 8, 16, f'<circle cx="{x}" cy="{y}" r="8" fill="#E10600"/>')}</div><div class="tiles">{tiles}</div></div>
<div class="card" style="left:876px;top:92px;width:368px;height:596px;padding:6px 24px 22px">
<div class="lbl">DURAÇÃO DA CORRIDA</div><div class="seg"><span class="on">25% · 18 v</span><span>50%</span><span>100%</span></div>
<div class="lbl">CLIMA</div><div class="wx"><span class="on">{ico("globe", 22)}Realista</span><span>{ico("sun", 22)}Seco</span><span>{ico("rain", 22)}Chuva</span><span>{ico("mix", 22)}Variável</span></div>
<div class="lbl">FORMATO</div><div class="seg"><span class="on">Fim de semana</span><span>Só a corrida</span></div>
<div style="margin-top:26px;background:#f4f6f9;border-radius:14px;padding:14px 16px;font-size:15px;line-height:1.5;color:#33415a"><b style="font-family:SairaC;font-size:17px">PROGRAMAÇÃO</b><br>Sexta · TL1, TL2<br>Sábado · TL3, Classificação<br>Domingo · Corrida</div>
<span class="btn red" style="position:absolute;left:24px;right:24px;bottom:22px;justify-content:center;height:62px;font-size:22px">COMEÇAR FIM DE SEMANA {ico("chev", 22, "#fff", 3)}</span></div></div>'''
    return page("V3 · Central da equipe · configuração", T_CSS, body)


# =============================================================================================
# DIREÇÃO 3 — LARGADA (pôster esportivo: diagonais de 12°, itálico, imagem em duotone)
# =============================================================================================
P_CSS = """
.scene{background:#0b0b0c;color:#f4f4f2;font-family:BarlowC;font-weight:600}
.disp{font-family:Kanit;font-weight:900;font-style:italic;text-transform:uppercase;letter-spacing:-.5px}
.hero{position:absolute;right:0;top:0;bottom:0;width:820px;clip-path:polygon(23% 0,100% 0,100% 100%,0 100%);overflow:hidden}
.hero .img{position:absolute;inset:0;background-size:cover;background-position:center;filter:grayscale(1) contrast(1.25) brightness(.9)}
.hero .tone{position:absolute;inset:0;background:#E10600;mix-blend-mode:multiply;opacity:.92}
.hero .shade{position:absolute;inset:0;background:linear-gradient(90deg,rgba(11,11,12,.55),transparent 40%)}
.edge{position:absolute;top:0;bottom:0;width:10px;background:#f4f4f2;transform:skewX(-12.7deg);transform-origin:top}
.logo{position:absolute;left:46px;top:36px;height:64px}
.big{position:absolute;left:46px;top:150px;font-size:116px;line-height:.86}
.sub{position:absolute;left:52px;top:372px;font-size:21px;color:#b9b9b6;letter-spacing:.5px}
.sk{display:flex;align-items:center;gap:12px;transform:skewX(-12deg);height:66px;padding:0 30px}
.sk>*{transform:skewX(12deg)}
.cta{position:absolute;left:52px;top:428px;background:#E10600;font-size:30px;font-family:Kanit;font-weight:900;font-style:italic}
.sec{position:absolute;left:52px;top:512px;background:#f4f4f2;color:#0b0b0c;height:56px;font-size:21px}
.lock{position:absolute;left:58px;display:flex;align-items:center;gap:10px;font-size:17px;color:#6f6f6c;letter-spacing:1.5px}
.ticker{position:absolute;left:0;right:0;bottom:0;height:46px;background:#f4f4f2;color:#0b0b0c;display:flex;align-items:center;gap:30px;padding-left:46px;font-size:17px;letter-spacing:2px}
.ticker b{font-family:Kanit;font-style:italic;font-weight:900;font-size:20px;color:#E10600}
.nums{position:absolute;right:48px;bottom:74px;display:flex;gap:26px;align-items:flex-end}
.nums .n{font-size:110px;line-height:.8;color:transparent;-webkit-text-stroke:2.5px #f4f4f2}
.nums small{display:block;font-size:15px;letter-spacing:2px}.nums b{font-size:22px}
.teamb{position:absolute;right:46px;top:38px;display:flex;align-items:center;gap:12px;background:#0b0b0c;padding:10px 20px 10px 12px;transform:skewX(-12deg)}
.teamb>*{transform:skewX(12deg)}.teamb b{font-family:Kanit;font-style:italic;font-weight:900;font-size:22px}
.note{position:absolute;font-size:11px;letter-spacing:1.5px;color:#7a7a77}
/* configuração */
.strip{position:absolute;left:0;right:0;top:0;height:92px;display:flex;align-items:center;gap:6px;padding-left:120px;background:#141415}
.rd{transform:skewX(-12deg);height:62px;min-width:74px;display:flex;align-items:center;justify-content:center;background:#202022;padding:0 14px}
.rd>*{transform:skewX(12deg)}.rd .disp{font-size:30px;color:#8b8b88}
.rd.on{background:#E10600;min-width:250px;gap:14px}.rd.on .disp{color:#fff;font-size:38px}.rd.on b{font-size:20px;letter-spacing:1px}
.back{position:absolute;left:30px;top:20px;width:52px;height:52px;display:grid;place-items:center;background:#202022;transform:skewX(-12deg)}
.band{position:absolute;left:-60px;top:150px;width:720px;height:330px;background:#E10600;transform:skewX(-12deg)}
.trk{position:absolute;left:150px;top:118px}
.title{position:absolute;left:52px;top:500px;font-size:68px;line-height:.9}
.place{position:absolute;left:56px;top:568px;font-size:20px;color:#b9b9b6}
.bigstats{position:absolute;left:720px;top:118px;display:grid;grid-template-columns:250px 250px;gap:14px 20px}
.bs{display:flex;align-items:baseline;gap:14px;border-left:4px solid #E10600;padding-left:16px}
.bs{flex-direction:column;align-items:flex-start;gap:0}.bs .disp{font-size:50px;line-height:.95}.bs small{font-size:15px;letter-spacing:2px;color:#b9b9b6}
.opts{position:absolute;left:52px;right:330px;bottom:30px;display:flex;gap:26px;align-items:flex-end}
.opt small{display:block;font-size:14px;letter-spacing:2px;color:#9a9a97;margin-bottom:8px}
.segs{display:flex;gap:6px}.segs span{transform:skewX(-12deg);height:50px;min-width:62px;padding:0 14px;display:grid;place-items:center;background:#202022;font-size:18px}
.segs span>i{transform:skewX(12deg);font-style:normal;display:flex;align-items:center;gap:6px}.segs span.on{background:#f4f4f2;color:#0b0b0c}
.go{position:absolute;right:40px;bottom:30px;height:80px;background:#E10600;font-family:Kanit;font-weight:900;font-style:italic;font-size:30px}
"""


def p_home():
    nums = "".join(f'<div style="display:flex;align-items:flex-end;gap:10px"><span class="n disp">{d["number"]}</span><div><small>{d["nationality"].upper()}</small><b>{d["name"].split(" ")[-1].upper()}</b></div></div>' for d in MY)
    body = f'''<div class="scene"><div class="hero"><div class="img" style="background-image:url(png/3d/clean_grid.png)"></div><div class="tone"></div><div class="shade"></div></div>
<div class="edge" style="left:640px"></div>
<img class="logo" src="../../game/assets/branding/logo.svg">
<div class="big disp">GRANDE<br>PRÊMIO</div><div class="sub">Temporada 2026 · treinos, classificação, sprint e corrida</div>
<div class="cta sk"><span>JOGAR</span>{ico("chev", 30, "#fff", 3.4)}</div>
<div class="sec sk"><span style="font-family:Kanit;font-style:italic;font-weight:900">CORRIDA RÁPIDA</span><span style="color:#55554f">· {C["short_name"].upper()}</span></div>
<div class="lock" style="top:592px">{ico("lock", 18, "#6f6f6c")} CAMPANHA — EM DESENVOLVIMENTO</div>
<div class="lock" style="top:620px">{ico("lock", 18, "#6f6f6c")} CORRIDA CAÓTICA — EM DESENVOLVIMENTO</div>
<div class="teamb"><img src="{EMB.format("williams")}" width="32"><b>{TEAM["name"].upper()}</b></div>
<div class="nums">{nums}</div>
<div class="ticker"><b>2026</b><span>22 GRANDES PRÊMIOS</span><span>{SPRINTS} SPRINTS</span><span>11 EQUIPES</span><span>22 PILOTOS</span><span>PISTA EM 3D</span></div>
<div class="note" style="left:700px;top:16px">FOTO: CAPTURA REAL DO 3D EM DUOTONE (FILTRO PROPOSTO)</div></div>'''
    return page("V3 · Largada · início", P_CSS, body)


def p_gp():
    i = next(k for k, r in enumerate(CAL) if r["id"] == SEL)
    rds = ""
    for r in CAL[i - 4:i + 4]:
        if r["id"] == SEL:
            rds += f'<div class="rd on"><span class="disp">{r["round"]}</span><b>{CIRC[r["id"]]["city"].upper()}</b></div>'
        else:
            rds += f'<div class="rd"><span class="disp">{r["round"]}</span></div>'
    stats = "".join(f'<div class="bs"><span class="disp">{v}</span><small>{k}</small></div>' for v, k in stats_list())
    x, y = start_dot(SEL, 470, 390, 20)
    trk = outline(SEL, 470, 390, "#f4f4f2", 11, 20, f'<circle cx="{x}" cy="{y}" r="11" fill="#0b0b0c" stroke="#f4f4f2" stroke-width="4"/>')
    body = f'''<div class="scene"><div class="strip">{rds}</div><div class="back">{ico("back", 26, "#f4f4f2", 2.8)}</div>
<div class="band"></div><div class="trk">{trk}</div>
<div class="title disp">{C["grand_prix"].upper()}</div><div class="place">{C["name"]} · {C["country"]} · 08 de novembro</div>
<div class="bigstats">{stats}</div>
<div class="opts" style="left:720px;right:auto;top:300px;bottom:auto;flex-direction:column;align-items:flex-start;gap:14px">
<div style="display:flex;gap:22px"><div class="opt"><small>EQUIPE</small><div class="segs"><span class="on"><i><img src="{EMB.format("williams")}" width="22"> {TEAM["name"].upper()}</i></span><span><i>{ico("swap", 20)}</i></span></div></div>
<div class="opt"><small>DURAÇÃO</small><div class="segs"><span class="on"><i>25%</i></span><span><i>50%</i></span><span><i>100%</i></span></div></div>
</div><div class="opt"><small>CLIMA</small><div class="segs"><span class="on"><i>{ico("globe", 18)}REALISTA</i></span><span><i>{ico("sun", 18)}SECO</i></span><span><i>{ico("rain", 18)}CHUVA</i></span><span><i>{ico("mix", 18)}VARIÁVEL</i></span></div></div>
<div class="opt"><small>FORMATO</small><div class="segs"><span class="on"><i>FIM DE SEMANA COMPLETO</i></span><span><i>SÓ A CORRIDA</i></span></div></div></div>
<div class="go sk"><span>COMEÇAR</span>{ico("chev", 32, "#fff", 3.4)}</div></div>'''
    return page("V3 · Largada · configuração", P_CSS, body)


if __name__ == "__main__":
    out = {"v3-1-garagem-inicio": g_home, "v3-1-garagem-gp": g_gp, "v3-2-central-inicio": t_home, "v3-2-central-gp": t_gp,
           "v3-3-largada-inicio": p_home, "v3-3-largada-gp": p_gp}
    for name, fn in out.items():
        (HERE / f"{name}.html").write_text(fn(), encoding="utf-8")
    print("ok")
