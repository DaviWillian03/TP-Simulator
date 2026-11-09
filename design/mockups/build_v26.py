"""V26 · Redesenho dos menus (decisões de 2026-11-09; inspiração: campanha do MM3, sem copiar).
Mais símbolos e menos escrita, uma cor de destaque por seção, blocos grandes com imagem, pista 3D, Sede 3D isométrica,
carro grande e calendário em cartões.
1) Tela inicial em mosaico  2) Grande Prêmio  3) Fim de semana  4) Campanha · Início (mosaico + barra de ícones)
5) Sede 3D com instalações  6) Calendário em cartões  7) Equipe (carro grande + pilotos)
As pistas são capturas do 3D do próprio jogo (img/v26, --view-only).
Uso: python design/mockups/build_v26.py   (V26_FACES=<pasta> V26_OUT=<pasta>: versão local com rostos)
"""
import os
import pathlib
import sys

sys.path.insert(0, str(pathlib.Path(__file__).parent))
import build as B  # noqa: E402
import build_v3 as V  # noqa: E402

HERE = B.HERE
FACES = os.environ.get("V26_FACES")
IMG = "img/v26/{}.jpg"
CAR = "../../game/assets/cars/{}.svg"
EMB = V.EMB
TEAM = "mercedes"
TC = B.teams[TEAM]["color"]

# cor de destaque por seção (vira token do UiStyle)
SEC = {"home": "#f3f4f6", "champ": "#E10600", "hist": "#F5C542", "staff": "#A66BFF", "car": "#FF8A1F",
       "design": "#4C8DFF", "hq": "#2FD38A", "spons": "#22C7E8", "money": "#F5C542", "board": "#FF5C8A",
       "cal": "#E10600", "drivers": "#4C8DFF"}

P = {
    "home": '<path d="M3 11l9-7 9 7"/><path d="M5 10v10h14V10"/><path d="M10 20v-6h4v6"/>',
    "trophy": '<path d="M7 4h10v5a5 5 0 0 1-10 0z"/><path d="M7 6H4a3 3 0 0 0 3 4M17 6h3a3 3 0 0 1-3 4"/><path d="M12 14v4M8 20h8"/>',
    "crown": '<path d="M3 8l4 4 5-7 5 7 4-4-2 11H5z"/>',
    "person": '<circle cx="12" cy="8" r="4"/><path d="M4 21c1-5 4-7 8-7s7 2 8 7"/>',
    "car": '<path d="M2 15h20l-2-4h-5l-2-3H8l-1 3H4z"/><circle cx="7" cy="16" r="2.4"/><circle cx="17" cy="16" r="2.4"/>',
    "pen": '<path d="M4 20l4-1 11-11-3-3L5 16z"/><path d="M14 6l3 3"/>',
    "factory": '<path d="M3 20V10l5 3V10l5 3V6h4l1 14z"/><path d="M3 20h18"/>',
    "hq": '<path d="M4 20V8l8-4 8 4v12"/><path d="M9 20v-5h6v5M8 10h2M14 10h2"/>',
    "hand": '<path d="M3 12l4-4 4 2 3-2 7 5-6 6-4-2-3 1z"/><path d="M11 10l3 3"/>',
    "money": '<circle cx="12" cy="12" r="9"/><path d="M15 9c-1-1-2-1.5-3-1.5-2 0-3 1-3 2.3 0 3 6 1.5 6 4.5 0 1.3-1.2 2.2-3 2.2-1.3 0-2.5-.6-3.2-1.5M12 6v1.5M12 16.8V18"/>',
    "gavel": '<path d="M13 4l7 7M10 7l7 7M12 5l-4 4 3 3 4-4"/><path d="M9 11l-6 6 2 2 6-6"/><path d="M13 20h8"/>',
    "cal": '<rect x="3" y="5" width="18" height="16" rx="3"/><path d="M3 10h18M8 3v4M16 3v4"/>',
    "rain": '<path d="M7 15a4 4 0 0 1 .5-8A6 6 0 0 1 19 9a3 3 0 0 1-1 6z"/><path d="M8 18l-1 3M12 18l-1 3M16 18l-1 3"/>',
    "sun": '<circle cx="12" cy="12" r="4"/><path d="M12 2v3M12 19v3M2 12h3M19 12h3M5 5l2 2M17 17l2 2M5 19l2-2M17 7l2-2"/>',
    "bell": '<path d="M6 16V11a6 6 0 0 1 12 0v5l2 2H4z"/><path d="M10 20a2 2 0 0 0 4 0"/>',
    "play": '<path d="M7 4l13 8-13 8z"/>',
    "chev": '<path d="M9 5l7 7-7 7"/>',
    "back": '<path d="M15 5l-7 7 7 7"/>',
    "wrench": '<path d="M14 6a4 4 0 0 0 5 5l-9 9-3-3 9-9a4 4 0 0 0-2-2z"/>',
    "flag": '<path d="M5 21V4h12l-2 4 2 4H5"/>',
    "gear": '<circle cx="12" cy="12" r="3"/><path d="M12 2v3M12 19v3M2 12h3M19 12h3M5 5l2 2M17 17l2 2M5 19l2-2M17 7l2-2"/>',
    "bolt": '<path d="M13 2L4 14h7l-1 8 9-12h-7z"/>',
    "smile": '<circle cx="12" cy="12" r="9"/><path d="M8 14c1 1.5 2.4 2.2 4 2.2s3-.7 4-2.2M9 9h.01M15 9h.01"/>',
    "wind": '<path d="M3 8h11a3 3 0 1 0-3-3M3 12h16a3 3 0 1 1-3 3M3 16h8"/>',
    "sim": '<rect x="3" y="4" width="18" height="12" rx="2"/><path d="M8 20h8M12 16v4"/>',
    "users": '<circle cx="9" cy="8" r="3.5"/><path d="M2 20c.8-4 3.4-6 7-6s6.2 2 7 6"/><circle cx="17" cy="8" r="3"/><path d="M17 14c2.5 0 4.3 1.8 5 5"/>',
    "lock": '<rect x="5" y="11" width="14" height="10" rx="2"/><path d="M8 11V8a4 4 0 0 1 8 0v3"/>',
    "check": '<path d="M5 12l5 5 9-10"/>',
    "plus": '<path d="M12 5v14M5 12h14"/>',
    "tyre": '<circle cx="12" cy="12" r="8"/><circle cx="12" cy="12" r="3"/>',
    "timer": '<circle cx="12" cy="13" r="8"/><path d="M12 9v4l3 2M9 2h6"/>',
    "up": '<path d="M12 19V5M5 12l7-7 7 7"/>',
    "globe": '<circle cx="12" cy="12" r="9"/><path d="M3 12h18M12 3c3 3 3 15 0 18M12 3c-3 3-3 15 0 18"/>',
}


def g(n, s=20, c="currentColor", w=2.2):
    return (f'<svg width="{s}" height="{s}" viewBox="0 0 24 24" fill="none" stroke="{c}" stroke-width="{w}" stroke-linecap="round" '
            f'stroke-linejoin="round" style="flex:none">{P[n]}</svg>')


def face(code, size, ring=None):
    d = B.drivers[code]
    col = B.teams[d["team"]]["color"]
    inner = (f'<img src="file://{FACES}/{d["id"]}_face.png" style="width:100%;height:100%;object-fit:cover">' if FACES
             else f'<b style="font-size:{size * .34:.0f}px">{code}</b>')
    bd = f"box-shadow:0 0 0 3px {ring};" if ring else ""
    return f'<span class="fc" style="width:{size}px;height:{size}px;background:{col};{bd}">{inner}</span>'


def ring(pct, size, col, label, sub="", w=6):
    r = size / 2 - w
    c = 2 * 3.14159 * r
    return (f'<span class="rg" style="width:{size}px;height:{size}px"><svg width="{size}" height="{size}">'
            f'<circle cx="{size/2}" cy="{size/2}" r="{r}" stroke="rgba(255,255,255,.12)" stroke-width="{w}" fill="none"/>'
            f'<circle cx="{size/2}" cy="{size/2}" r="{r}" stroke="{col}" stroke-width="{w}" fill="none" stroke-linecap="round" '
            f'stroke-dasharray="{c*pct:.1f} {c:.1f}" transform="rotate(-90 {size/2} {size/2})"/></svg>'
            f'<i><b>{label}</b>{f"<small>{sub}</small>" if sub else ""}</i></span>')


def tyre(letter, col, size=26):
    return (f'<span class="ty" style="width:{size}px;height:{size}px;border-color:{col};font-size:{size*.42:.0f}px">{letter}</span>')


SOFT = ("S", "#E8261C")
MEDI = ("M", "#F5C400")
HARD = ("H", "#F2F2F2")

CSS = V.G_CSS + """
.scene{background:#0d0f13}
.bgx{position:absolute;inset:0;background:radial-gradient(ellipse 60% 70% at 70% 30%,rgba(0,161,155,.22),transparent 70%),
 radial-gradient(ellipse 50% 60% at 10% 90%,rgba(76,141,255,.14),transparent 70%),linear-gradient(#141821,#0b0d11)}
.fc{border-radius:50%;overflow:hidden;display:grid;place-items:center;flex:none;color:#fff}
.ty{border-radius:50%;border:3px solid;background:#15171c;color:#fff;font-weight:900;display:grid;place-items:center;flex:none}
.cap{font-size:12px;letter-spacing:2.4px;color:#9aa3b2;font-weight:900;text-transform:uppercase}
.rg{position:relative;display:inline-grid;place-items:center;flex:none}.rg svg{position:absolute;inset:0}
.rg i{font-style:normal;text-align:center;line-height:1}.rg b{display:block;font-weight:900;font-size:20px}.rg small{display:block;font-size:12px;color:#a8b0bd;font-weight:800;margin-top:2px}
.tile{position:absolute;border-radius:22px;overflow:hidden;background:#171a21;box-shadow:0 10px 30px rgba(0,0,0,.35)}
.tile .hd{position:absolute;left:16px;top:14px;display:flex;align-items:center;gap:8px;font-weight:900;font-size:15px;letter-spacing:1px;text-transform:uppercase}
.tile .bdg{width:32px;height:32px;border-radius:10px;display:grid;place-items:center}
.cta{background:#E10600;color:#fff;font-weight:900;display:flex;align-items:center;justify-content:center;gap:10px;
 clip-path:polygon(0 0,calc(100% - 16px) 0,100% 16px,100% 100%,0 100%);border-radius:14px 0 14px 14px;padding:0 22px;white-space:nowrap}
.chip{display:inline-flex;align-items:center;gap:6px;height:30px;border-radius:15px;padding:0 12px;background:rgba(255,255,255,.1);font-weight:900;font-size:13px}
.top{position:absolute;left:0;right:0;top:0;height:76px;display:flex;align-items:center;gap:12px;padding:0 20px 0 18px;background:rgba(10,12,16,.75);backdrop-filter:blur(8px)}
.pill{height:46px;border-radius:23px;background:rgba(255,255,255,.07);display:flex;align-items:center;gap:8px;padding:0 16px;font-weight:900;font-size:17px}
.rail{position:absolute;left:0;top:76px;bottom:0;width:84px;background:rgba(10,12,16,.75);display:flex;flex-direction:column;align-items:center;gap:2px;padding-top:6px}
.ri{width:72px;height:56px;border-radius:14px;display:flex;flex-direction:column;align-items:center;justify-content:center;gap:3px;font-size:12px;font-weight:800;color:#a8b0bd}
.ri.on{background:rgba(255,255,255,.1);color:#fff}
.shade{position:absolute;inset:0;background:linear-gradient(180deg,rgba(8,10,14,0) 30%,rgba(8,10,14,.92))}
.big{font-weight:900;line-height:.9}
.num{position:absolute;font-weight:900;font-style:italic;line-height:.8;opacity:.95}
.bars span{display:flex;align-items:center;gap:8px;font-size:13px;font-weight:800;margin-top:6px}
.bars i{flex:1;height:8px;border-radius:4px;background:rgba(255,255,255,.12);overflow:hidden}.bars i u{display:block;height:100%;text-decoration:none}
"""


def topbar(title, sec):
    return (f'<div class="top"><span style="width:48px;height:48px;border-radius:50%;background:rgba(255,255,255,.08);display:grid;place-items:center">'
            f'{g("home", 22)}</span><img src="{EMB.format(TEAM)}" style="width:46px;height:46px;border-radius:12px">'
            f'<div><div class="cap" style="font-size:12px">MERCEDES · QUI 02 JUL 2026</div><div class="big" style="font-size:28px;color:{SEC[sec]}">{title}</div></div>'
            f'<span style="flex:1"></span>'
            f'<span class="pill">{g("money", 22, SEC["money"])}140 mi</span>'
            f'<span class="pill">{g("smile", 22, "#7fe0b1")}<span style="width:56px;height:8px;border-radius:4px;background:rgba(255,255,255,.12);overflow:hidden"><u style="display:block;width:72%;height:100%;background:#7fe0b1"></u></span></span>'
            f'<span class="pill" style="position:relative">{g("bell", 22)}<b style="position:absolute;right:6px;top:4px;width:18px;height:18px;border-radius:50%;background:#E10600;font-size:12px;display:grid;place-items:center">3</b></span>'
            f'<span class="cta" style="height:52px;font-size:18px">CONTINUAR {g("play", 18, "#fff")}</span></div>')


RAIL = [("home", "Início", "home"), ("trophy", "Tabela", "champ"), ("users", "Pilotos", "drivers"), ("car", "Carro", "car"),
        ("hq", "Sede", "hq"), ("cal", "Agenda", "cal"), ("person", "Pessoal", "staff"), ("hand", "Patroc.", "spons"),
        ("money", "Caixa", "money"), ("crown", "História", "hist"), ("gavel", "Regras", "board")]


def rail(on):
    items = "".join(f'<div class="ri{" on" if k == on else ""}">{g(i, 22, SEC[k] if k == on or True else "#a8b0bd")}{n}</div>'
                    for i, n, k in RAIL)
    return f'<div class="rail">{items}</div>'


# --- isometria (Sede 3D) -----------------------------------------------------------------------------------------

def shade(hx, f):
    hx = hx.lstrip("#")
    r, gg, b = (int(hx[i:i + 2], 16) for i in (0, 2, 4))
    if f >= 1:
        r, gg, b = (int(v + (255 - v) * (f - 1)) for v in (r, gg, b))
    else:
        r, gg, b = (int(v * f) for v in (r, gg, b))
    return f"#{r:02x}{gg:02x}{b:02x}"


class Iso:
    def __init__(self, ox, oy, s):
        self.ox, self.oy, self.s = ox, oy, s

    def p(self, x, y, z=0.0):
        return (self.ox + (x - y) * 0.866 * self.s, self.oy + (x + y) * 0.5 * self.s - z * self.s)

    def poly(self, pts, fill, extra=""):
        return f'<polygon points="{" ".join(f"{a:.1f},{b:.1f}" for a, b in pts)}" fill="{fill}" {extra}/>'

    def box(self, x, y, w, d, h, col, roof=None):
        P_ = self.p
        top = [P_(x, y, h), P_(x + w, y, h), P_(x + w, y + d, h), P_(x, y + d, h)]
        left = [P_(x, y + d, 0), P_(x + w, y + d, 0), P_(x + w, y + d, h), P_(x, y + d, h)]
        right = [P_(x + w, y, 0), P_(x + w, y + d, 0), P_(x + w, y + d, h), P_(x + w, y, h)]
        out = self.poly(left, shade(col, .78)) + self.poly(right, shade(col, .58)) + self.poly(top, roof or shade(col, 1.18))
        # janelas na face da esquerda
        n = max(int(w * 1.2), 2)
        for i in range(n):
            fx = x + (i + .3) * w / n
            win = [P_(fx, y + d, h * .35), P_(fx + w / n * .45, y + d, h * .35), P_(fx + w / n * .45, y + d, h * .7), P_(fx, y + d, h * .7)]
            out += self.poly(win, "rgba(200,235,255,.55)")
        return out


BUILDINGS = [  # id, nome, ícone, x, y, w, d, h, cor, nível, máx
    ("factory", "Fábrica", "factory", 1.0, 1.0, 7.0, 3.6, 1.8, "#FF8A1F", 4, 10),
    ("wind", "Túnel de vento", "wind", 10.0, 1.0, 6.5, 2.4, 1.6, "#22C7E8", 3, 10),
    ("design", "Centro técnico", "pen", 6.0, 6.5, 3.6, 3.6, 4.2, "#4C8DFF", 5, 10),
    ("sim", "Simulador", "sim", 1.0, 7.0, 3.4, 3.2, 2.2, "#A66BFF", 2, 8),
    ("drivers", "Centro de pilotos", "users", 11.5, 6.0, 4.6, 3.0, 1.4, "#2FD38A", 1, 8),
    ("hosp", "Hospitalidade", "hand", 11.5, 11.0, 5.0, 2.2, 1.1, "#F5C542", 2, 6),
]


def campus(ox, oy, s, sel=None, badges=True, w_=1280, h_=720):
    iso = Iso(ox, oy, s)
    svg = iso.poly([iso.p(-1, -1), iso.p(19, -1), iso.p(19, 15), iso.p(-1, 15)], "#1f3b2f")
    svg += iso.poly([iso.p(-1, 15), iso.p(19, 15), iso.p(19, 15, -.6), iso.p(-1, 15, -.6)], "#132219")
    svg += iso.poly([iso.p(19, -1), iso.p(19, 15), iso.p(19, 15, -.6), iso.p(19, -1, -.6)], "#0e1912")
    # pista de testes e ruas
    svg += iso.poly([iso.p(-.5, 5), iso.p(18.5, 5), iso.p(18.5, 5.8), iso.p(-.5, 5.8)], "#3a3f48")
    svg += iso.poly([iso.p(9.9, 5.8), iso.p(10.7, 5.8), iso.p(10.7, 14.5), iso.p(9.9, 14.5)], "#3a3f48")
    svg += iso.poly([iso.p(1, 11.2), iso.p(9, 11.2), iso.p(9, 14), iso.p(1, 14)], "#2b4a3a")
    for i in range(6):
        svg += iso.poly([iso.p(1.5 + i * 1.2, 12), iso.p(2.1 + i * 1.2, 12), iso.p(2.1 + i * 1.2, 13.4), iso.p(1.5 + i * 1.2, 13.4)], "#e8edf3")
    labels = ""
    for bid, name, ic, x, y, w, d, h, col, lv, mx in sorted(BUILDINGS, key=lambda b: b[3] + b[4]):
        on = bid == sel
        svg += iso.box(x, y, w, d, h, col if (sel is None or on) else shade(col, .55))
        if on:
            svg += iso.poly([iso.p(x - .3, y - .3), iso.p(x + w + .3, y - .3), iso.p(x + w + .3, y + d + .3), iso.p(x - .3, y + d + .3)],
                            "none", 'stroke="#fff" stroke-width="3" stroke-dasharray="8 6"')
        if badges:
            cx, cy = iso.p(x + w / 2, y + d / 2, h)
            labels += (f'<div class="bl{" on" if on else ""}" style="left:{cx - 60:.0f}px;top:{cy - 58:.0f}px;--c:{col}">'
                       f'<span class="bi">{g(ic, 18, "#11141a")}</span><b>{lv}</b><small>/{mx}</small></div>')
    return f'<svg width="{w_}" height="{h_}" style="position:absolute;left:0;top:0">{svg}</svg>{labels}'


ISO_CSS = """
.bl{position:absolute;width:120px;display:flex;align-items:center;justify-content:center;gap:4px}
.bl .bi{width:30px;height:30px;border-radius:9px;background:var(--c);display:grid;place-items:center}
.bl b{font-size:22px;font-weight:900;text-shadow:0 2px 6px #000}.bl small{font-size:13px;font-weight:900;color:#c3c9d3;text-shadow:0 2px 6px #000}
.bl.on .bi{box-shadow:0 0 0 3px #fff}
"""


# --- telas -----------------------------------------------------------------------------------------------------

def inicio():
    css = CSS + """
.logo2{position:absolute;left:40px;top:28px;height:58px}
"""
    camp = (f'<div class="tile" style="left:40px;top:110px;width:700px;height:570px;background:linear-gradient(135deg,#0f3d3a,#0b1916)">'
            f'<div style="position:absolute;inset:0;background:radial-gradient(ellipse 60% 50% at 60% 60%,{TC}55,transparent 70%)"></div>'
            f'<img src="{CAR.format(TEAM)}" style="position:absolute;left:40px;top:250px;width:640px">'
            f'<div style="position:absolute;left:28px;top:26px"><span class="chip" style="background:#E10600">{g("trophy", 16, "#fff")}CAMPANHA</span>'
            f'<div class="big" style="font-size:64px;margin-top:14px">MERCEDES</div>'
            f'<div style="display:flex;gap:10px;margin-top:12px"><span class="chip">{g("cal", 16)}RD 9/22</span><span class="chip">{g("trophy", 16, "#F5C542")}1º</span>'
            f'<span class="chip">{g("money", 16, "#F5C542")}140 mi</span></div></div>'
            f'<span class="cta" style="position:absolute;right:28px;bottom:28px;height:64px;font-size:22px">CONTINUAR {g("play", 20, "#fff")}</span></div>')
    gp = (f'<div class="tile" style="left:760px;top:110px;width:480px;height:300px">'
          f'<img src="{IMG.format("spa")}" style="position:absolute;inset:0;width:100%;height:100%;object-fit:cover"><div class="shade"></div>'
          f'<div style="position:absolute;left:22px;bottom:20px"><span class="chip" style="background:#4C8DFF">{g("flag", 16, "#fff")}GRANDE PRÊMIO</span>'
          f'<div class="big" style="font-size:40px;margin-top:10px">1 FIM DE SEMANA</div></div>'
          f'<span style="position:absolute;right:20px;bottom:20px;width:58px;height:58px;border-radius:50%;background:#fff;display:grid;place-items:center">{g("play", 24, "#11141a")}</span></div>')
    small = [("crown", "HISTÓRIA", "#F5C542", "15 lendas"), ("gear", "OPÇÕES", "#9aa3b2", ""), ("plus", "NOVA EQUIPE", "#2FD38A", "12ª do grid")]
    sm = "".join(f'<div class="tile" style="left:{760 + i * 164}px;top:430px;width:152px;height:250px;background:linear-gradient(160deg,{c}33,#171a21 60%)">'
                 f'<span style="position:absolute;left:18px;top:20px;width:52px;height:52px;border-radius:16px;background:{c};display:grid;place-items:center">{g(ic, 28, "#11141a")}</span>'
                 f'<div style="position:absolute;left:18px;bottom:20px"><div class="big" style="font-size:20px">{n}</div>'
                 f'{f"<div style=font-size:13px;color:#a8b0bd;font-weight:800;margin-top:4px>{sub}</div>" if sub else ""}</div></div>'
                 for i, (ic, n, c, sub) in enumerate(small))
    body = (f'<div class="scene"><div class="bgx"></div><img class="logo2" src="../../game/assets/branding/logo.svg" onerror="this.style.display=\'none\'">'
            f'<div style="position:absolute;right:44px;top:44px" class="cap">TEMPORADA 2026</div>{camp}{gp}{sm}</div>')
    return V.page("V26 · Tela inicial em mosaico", css, body)


def gp():
    cards = [("silverstone", "Grã-Bretanha", "#E10600", False), ("spa", "Bélgica", "#4C8DFF", True), ("hungaroring", "Hungria", "#2FD38A", False),
             ("zandvoort", "Holanda", "#FF8A1F", False)]
    cc = ""
    for i, (cid, n, col, on) in enumerate(cards):
        x = 40 + i * 250 - (0 if not on else 10)
        w, h, y = (260, 330, 96) if on else (230, 300, 111)
        x = 40 + i * 248
        cc += (f'<div class="tile" style="left:{x}px;top:{y}px;width:{w}px;height:{h}px;{"box-shadow:0 0 0 4px #fff,0 16px 40px rgba(0,0,0,.5)" if on else ""}">'
               f'<img src="{IMG.format(cid)}" style="position:absolute;inset:0;width:100%;height:100%;object-fit:cover;transform:scale(1.5)"><div class="shade"></div>'
               f'<span style="position:absolute;left:14px;top:14px;width:10px;height:40px;border-radius:5px;background:{col}"></span>'
               f'<div style="position:absolute;left:16px;bottom:16px"><div class="big" style="font-size:26px">{n.upper()}</div>'
               f'<div style="display:flex;gap:6px;margin-top:8px">{g("rain" if on else "sun", 18, "#9fd2ff" if on else "#F5C542")}'
               f'{tyre(*SOFT, 22)}{tyre(*MEDI, 22)}{tyre(*HARD, 22)}</div></div></div>')
    teams = ["mercedes", "ferrari", "mclaren", "redbull", "williams", "astonmartin", "alpine", "haas", "audi", "racingbulls", "cadillac"]
    tt = "".join(f'<span style="width:60px;height:60px;border-radius:16px;background:{B.teams[t]["color"]}33;display:grid;place-items:center;'
                 f'{"box-shadow:0 0 0 3px #fff;" if t == TEAM else ""}"><img src="{EMB.format(t)}" style="width:42px;height:42px;border-radius:10px"></span>' for t in teams)
    seg = lambda items, on: '<div style="display:flex;gap:6px">' + "".join(
        f'<span class="chip" style="height:44px;padding:0 16px;font-size:15px;{"background:#f3f4f6;color:#11141a" if k == on else ""}">{n}</span>' for k, n in items) + "</div>"
    panel = (f'<div style="position:absolute;left:40px;top:450px;right:40px;height:230px;border-radius:22px;background:#171a21;padding:18px 22px">'
             f'<div style="display:flex;gap:28px;align-items:flex-start"><div><div class="cap">{g("car", 16)} EQUIPE</div>'
             f'<div style="display:grid;grid-template-columns:repeat(6,60px);gap:8px;margin-top:10px">{tt}</div></div>'
             f'<div><div class="cap">CATEGORIA</div><div style="margin-top:10px">{seg([("f1", "F1"), ("f2", "F2"), ("f3", "F3")], "f1")}</div>'
             f'<div class="cap" style="margin-top:16px">DURAÇÃO</div><div style="margin-top:10px">{seg([("25", "25%"), ("50", "50%"), ("100", "100%")], "25")}</div></div>'
             f'<div><div class="cap">CLIMA</div><div style="margin-top:10px">{seg([("a", g("rain", 18) + " real"), ("s", g("sun", 18))], "a")}</div>'
             f'<div class="cap" style="margin-top:16px">SESSÕES</div><div style="margin-top:10px">{seg([("all", "Todas"), ("r", "Só corrida")], "all")}</div></div></div>'
             f'<span class="cta" style="position:absolute;right:22px;bottom:22px;height:64px;font-size:22px">LARGAR {g("play", 20, "#fff")}</span></div>')
    head = (f'<div style="position:absolute;left:40px;top:28px;display:flex;align-items:center;gap:14px"><span style="width:48px;height:48px;border-radius:50%;'
            f'background:rgba(255,255,255,.08);display:grid;place-items:center">{g("back", 22)}</span><div class="big" style="font-size:34px;color:#4C8DFF">GRANDE PRÊMIO</div></div>')
    return V.page("V26 · Grande Prêmio", CSS, f'<div class="scene"><div class="bgx"></div>{head}{cc}{panel}</div>')


DONE = f'<span style="position:absolute;right:18px;top:22px">{g("check", 28, "#7fe0b1")}</span>'


def fds():
    sess = [("T1", "TREINO 1", "#9aa3b2", "done", "Acerto 72%"), ("T2", "TREINO 2", "#9aa3b2", "done", "Acerto 81%"),
            ("T3", "TREINO 3", "#4C8DFF", "now", "60 min"), ("Q", "CLASSIFICAÇÃO", "#A66BFF", "", "sáb 15:00"), ("R", "CORRIDA", "#E10600", "", "dom 15:00")]
    st = ""
    for i, (k, n, c, s, sub) in enumerate(sess):
        on = s == "now"
        st += (f'<div class="tile" style="left:{40 + i * 242}px;top:400px;width:230px;height:200px;background:{"#f3f4f6" if on else "#171a21"};color:{"#11141a" if on else "#fff"}">'
               f'<span style="position:absolute;left:18px;top:18px;width:58px;height:58px;border-radius:18px;background:{c};display:grid;place-items:center;font-weight:900;font-size:24px;color:#fff">{k}</span>'
               f'{DONE if s == "done" else ""}'
               f'<div style="position:absolute;left:18px;bottom:18px"><div class="big" style="font-size:21px">{n}</div>'
               f'<div style="font-size:14px;font-weight:800;margin-top:6px;color:{"#4b5260" if on else "#a8b0bd"}">{sub}</div></div></div>')
    hero = (f'<div class="tile" style="left:40px;top:96px;width:800px;height:288px">'
            f'<img src="{IMG.format("silverstone")}" style="position:absolute;inset:0;width:100%;height:100%;object-fit:cover"><div class="shade"></div>'
            f'<div style="position:absolute;left:24px;bottom:22px"><span class="chip">{g("flag", 16)}RODADA 9</span><div class="big" style="font-size:52px;margin-top:8px">GRÃ-BRETANHA</div></div>'
            f'<div style="position:absolute;right:22px;bottom:22px;display:flex;gap:10px">'
            + "".join(f'<span style="width:62px;height:76px;border-radius:14px;background:rgba(10,12,16,.75);display:flex;flex-direction:column;align-items:center;justify-content:center;gap:4px;font-weight:900;font-size:14px">{g(ic, 24, cl)}{t}</span>'
                      for ic, cl, t in [("sun", "#F5C542", "sex"), ("rain", "#9fd2ff", "sáb"), ("rain", "#9fd2ff", "dom")])
            + "</div></div>")
    stock = (f'<div class="tile" style="left:860px;top:96px;width:380px;height:288px;padding:18px">'
             f'<div class="cap">{g("tyre", 16)} PNEUS DO FIM DE SEMANA</div>'
             f'<div style="display:flex;flex-direction:column;gap:12px;margin-top:16px">'
             + "".join(f'<div style="display:flex;align-items:center;gap:10px">{tyre(l, c, 36)}<div style="display:flex;gap:5px">'
                       + "".join(f'<span style="width:22px;height:22px;border-radius:50%;background:{c if j < n else "transparent"};border:2px solid {c};opacity:{1 if j < n else .4}"></span>' for j in range(t))
                       + f'</div><b style="margin-left:auto;font-size:20px">{n}</b></div>' for l, c, n, t in [("S", "#E8261C", 5, 8), ("M", "#F5C400", 3, 3), ("H", "#F2F2F2", 2, 2)])
             + f'</div><div style="display:flex;gap:10px;margin-top:18px">{ring(.81, 64, "#2FD38A", "81%")}<div style="font-size:14px;font-weight:800;color:#a8b0bd;align-self:center">{g("wrench", 18, "#2FD38A")} acerto</div></div></div>')
    go = (f'<span class="cta" style="position:absolute;right:40px;bottom:28px;height:64px;font-size:22px">TREINO 3 {g("play", 20, "#fff")}</span>'
          f'<span class="pill" style="position:absolute;left:40px;bottom:32px">{g("timer", 20)}simular até a classificação</span>')
    head = (f'<div style="position:absolute;left:40px;top:24px;display:flex;align-items:center;gap:14px"><span style="width:48px;height:48px;border-radius:50%;'
            f'background:rgba(255,255,255,.08);display:grid;place-items:center">{g("back", 22)}</span><img src="{EMB.format(TEAM)}" style="width:44px;height:44px;border-radius:12px">'
            f'<div class="big" style="font-size:30px">FIM DE SEMANA</div></div>')
    return V.page("V26 · Fim de semana", CSS, f'<div class="scene"><div class="bgx"></div>{head}{hero}{stock}{st}{go}</div>')


def campanha():
    X0 = 100
    nxt = (f'<div class="tile" style="left:{X0}px;top:92px;width:540px;height:330px">'
           f'<img src="{IMG.format("silverstone")}" style="position:absolute;inset:0;width:100%;height:100%;object-fit:cover"><div class="shade"></div>'
           f'<div class="hd"><span class="bdg" style="background:#E10600">{g("flag", 18, "#fff")}</span>PRÓXIMO GP</div>'
           f'<span class="chip" style="position:absolute;right:16px;top:14px;background:#E10600">{g("timer", 16, "#fff")}1 DIA</span>'
           f'<div style="position:absolute;left:20px;bottom:18px"><div class="big" style="font-size:44px">GRÃ-BRETANHA</div>'
           f'<div style="display:flex;gap:8px;margin-top:10px;align-items:center"><span class="chip">{g("cal", 16)}05 jul</span><span class="chip">{g("rain", 16, "#9fd2ff")}35%</span>'
           f'<span class="chip" style="background:#A66BFF">SPRINT</span></div></div>'
           f'<div style="position:absolute;right:18px;bottom:18px;display:flex;gap:6px">{ring(.6, 58, "#4C8DFF", g("wind", 20))}{ring(.25, 58, "#F5C542", g("bolt", 20))}{ring(.85, 58, "#2FD38A", "P1")}</div></div>')
    drv = "".join(
        f'<div style="position:absolute;left:{i * 190}px;top:0;width:186px;height:330px;background:linear-gradient(180deg,{TC}40,transparent 70%)">'
        f'<span class="num" style="left:10px;top:44px;font-size:120px;color:{TC};opacity:.35">{n}</span>'
        f'<div style="position:absolute;left:50%;top:70px;transform:translateX(-50%)">{face(c, 96, TC)}</div>'
        f'<div style="position:absolute;left:0;right:0;top:186px;text-align:center"><div class="big" style="font-size:22px">{nm}</div>'
        f'<div style="display:flex;justify-content:center;gap:8px;margin-top:10px">{ring(p, 62, "#4C8DFF", pos, pts)}</div></div></div>'
        for i, (c, n, nm, pos, pts, p) in enumerate([("RUS", 63, "RUSSELL", "4º", "250", .7), ("ANT", 12, "ANTONELLI", "1º", "380", 1.0)]))
    drivers = (f'<div class="tile" style="left:{X0 + 556}px;top:92px;width:380px;height:330px">{drv}'
               f'<div class="hd" style="left:auto;right:16px"><span class="bdg" style="background:#4C8DFF">{g("users", 18, "#fff")}</span></div></div>')
    car = (f'<div class="tile" style="left:{X0}px;top:438px;width:540px;height:266px;background:linear-gradient(160deg,#2a1a0b,#171a21 60%)">'
           f'<div class="hd"><span class="bdg" style="background:#FF8A1F">{g("car", 18, "#11141a")}</span>CARRO</div>'
           f'<span class="chip" style="position:absolute;right:16px;top:14px">{g("factory", 16, "#FF8A1F")}2/3</span>'
           f'<img src="{CAR.format(TEAM)}" style="position:absolute;left:24px;top:56px;width:490px">'
           f'<div style="position:absolute;left:20px;right:20px;bottom:14px;display:flex;justify-content:space-between">'
           + "".join(ring(v / 100, 58, c, str(v)) for v, c in [(91, "#F5C542"), (88, "#E10600"), (93, "#4C8DFF"), (86, "#2FD38A")])
           + "</div></div>")
    hq = (f'<div class="tile" style="left:{X0 + 556}px;top:438px;width:380px;height:266px;background:linear-gradient(160deg,#0d2a1f,#171a21 70%)">'
          f'<div style="position:absolute;inset:0;transform:scale(.62);transform-origin:-60px -30px">{campus(330, 70, 26, badges=False, w_=900, h_=500)}</div>'
          f'<div class="hd"><span class="bdg" style="background:#2FD38A">{g("hq", 18, "#11141a")}</span>SEDE</div>'
          f'<span class="chip" style="position:absolute;right:16px;top:14px;background:#2FD38A;color:#11141a">{g("up", 16, "#11141a")}1 OBRA</span></div>')
    side = (f'<div class="tile" style="left:{X0 + 952}px;top:92px;width:212px;height:390px;padding:16px">'
            f'<div style="display:flex;align-items:center;gap:8px;font-weight:900;font-size:15px">{g("trophy", 20, "#E10600")}TABELA</div>'
            + "".join(f'<div style="display:flex;align-items:center;gap:8px;margin-top:12px;{"background:rgba(255,255,255,.08);border-radius:10px;margin-left:-6px;padding:4px 6px" if t == TEAM else ""}">'
                      f'<b style="width:18px;font-size:16px">{i + 1}</b><span style="width:6px;height:28px;border-radius:3px;background:{B.teams[t]["color"]}"></span>'
                      f'<img src="{EMB.format(t)}" style="width:28px;height:28px;border-radius:8px"><b style="margin-left:auto;font-size:15px">{p}</b></div>'
                      for i, (t, p) in enumerate([("mercedes", 630), ("mclaren", 541), ("ferrari", 488), ("redbull", 402), ("williams", 160), ("astonmartin", 98)]))
            + "</div>")
    meta = (f'<div class="tile" style="left:{X0 + 952}px;top:498px;width:212px;height:206px;display:flex;flex-direction:column;align-items:center;justify-content:center;gap:10px">'
            f'{ring(1.0, 104, "#FF5C8A", "1º", "meta 1º", 9)}<div style="font-weight:900;font-size:14px;display:flex;gap:6px;align-items:center">{g("gavel", 18, "#FF5C8A")}DIRETORIA</div></div>')
    body = f'<div class="scene"><div class="bgx"></div>{nxt}{drivers}{car}{hq}{side}{meta}{topbar("INÍCIO", "home")}{rail("home")}</div>'
    return V.page("V26 · Campanha · Início em mosaico", CSS, body)


def sede():
    css = CSS + ISO_CSS
    bg = '<div style="position:absolute;inset:0;background:radial-gradient(ellipse 60% 60% at 40% 55%,#1d3a2e,#0b0f0d 75%)"></div>'
    nodes = ""
    lv = 3
    for i in range(10):
        on = i < lv
        nxt = i == lv
        nodes += (f'<span style="width:44px;height:44px;border-radius:12px;display:grid;place-items:center;'
                  f'background:{"#22C7E8" if on else ("#f3f4f6" if nxt else "rgba(255,255,255,.06)")};'
                  f'{"box-shadow:0 0 0 3px #22C7E8;" if nxt else ""}">{g("check" if on else ("up" if nxt else "lock"), 20, "#11141a" if (on or nxt) else "#5b6270")}</span>')
    panel = (f'<div style="position:absolute;right:20px;top:92px;width:400px;bottom:20px;border-radius:22px;background:rgba(18,21,27,.92);padding:20px">'
             f'<div style="display:flex;align-items:center;gap:12px"><span style="width:56px;height:56px;border-radius:16px;background:#22C7E8;display:grid;place-items:center">{g("wind", 30, "#11141a")}</span>'
             f'<div><div class="cap">INSTALAÇÃO</div><div class="big" style="font-size:28px">TÚNEL DE VENTO</div></div></div>'
             f'<div style="display:flex;align-items:center;gap:16px;margin-top:18px">{ring(.3, 96, "#22C7E8", "3", "de 10", 9)}'
             f'<div class="bars" style="flex:1"><span>{g("wind", 18, "#4C8DFF")}<i><u style="width:62%;background:#4C8DFF"></u></i>+6%</span>'
             f'<span>{g("timer", 18, "#22C7E8")}<i><u style="width:40%;background:#22C7E8"></u></i>−8%</span></div></div>'
             f'<div class="cap" style="margin-top:20px">MELHORIAS</div><div style="display:grid;grid-template-columns:repeat(5,44px);gap:10px;margin-top:10px">{nodes}</div>'
             f'<div style="margin-top:20px;border-radius:16px;background:rgba(255,255,255,.06);padding:14px">'
             f'<div style="display:flex;align-items:center;gap:8px;font-weight:900;font-size:17px">{g("up", 20, "#22C7E8")}NÍVEL 4</div>'
             f'<div style="display:flex;gap:8px;margin-top:10px"><span class="chip">{g("wind", 16, "#4C8DFF")}+2% aero</span><span class="chip">{g("money", 16, "#F5C542")}12 mi</span>'
             f'<span class="chip">{g("cal", 16)}6 sem</span></div></div>'
             f'<span class="cta" style="position:absolute;left:20px;right:20px;bottom:20px;height:60px;font-size:20px">CONSTRUIR {g("hq", 20, "#fff")}</span></div>')
    body = (f'<div class="scene">{bg}{campus(430, 150, 30, sel="wind")}{panel}{topbar("SEDE", "hq")}{rail("hq")}'
            f'<div style="position:absolute;left:110px;bottom:24px;display:flex;gap:8px"><span class="chip">{g("hq", 16, "#2FD38A")}17 / 52 níveis</span>'
            f'<span class="chip">{g("timer", 16)}1 obra · 3 sem</span></div></div>')
    return V.page("V26 · Sede 3D com instalações", css, body)


def calendario():
    races = [("silverstone", "GRÃ-BRETANHA", "05 jul", "next", "#2FD38A", "forte", True), ("spa", "BÉLGICA", "19 jul", "", "#F5C542", "neutro", False),
             ("hungaroring", "HUNGRIA", "26 jul", "", "#E10600", "fraco", False), ("zandvoort", "HOLANDA", "23 ago", "", "#2FD38A", "forte", False),
             ("monza", "ITÁLIA", "06 set", "", "#F5C542", "neutro", False)]
    done = [("interlagos", "P2"), ("spa", "P1"), ("monza", "P1")]
    cards = ""
    for i, (cid, n, d, s, ac, at, spr) in enumerate(races):
        nx = s == "next"
        x = 204 + i * 210
        cards += (f'<div class="tile" style="left:{x}px;top:{104 if nx else 116}px;width:196px;height:{574 if nx else 550}px;{"box-shadow:0 0 0 4px #fff" if nx else ""}">'
                  f'<div style="position:absolute;left:0;top:0;right:0;height:56%;overflow:hidden"><img src="{IMG.format(cid)}" style="width:100%;height:100%;object-fit:cover;transform:scale(1.35)">'
                  f'<div style="position:absolute;left:0;right:0;bottom:0;height:40%;background:linear-gradient(transparent,#171a21)"></div></div>'
                  f'<div style="position:absolute;left:14px;top:14px;display:flex;gap:6px"><span class="chip" style="background:rgba(10,12,16,.8)">{9 + i}</span>'
                  f'{"<span class=chip style=background:#A66BFF>SPRINT</span>" if spr else ""}</div>'
                  f'<div style="position:absolute;left:14px;right:14px;top:54%"><div class="big" style="font-size:22px">{n}</div>'
                  f'<div style="display:flex;align-items:center;gap:6px;margin-top:6px;font-weight:800;font-size:14px;color:#a8b0bd">{g("cal", 16)}{d}</div>'
                  f'<div style="display:flex;gap:6px;margin-top:12px">{tyre(*SOFT, 28)}{tyre(*MEDI, 28)}{tyre(*HARD, 28)}</div>'
                  f'<div style="display:flex;align-items:center;gap:8px;margin-top:12px"><span style="width:34px;height:34px;border-radius:10px;background:{ac};display:grid;place-items:center">{g("car", 20, "#11141a")}</span>'
                  f'<b style="font-size:15px;color:{ac}">{at}</b></div></div>'
                  f'{"<span class=cta style=position:absolute;left:14px;right:14px;bottom:14px;height:48px;font-size:16px>IR " + g("play", 16, "#fff") + "</span>" if nx else ""}</div>')
    past = "".join(f'<div style="display:flex;align-items:center;gap:8px;margin-top:10px"><img src="{IMG.format(c)}" style="width:64px;height:40px;border-radius:8px;object-fit:cover">'
                   f'<b style="font-size:18px;color:{"#F5C542" if r == "P1" else "#fff"}">{r}</b></div>' for c, r in done)
    side = f'<div style="position:absolute;left:100px;top:122px;width:84px">{g("check", 18, "#7fe0b1")}<div class="cap" style="margin-top:4px">8 FEITAS</div>{past}</div>'
    body = f'<div class="scene"><div class="bgx"></div>{side}{cards}{topbar("AGENDA", "cal")}{rail("cal")}</div>'
    return V.page("V26 · Calendário em cartões", CSS, body)


def equipe():
    css = CSS + ".att{display:flex;gap:10px;margin-top:12px}"
    bg = (f'<div style="position:absolute;inset:0;background:radial-gradient(ellipse 70% 55% at 55% 70%,{TC}44,transparent 70%),linear-gradient(#141821,#0b0d11)"></div>'
          f'<div style="position:absolute;left:84px;right:0;bottom:0;height:240px;background:linear-gradient(#181b21,#0a0b0d)"></div>')
    carimg = (f'<img src="{CAR.format(TEAM)}" style="position:absolute;left:330px;top:300px;width:820px">'
              f'<img src="{CAR.format(TEAM)}" style="position:absolute;left:330px;top:300px;width:820px;transform:translateY(176px) scaleY(-1);opacity:.12">')
    dcards = ""
    for i, (c, n, nm, pos, rt) in enumerate([("RUS", 63, "GEORGE RUSSELL", "4º", (89, 90, 86)), ("ANT", 12, "KIMI ANTONELLI", "1º", (87, 82, 84))]):
        x = 110 if i == 0 else 980
        dcards += (f'<div class="tile" style="left:{x}px;top:96px;width:280px;height:250px;background:linear-gradient(160deg,{TC}55,#171a21 70%)">'
                   f'<span class="num" style="right:10px;top:4px;font-size:150px;color:#fff;opacity:.16">{n}</span>'
                   f'<div style="position:absolute;left:18px;top:18px">{face(c, 84, TC)}</div>'
                   f'<div style="position:absolute;left:18px;top:116px"><div class="big" style="font-size:22px">{nm}</div>'
                   f'<div class="att">{ring(rt[0] / 100, 54, "#E10600", str(rt[0]))}{ring(rt[1] / 100, 54, "#2FD38A", str(rt[1]))}{ring(rt[2] / 100, 54, "#4C8DFF", str(rt[2]))}'
                   f'<span style="align-self:center;font-weight:900;font-size:26px;margin-left:6px">{pos}</span></div></div></div>')
    stats = (f'<div style="position:absolute;left:400px;top:100px;width:540px;display:flex;justify-content:space-between">'
             + "".join(f'<div style="text-align:center">{ring(v / 100, 92, c, str(v), "", 8)}<div style="margin-top:8px">{g(ic, 22, c)}</div></div>'
                       for v, c, ic in [(91, "#F5C542", "bolt"), (88, "#E10600", "gear"), (93, "#4C8DFF", "wind"), (86, "#2FD38A", "check")])
             + "</div>")
    legend = (f'<div style="position:absolute;left:110px;bottom:24px;display:flex;gap:8px"><span class="chip">{g("bolt", 16, "#F5C542")}reta</span>'
              f'<span class="chip">{g("gear", 16, "#E10600")}lentas</span><span class="chip">{g("wind", 16, "#4C8DFF")}rápidas</span>'
              f'<span class="chip">{g("check", 16, "#2FD38A")}confiab.</span></div>'
              f'<span class="cta" style="position:absolute;right:30px;bottom:24px;height:56px;font-size:18px">PEÇAS {g("wrench", 18, "#fff")}</span>')
    body = f'<div class="scene">{bg}{carimg}{stats}{dcards}{legend}{topbar("EQUIPE", "drivers")}{rail("drivers")}</div>'
    return V.page("V26 · Equipe: carro grande e pilotos", css, body)


if __name__ == "__main__":
    out = pathlib.Path(os.environ["V26_OUT"]) if os.environ.get("V26_OUT") else HERE
    if os.environ.get("V26_OUT"):
        B.FONTS = B.FONTS.replace("url(fonts/", f"url(file://{(HERE / 'fonts').resolve()}/")
    pages = {"v26-1-inicio": inicio, "v26-2-grande-premio": gp, "v26-3-fim-de-semana": fds, "v26-4-campanha-inicio": campanha,
             "v26-5-sede-3d": sede, "v26-6-calendario": calendario, "v26-7-equipe": equipe}
    for name, fn in pages.items():
        (out / f"{name}.html").write_text(fn(), encoding="utf-8")
    print("ok")
