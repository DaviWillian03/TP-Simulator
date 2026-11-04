"""V18 · Estúdio de design do carro (P9 aprovada; tinta/acabamento só visual). Item 4 da fila de 2026-11-04.
1) Pintura em camadas + acabamentos + gerar pintura. 2) Patrocínios nas zonas do carro. 3) Lançamento do carro.
Uso: python design/mockups/build_v18.py  (V18_OUT=<pasta> para gerar fora do repositório)
"""
import json
import os
import pathlib
import sys

sys.path.insert(0, str(pathlib.Path(__file__).parent))
sys.path.insert(0, str(pathlib.Path(__file__).parent.parent.parent / "tools"))
import build as B  # noqa: E402
import build_v3 as V  # noqa: E402
import make_car_art as CA  # noqa: E402

HERE = B.HERE
ROOT = HERE.parent.parent
ico = V.ico
SPONS = json.loads((ROOT / "game/data/sponsors.json").read_text(encoding="utf-8"))
TEAM = B.teams["williams"]
C1, C2 = TEAM["color"], "#F2F2F2"

G = {
    "eye": '<path d="M2 12s4-7 10-7 10 7 10 7-4 7-10 7S2 12 2 12z"/><circle cx="12" cy="12" r="3"/>',
    "grip": '<path d="M9 6h.01M15 6h.01M9 12h.01M15 12h.01M9 18h.01M15 18h.01"/>',
    "move": '<path d="M12 2v20M2 12h20M12 2l-3 3M12 2l3 3M12 22l-3-3M12 22l3-3M2 12l3-3M2 12l3 3M22 12l-3-3M22 12l-3 3"/>',
    "rot": '<path d="M20 12a8 8 0 1 1-3-6.3M20 4v5h-5"/>',
    "mirror": '<path d="M12 3v18M8 7l-5 5 5 5zM16 7l5 5-5 5z"/>',
    "drop": '<path d="M12 3s6 7 6 11a6 6 0 0 1-12 0c0-4 6-11 6-11z"/>',
    "trash": '<path d="M4 7h16M10 11v6M14 11v6M6 7l1 13h10l1-13M9 7V4h6v3"/>',
    "dice": '<rect x="4" y="4" width="16" height="16" rx="3"/><circle cx="9" cy="9" r="1.2"/><circle cx="15" cy="15" r="1.2"/><circle cx="15" cy="9" r="1.2"/><circle cx="9" cy="15" r="1.2"/>',
    "plus": '<path d="M12 5v14M5 12h14"/>',
    "star": '<path d="M12 3l2.7 5.6 6.1.9-4.4 4.3 1 6.1L12 17l-5.4 2.9 1-6.1L3.2 9.5l6.1-.9z"/>',
    "cam": '<path d="M3 8h4l2-3h6l2 3h4v11H3z"/><circle cx="12" cy="13" r="4"/>',
    "fans": '<circle cx="8" cy="8" r="3"/><circle cx="16" cy="8" r="3"/><path d="M2 20c0-4 3-6 6-6s6 2 6 6M10 20c0-4 3-6 6-6s6 2 6 6"/>',
}


def g(n, s=20, c="currentColor", w=2.2):
    return f'<svg width="{s}" height="{s}" viewBox="0 0 24 24" fill="none" stroke="{c}" stroke-width="{w}" stroke-linecap="round" stroke-linejoin="round" style="flex:none">{G[n]}</svg>'


def painted_car(w=760, plates=None, pins=False):
    """Carro lateral (mesma arte do jogo) com camadas extras recortadas na carroceria."""
    svg = CA.car(C1, C2)
    clip = "".join(f'<path d="{d}"/>' for d in CA.BODY)
    layers = f'''<defs><clipPath id="body">{clip}</clipPath>
<linearGradient id="fade" x1="0" y1="0" x2="1" y2="0"><stop offset="0" stop-color="#0b1e5c" stop-opacity="0"/><stop offset=".6" stop-color="#0b1e5c" stop-opacity=".0"/><stop offset="1" stop-color="#0b1e5c" stop-opacity=".85"/></linearGradient>
<pattern id="hex" width="22" height="19" patternUnits="userSpaceOnUse"><path d="M5.5 0h11l5.5 9.5-5.5 9.5h-11L0 9.5z" fill="none" stroke="#fff" stroke-opacity=".12" stroke-width="1.2"/></pattern></defs>
<g clip-path="url(#body)"><rect x="0" y="0" width="1000" height="280" fill="url(#fade)"/>
<path d="M300 280L520 90 600 90 380 280Z" fill="#00E1FF" opacity=".9"/><path d="M400 280L620 90 640 90 420 280Z" fill="#fff" opacity=".9"/>
<rect x="560" y="90" width="430" height="150" fill="url(#hex)"/></g>
<text x="660" y="198" font-family="Titillium" font-weight="900" font-size="44" fill="#fff" font-style="italic">23</text>'''
    if plates:
        for x, y, txt, wv in plates:
            layers += (f'<rect x="{x}" y="{y}" width="{wv}" height="22" rx="4" fill="#fff" opacity=".95"/>'
                       f'<text x="{x + wv / 2}" y="{y + 16}" text-anchor="middle" font-family="Titillium" font-weight="900" font-size="15" fill="#11141a">{txt}</text>')
    svg = svg.replace("<circle cx=\"468\"", layers + "<circle cx=\"468\"", 1)
    return svg.replace('width="1000" height="280"', f'width="{w}" height="{int(w * 0.28)}"', 1)


CSS = V.G_CSS + """
.scene{background:#07080a}
.sbg{position:absolute;inset:0;background:radial-gradient(ellipse 60% 55% at 50% 50%,#1b2a55,#07080a 72%)}
.sbg:after{content:"";position:absolute;left:0;right:0;top:470px;bottom:0;background:linear-gradient(rgba(255,255,255,.04),transparent)}
.hd3{position:absolute;left:36px;top:20px;right:36px;display:flex;align-items:center;gap:14px}
.rb{width:50px;height:50px;border-radius:50%;background:rgba(255,255,255,.08);display:grid;place-items:center;flex:none}
.hd3 h1{font-size:26px;font-weight:900;line-height:1}.hd3 small{display:block;font-size:12px;letter-spacing:3px;color:#8f98a7;font-weight:900}
.tabs3{position:absolute;left:36px;top:84px;display:flex;gap:4px;background:rgba(255,255,255,.06);border-radius:26px;padding:4px}
.tabs3 span{height:44px;padding:0 18px;border-radius:22px;display:flex;align-items:center;gap:8px;font-weight:900;font-size:15px;color:#c3c9d3}.tabs3 span.on{background:#f3f4f6;color:#11141a}
.btn3{height:48px;border-radius:24px;background:rgba(255,255,255,.08);display:flex;align-items:center;gap:8px;padding:0 18px;font-weight:900;font-size:14px}
.save{background:#E10600}
.lp{position:absolute;left:36px;top:150px;width:240px;border-radius:20px;background:rgba(8,9,12,.72);padding:12px}
.ly{display:flex;align-items:center;gap:8px;height:46px;border-radius:12px;padding:0 8px;margin-top:5px;background:rgba(255,255,255,.04);font-size:13px;font-weight:900}
.ly.on{background:#f3f4f6;color:#11141a}
.ly .sw{width:22px;height:22px;border-radius:7px;flex:none;border:2px solid rgba(255,255,255,.3)}
.ly small{display:block;font-size:11px;color:#8f98a7;font-weight:700}.ly.on small{color:#4b5260}
.ly .end{margin-left:auto;display:flex;gap:6px;opacity:.7}
.addl{display:flex;align-items:center;justify-content:center;gap:6px;height:42px;border-radius:12px;border:2px dashed rgba(255,255,255,.18);margin-top:8px;font-size:13px;font-weight:900;color:#a8b0bd}
.carbox{position:absolute;left:290px;top:250px;width:700px}
.carbox .refl{transform:scaleY(-1);opacity:.16;margin-top:-6px;-webkit-mask-image:linear-gradient(transparent 45%,#000)}
.tools{position:absolute;left:420px;top:528px;display:flex;gap:8px}
.tools span{width:52px;height:52px;border-radius:16px;background:rgba(255,255,255,.08);display:grid;place-items:center}
.tools span.on{background:#f3f4f6}
.rp{position:absolute;right:36px;top:150px;width:262px;border-radius:20px;background:rgba(8,9,12,.72);padding:12px}
.sws{display:grid;grid-template-columns:repeat(6,1fr);gap:7px;margin-top:6px}
.sws i{display:block;height:32px;border-radius:9px;border:2px solid rgba(255,255,255,.12)}
.sws i.on{border-color:#fff;box-shadow:0 0 0 3px rgba(255,255,255,.25)}
.fin{display:grid;grid-template-columns:repeat(4,1fr);gap:6px;margin-top:6px}
.fin div{border-radius:12px;background:rgba(255,255,255,.05);padding:7px 2px;text-align:center;font-size:11px;font-weight:900}
.fin div.on{background:#f3f4f6;color:#11141a}
.fin b{display:block;width:30px;height:30px;border-radius:50%;margin:0 auto 4px}
.note{font-size:11px;color:#8f98a7;font-weight:700;margin-top:10px;line-height:1.35}
.hex{display:flex;align-items:center;gap:8px;margin-top:8px;height:38px;border-radius:10px;background:rgba(0,0,0,.35);padding:0 10px;font-size:14px;font-weight:900;font-family:monospace}
/* patrocínios */
.zpin{position:absolute;display:flex;align-items:center;gap:6px;height:34px;border-radius:17px;background:rgba(8,9,12,.9);padding:0 12px 0 6px;font-size:12px;font-weight:900;border:1px solid rgba(255,255,255,.14)}
.zpin i{width:22px;height:22px;border-radius:50%;background:#E10600;display:grid;place-items:center;font-style:normal;font-size:11px}
.zpin.free i{background:rgba(255,255,255,.2)}
.zr{display:flex;align-items:center;gap:8px;height:50px;border-radius:12px;background:rgba(255,255,255,.04);padding:0 10px;margin-top:5px;font-size:13px;font-weight:900}
.zr small{display:block;font-size:11px;color:#8f98a7;font-weight:700}
.zr .val{margin-left:auto;text-align:right}.zr .val b{display:block;font-size:14px}.zr .val small{color:#7fe0b1}
.zr.free{border:2px dashed rgba(255,255,255,.18);background:none}
.brand{height:24px;border-radius:5px;background:#fff;color:#11141a;font-size:11px;font-weight:900;display:grid;place-items:center;padding:0 8px}
.tot{display:flex;justify-content:space-between;margin-top:10px;font-size:14px;font-weight:900}
.tot span:first-child{color:#a8b0bd}
/* lançamento */
.dim{position:absolute;inset:0;background:rgba(0,0,0,.6)}
.launch{position:absolute;left:190px;top:70px;width:900px;border-radius:26px;background:#101318;overflow:hidden;box-shadow:0 30px 80px rgba(0,0,0,.7)}
.launch .stage{height:250px;background:radial-gradient(ellipse 60% 70% at 50% 60%,#1347F555,#05060a 75%);position:relative}
.launch .stage:before{content:"";position:absolute;left:30%;top:-20px;width:140px;height:290px;background:linear-gradient(rgba(255,255,255,.25),transparent);transform:skewX(-12deg);filter:blur(4px)}
.launch .stage:after{content:"";position:absolute;right:30%;top:-20px;width:140px;height:290px;background:linear-gradient(rgba(255,255,255,.18),transparent);transform:skewX(12deg);filter:blur(4px)}
.launch .lc{position:absolute;left:120px;top:60px}
.launch .bd{padding:18px 28px 22px}
.launch h2{font-size:32px;font-weight:900;line-height:1}
.stars{display:flex;gap:4px;margin-top:8px}
.quotes{display:flex;gap:10px;margin-top:14px}
.quotes>div{flex:1;border-radius:14px;background:rgba(255,255,255,.06);padding:10px 12px;font-size:13px;line-height:1.35;color:#c3c9d3;font-weight:700}
.quotes b{display:block;color:#fff;font-size:12px;letter-spacing:1px;margin-bottom:4px}
.gains{display:flex;gap:10px;margin-top:14px}
.gains>div{flex:1;display:flex;align-items:center;gap:10px;border-radius:14px;background:rgba(57,211,107,.12);padding:10px 12px}
.gains b{display:block;font-size:20px;font-weight:900;color:#7fe0b1}.gains small{font-size:12px;color:#a8b0bd;font-weight:700}
.cta4{height:56px;width:260px;background:#E10600;color:#fff;font-weight:900;font-size:18px;display:flex;align-items:center;justify-content:center;gap:10px;margin-left:auto;margin-top:16px;
 clip-path:polygon(0 0,calc(100% - 18px) 0,100% 18px,100% 100%,0 100%);border-radius:14px 0 14px 14px}
"""


def head(tab):
    tabs = "".join(f'<span class="{"on" if t == tab else ""}">{t}</span>' for t in ["Pintura", "Patrocínios", "Capacete", "Logo", "Especiais · 1/3"])
    return f'''<div class="hd3"><span class="rb">{ico("back", 24, "#eef0f3", 2.6)}</span>{V.emb_img("williams", 44) if hasattr(V, "emb_img") else f'<img src="{V.EMB.format("williams")}" width="44">'}
<div><small>WILLIAMS · CARRO 2027</small><h1>ESTÚDIO DE DESIGN</h1></div>
<span class="btn3" style="margin-left:auto">{g("dice", 18)} Gerar pintura</span><span class="btn3 save">SALVAR {ico("chev", 18, "#fff", 3)}</span></div>
<div class="tabs3">{tabs}</div>'''


def car_block(svg, left=290, top=250, w=700):
    return f'<div class="carbox" style="left:{left}px;top:{top}px;width:{w}px">{svg}<div class="refl">{svg}</div></div>'


def paint():
    layers = [("Base", "cor sólida · metálico", C1, False), ("Faixa diagonal", "ciano + branco", "#00E1FF", True), ("Degradê", "azul-noite, da traseira", "#0b1e5c", False),
              ("Hexágonos", "padrão · 12%", "#ffffff", False), ("Número 23", "itálico", "#ffffff", False)]
    lh = "".join(f'<div class="ly{" on" if on else ""}"><span class="sw" style="background:{c}"></span><div>{n}<small>{s}</small></div><span class="end">{g("eye", 16)}{g("grip", 16)}</span></div>'
                 for n, s, c, on in layers)
    sw = ["#1347F5", "#00E1FF", "#ffffff", "#0b1e5c", "#11141a", "#E10600", "#ffd24a", "#3c9d5d", "#ff8000", "#c77dff", "#8f98a7", "#d4a017"]
    swh = "".join(f'<i class="{"on" if c == "#00E1FF" else ""}" style="background:{c}"></i>' for c in sw)
    fins = [("Brilho", "radial-gradient(circle at 35% 30%,#fff,#00b8d4 45%,#006b7a)"), ("Fosco", "#00a9c0"), ("Metálico", "conic-gradient(#7ff3ff,#00a9c0,#d8fcff,#008ea3,#7ff3ff)"),
            ("Perolado", "linear-gradient(135deg,#e8fdff,#a6f3ff,#f6d8ff)"), ("Cromado", "linear-gradient(160deg,#fff,#7d8a94 45%,#fff 55%,#4b555d)"),
            ("Neon", "radial-gradient(circle,#b8ffff,#00f0ff)"), ("Carbono", "repeating-linear-gradient(45deg,#1b1d22 0 4px,#2c3038 4px 8px)")]
    fh = "".join(f'<div class="{"on" if n == "Metálico" else ""}"><b style="background:{bg}"></b>{n}</div>' for n, bg in fins)
    tools = "".join(f'<span class="{"on" if n == "move" else ""}">{g(n, 22, "#11141a" if n == "move" else "#eef0f3")}</span>' for n in ["move", "rot", "mirror", "drop", "trash"])
    body = f'''<div class="scene"><div class="sbg"></div>{head("Pintura")}
<div class="lp"><div class="cap">CAMADAS · 5 DE 12</div>{lh}<div class="addl">{g("plus", 16)} Camada</div></div>
{car_block(painted_car())}<div class="tools">{tools}</div>
<div class="rp"><div class="cap">COR DA FAIXA</div><div class="sws">{swh}</div><div class="hex"><span style="width:18px;height:18px;border-radius:5px;background:#00E1FF"></span>#00E1FF</div>
<div class="cap" style="margin-top:14px">ACABAMENTO</div><div class="fin">{fh}</div>
<div class="note">A pintura é só visual: não muda o desempenho. Uma pintura marcante rende mídia no lançamento do carro.</div></div></div>'''
    return V.page("V18 · Estúdio · pintura", CSS, body)


def sponsors():
    zones = SPONS["zones"]
    deals = {"rear_wing": ("Dell", 2.4), "sidepods": ("Pepsi", 2.0), "nose": ("Havaianas", 1.1), "halo": None, "front_wing": ("Natura", 0.9)}
    plates = [(890, 125, "DELL", 82), (560, 168, "PEPSI", 90), (150, 200, "HAVAIANAS", 110), (40, 250, "NATURA", 80)]
    svg = painted_car(600, plates=plates)
    # pinos das zonas (posição do JSON, relativa à arte 1000×280 → caixa 700×196 em 290,250)
    pins = ""
    for z in zones:
        x = 320 + z["pin"][0] * 600
        y = 270 + z["pin"][1] * 168
        d = deals.get(z["id"])
        pins += (f'<div class="zpin{" free" if d is None else ""}" style="left:{x - (120 if z["id"] == "rear_wing" else 11):.0f}px;top:{y - 60:.0f}px"><i>{"$" if d else "+"}</i>{z["name"]}</div>')
    rows = ""
    for z in zones:
        d = deals.get(z["id"])
        if d:
            rows += (f'<div class="zr"><span class="brand">{d[0].upper()}</span><div>{z["name"]}<small>visibilidade ×{z["mult"]}</small></div>'
                     f'<div class="val"><b>US$ {d[1]:.1f} mi</b><small>por corrida</small></div></div>').replace(".", ",", 1)
        else:
            rows += f'<div class="zr free">{g("plus", 18)}<div>{z["name"]}<small>livre · ver ofertas</small></div><div class="val"><b>até US$ 0,8 mi</b></div></div>'
    body = f'''<div class="scene"><div class="sbg"></div>{head("Patrocínios")}
{car_block(svg, 320, 270, 600)}{pins}
<div class="rp" style="width:300px"><div class="cap">ZONAS DO CARRO</div>{rows}<div class="tot"><span>Total por corrida</span><span>US$ 6,4 mi</span></div>
<div class="note">Arraste uma marca para uma zona. Zonas mais visíveis pagam mais; um carro limpo rende menos.</div></div>
<div class="lp" style="width:240px"><div class="cap">OFERTAS · ZONA HALO</div>
<div class="zr"><span class="brand">LOGITECH</span><div>3 anos<small>exige halo</small></div><div class="val"><b>0,8</b></div></div>
<div class="zr"><span class="brand">EMBRACO</span><div>1 ano<small>qualquer zona</small></div><div class="val"><b>0,6</b></div></div></div></div>'''
    return V.page("V18 · Estúdio · patrocínios", CSS, body)


def launch():
    stars = "".join(g("star", 26, "#ffd24a" if i < 4 else "#4b5260", 2.2).replace('fill="none"', f'fill="{"#ffd24a" if i < 4 else "none"}"') for i in range(5))
    body = f'''<div class="scene"><div class="sbg"></div>{head("Pintura")}{car_block(painted_car())}<div class="dim"></div>
<div class="launch"><div class="stage"><div class="lc">{painted_car(660)}</div></div>
<div class="bd"><div class="cap">APRESENTAÇÃO · 12 FEV 2027 · SILVERSTONE</div><h2>WILLIAMS FW49 É REVELADO</h2>
<div class="stars">{stars}<span style="margin-left:10px;font-size:14px;font-weight:900;color:#c3c9d3;align-self:center">nota da crítica 4 de 5</span></div>
<div class="quotes"><div><b>REVISTA DO PADDOCK</b>"A faixa ciano é ousada e funciona. Um dos carros mais bonitos do grid."</div>
<div><b>TORCIDA</b>"Melhor pintura desde os anos 90. Já quero a miniatura."</div></div>
<div class="gains"><div>{g("fans", 28, "#7fe0b1")}<div><b>+6%</b><small>fãs</small></div></div><div>{g("cam", 28, "#7fe0b1")}<div><b>+4</b><small>mídia (influência)</small></div></div>
<div>{g("star", 28, "#7fe0b1")}<div><b>+US$ 0,5 mi</b><small>bônus das marcas</small></div></div></div>
<div class="cta4">CONTINUAR {ico("chev", 20, "#fff", 3)}</div></div></div></div>'''
    return V.page("V18 · Lançamento do carro", CSS, body)


if __name__ == "__main__":
    out = pathlib.Path(os.environ["V18_OUT"]) if os.environ.get("V18_OUT") else HERE
    if os.environ.get("V18_OUT"):
        B.FONTS = B.FONTS.replace("url(fonts/", f"url(file://{(HERE / 'fonts').resolve()}/")
        V.EMB = "file://" + str((ROOT / "game/assets/emblems").resolve()) + "/{}.svg"
    (out / "v18-1-estudio-pintura.html").write_text(paint(), encoding="utf-8")
    (out / "v18-2-estudio-patrocinios.html").write_text(sponsors(), encoding="utf-8")
    (out / "v18-3-lancamento.html").write_text(launch(), encoding="utf-8")
    print("ok")
