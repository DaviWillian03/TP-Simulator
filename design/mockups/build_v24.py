"""V24 · Histórico da campanha e animação de campeão (decisões de 2026-11-08).
1) Histórico · Lendas (os 15 maiores campeões aposentados; aposentados da campanha entram depois).
2) Histórico · Pilotos atuais (grid da F1: números até o fim de 2025 + o que a campanha somar).
3) Histórico · Campeonatos (campeões de pilotos e construtores de cada temporada da campanha).
4) Animação de campeão · pista (bandeirada: câmera no carro, pista na cor da equipe, fogos/confete).
5) Animação de campeão · pôster (foto grande, "CAMPEÃO MUNDIAL", número e os números da temporada).
Uso: python design/mockups/build_v24.py   (V24_FACES=<pasta> V24_OUT=<pasta>: versão local com rostos)
"""
import json
import os
import pathlib
import random
import sys

sys.path.insert(0, str(pathlib.Path(__file__).parent))
import build as B  # noqa: E402
import build_v3 as V  # noqa: E402

HERE = B.HERE
ROOT = HERE.parent.parent
ico = V.ico
FACES = os.environ.get("V24_FACES")
LEG = json.loads((ROOT / "game/data/legends.json").read_text(encoding="utf-8"))["legends"]
DRV = json.loads((ROOT / "game/data/drivers_2026.json").read_text(encoding="utf-8"))["drivers"]
TEAMS = B.teams


def face(did, size, col):
    inner = f'<img src="file://{FACES}/{did}_face.png" style="width:100%;height:100%;object-fit:cover">' if FACES else ""
    return f'<span class="fc" style="width:{size}px;height:{size}px;background:{col}">{inner}</span>'


CROWN = '<svg width="{s}" height="{s}" viewBox="0 0 24 24" fill="{c}"><path d="M3 18h18l-1.5-10-4.5 4-3-6-3 6-4.5-4z"/></svg>'


def crown(s=16, c="#ffd24a"):
    return CROWN.format(s=s, c=c)


CSS = V.G_CSS + """
.scene{background:#0b0c0f}
.bg{position:absolute;inset:0;background:radial-gradient(ellipse 60% 70% at 30% 20%,#2a2f3d,#0b0c0f 72%)}
.fc{border-radius:50%;overflow:hidden;display:block;flex:none}
.cap{font-size:12px;letter-spacing:3px;color:#8f98a7;font-weight:900}
.rb{width:52px;height:52px;border-radius:50%;background:rgba(255,255,255,.08);display:grid;place-items:center}
.hd{position:absolute;left:44px;top:22px;right:44px;display:flex;align-items:center;gap:14px}
.hd h1{font-size:30px;font-weight:900;line-height:1}
.tabs{display:flex;border-radius:999px;background:rgba(255,255,255,.08);padding:4px;gap:4px;margin-left:auto}
.tabs span{border-radius:999px;padding:8px 18px;font-size:15px;font-weight:900;color:#c3c9d3}.tabs .on{background:#f3f4f6;color:#11141a}
.nav{position:absolute;left:44px;top:88px;display:flex;gap:4px;border-radius:26px;background:rgba(255,255,255,.06);padding:4px}
.nav span{padding:10px 18px;border-radius:22px;font-size:15px;font-weight:800}.nav .on{background:#f3f4f6;color:#11141a}
.lg{position:absolute;width:286px;height:170px;border-radius:20px;background:rgba(255,255,255,.06);padding:14px;overflow:hidden}
.lg strong{display:block;font-size:17px;font-weight:900;line-height:1.05}.lg small{display:block;font-size:12px;color:#a8b0bd;font-weight:800}
.lg .t{display:flex;gap:2px;margin-top:8px}
.nums{display:flex;gap:12px;margin-top:10px}.nums div{font-size:20px;font-weight:900}.nums small{font-size:10px;letter-spacing:2px;color:#8f98a7}
.rank{position:absolute;right:12px;top:6px;font-size:48px;font-weight:900;color:rgba(255,255,255,.08)}
.tbl{position:absolute;left:44px;right:44px;top:150px;border-radius:20px;background:rgba(255,255,255,.05);padding:6px 14px}
.tr{display:flex;align-items:center;gap:12px;height:46px;border-top:1px solid rgba(255,255,255,.06);font-weight:900;font-size:15px}
.tr:first-child{border-top:0;height:34px;font-size:11px;letter-spacing:2px;color:#8f98a7}
.tr .n{width:96px;text-align:right}.tr .n small{display:block;font-size:11px;color:#7fe0b1;font-weight:900;letter-spacing:0}
.sea{position:absolute;width:560px;border-radius:22px;background:rgba(255,255,255,.06);padding:16px 18px}
.sea h3{font-size:34px;font-weight:900;line-height:1}
.ch{display:flex;align-items:center;gap:12px;border-radius:16px;background:rgba(0,0,0,.25);padding:10px 12px;margin-top:10px}
.ch strong{font-size:18px;font-weight:900;display:block}.ch small{font-size:12px;color:#a8b0bd;font-weight:800;display:block}
.pill{border-radius:10px;background:rgba(255,255,255,.08);padding:3px 8px;font-size:12px;font-weight:900;display:inline-block}
.track{position:absolute;inset:0;background:radial-gradient(ellipse 70% 60% at 55% 55%,#3a2410,#0b0c0f 75%)}
.conf{position:absolute;width:10px;height:16px;border-radius:2px}
.banner{position:absolute;left:0;right:0;top:250px;height:200px;background:linear-gradient(90deg,transparent,rgba(255,128,0,.92) 12%,rgba(255,128,0,.92) 88%,transparent);display:flex;align-items:center;justify-content:center;flex-direction:column}
.banner b{font-size:84px;font-weight:900;letter-spacing:4px;line-height:1;color:#fff;text-shadow:0 6px 30px rgba(0,0,0,.4)}
.banner span{font-size:22px;font-weight:900;letter-spacing:8px;color:#fff}
.poster{position:absolute;inset:0;background:linear-gradient(115deg,#ff8000 0 42%,#0b0c0f 42%)}
.pface{position:absolute;left:40px;top:40px;width:520px;height:640px;border-radius:30px;overflow:hidden;background:#ff9a33}
.big1{position:absolute;left:560px;top:-90px;font-size:760px;font-weight:900;color:rgba(255,255,255,.05);line-height:1}
.pinfo{position:absolute;left:640px;top:70px;right:50px}
.pinfo h2{font-size:64px;font-weight:900;line-height:.95}.pinfo h3{font-size:24px;font-weight:900;letter-spacing:8px;color:#fff;text-shadow:0 2px 0 #ff8000}
.pst{display:grid;grid-template-columns:repeat(4,1fr);gap:10px;margin-top:26px}
.pst>div{border-radius:16px;background:rgba(255,255,255,.07);padding:12px}.pst b{display:block;font-size:34px;font-weight:900}.pst small{font-size:11px;letter-spacing:2px;color:#a8b0bd;font-weight:900}
.cta{height:56px;background:#E10600;color:#fff;font-weight:900;font-size:19px;display:flex;align-items:center;justify-content:center;gap:10px;
 clip-path:polygon(0 0,calc(100% - 18px) 0,100% 18px,100% 100%,0 100%);border-radius:14px 0 14px 14px;padding:0 26px}
"""


def header(active):
    nav = "".join(f'<span class="{"on" if n == "Histórico" else ""}">{n}</span>' for n in ["Início", "Campeonatos", "Histórico", "Pessoal", "Carro"])
    tabs = "".join(f'<span class="{"on" if t == active else ""}">{t}</span>' for t in ["Lendas", "Pilotos atuais", "Campeonatos"])
    return (f'<div class="hd"><span class="rb">{ico("back", 24, "#eef0f3", 2.6)}</span><div><div class="cap">MCLAREN · TEMPORADA 2028</div><h1>HISTÓRICO</h1></div>'
            f'<div class="tabs">{tabs}</div></div><div class="nav">{nav}</div>')


def legends():
    cards = ""
    lst = LEG[:12]
    for i, l in enumerate(lst):
        x = 44 + (i % 4) * 302
        y = 150 + (i // 4) * 184
        crowns = "".join(crown(16) for _ in range(l["titles"]))
        cards += (f'<div class="lg" style="left:{x}px;top:{y}px"><span class="rank">{i + 1}</span><div style="display:flex;gap:10px;align-items:center">'
                  f'{face(l["id"], 52, "#3a3f4b")}<div><strong>{l["name"]}</strong><small>{l["nationality"]} · {l["years"]}</small></div></div>'
                  f'<div class="t">{crowns}</div>'
                  f'<div class="nums"><div>{l["wins"]}<br><small>VIT</small></div><div>{l["poles"]}<br><small>POLES</small></div>'
                  f'<div>{l["podiums"]}<br><small>PÓD</small></div><div>{l["starts"]}<br><small>GPS</small></div></div></div>')
    body = f'<div class="scene"><div class="bg"></div>{header("Lendas")}{cards}</div>'
    return V.page("V24 · Histórico · Lendas", CSS, body)


def current():
    rows = '<div class="tr"><span style="width:30px">#</span><span style="flex:1">PILOTO</span><span class="n">LARGADAS</span><span class="n">VITÓRIAS</span><span class="n">PÓDIOS</span><span class="n">POLES</span><span class="n">TÍTULOS</span></div>'
    add = {"norris": (44, 9, 21, 7, 1), "verstappen": (44, 12, 25, 10, 1), "leclerc": (44, 3, 14, 4, 0), "hamilton": (44, 1, 6, 2, 0),
           "russell": (44, 6, 18, 5, 0), "antonelli": (44, 8, 20, 9, 1), "piastri": (44, 4, 15, 3, 0), "alonso": (44, 0, 2, 0, 0)}
    srt = sorted(DRV, key=lambda d: -(d["career_2025"]["wins"] + add.get(d["id"], (0, 0))[1]))[:10]
    for d in srt:
        c = d["career_2025"]
        a = add.get(d["id"], (44, 0, 0, 0, 0))
        col = TEAMS[d["team"]]["color"]
        cells = "".join(f'<span class="n">{c[k] + a[i]}<small>+{a[i]} campanha</small></span>' if a[i] else f'<span class="n">{c[k]}</span>'
                        for i, k in enumerate(["starts", "wins", "podiums", "poles", "titles"]))
        rows += (f'<div class="tr"><span style="width:30px;color:#8f98a7">{d["number"]}</span><span style="flex:1;display:flex;gap:10px;align-items:center">'
                 f'{face(d["id"], 34, col)}{d["name"]}<span class="pill" style="background:{col}33">{TEAMS[d["team"]]["name"]}</span></span>{cells}</div>')
    body = (f'<div class="scene"><div class="bg"></div>{header("Pilotos atuais")}<div class="tbl">{rows}</div>'
            f'<div style="position:absolute;left:44px;bottom:16px;font-size:12px;font-weight:800;color:#8f98a7">Números até o fim de 2025 (fontes no jogo) + o que a campanha somou (em verde).</div></div>')
    return V.page("V24 · Histórico · Pilotos atuais", CSS, body)


def seasons():
    data = [(2026, "antonelli", "Kimi Antonelli", "mercedes", 412, "Mercedes", 703, 4), (2027, "verstappen", "Max Verstappen", "redbull", 389, "McLaren", 655, 2)]
    cards = ""
    for i, (yr, did, dn, tid, pts, team, tpts, mine) in enumerate(data):
        col = TEAMS[tid]["color"]
        tcol = TEAMS["mclaren" if team == "McLaren" else "mercedes"]["color"]
        cards += (f'<div class="sea" style="left:{44 + i * 600}px;top:150px"><div style="display:flex;align-items:baseline;gap:12px"><h3>{yr}</h3>'
                  f'<span class="pill">sua equipe: {mine}º</span></div>'
                  f'<div class="ch">{face(did, 64, col)}<div style="flex:1"><div class="cap">CAMPEÃO DE PILOTOS</div><strong>{dn}</strong><small>{pts} pontos · {TEAMS[tid]["name"]}</small></div>{crown(30)}</div>'
                  f'<div class="ch"><span style="width:64px;height:64px;border-radius:16px;background:{tcol};display:block"></span><div style="flex:1"><div class="cap">CAMPEÃ DE CONSTRUTORES</div>'
                  f'<strong>{team}</strong><small>{tpts} pontos</small></div>{crown(30)}</div>'
                  f'<div style="display:flex;gap:8px;margin-top:10px;font-size:13px;font-weight:800;color:#c3c9d3">Vice: {"Max Verstappen" if i == 0 else "Lando Norris"} · 3º: {"George Russell" if i == 0 else "Kimi Antonelli"}</div></div>')
    body = f'<div class="scene"><div class="bg"></div>{header("Campeonatos")}{cards}</div>'
    return V.page("V24 · Histórico · Campeonatos", CSS, body)


def track():
    random.seed(4)
    conf = "".join(f'<i class="conf" style="left:{random.randint(0, 1270)}px;top:{random.randint(0, 700)}px;background:{random.choice(["#ff8000", "#fff", "#ffd24a", "#1b1d22"])};transform:rotate({random.randint(0, 180)}deg)"></i>' for _ in range(90))
    body = (f'<div class="scene"><div class="track"></div>'
            f'<svg style="position:absolute;inset:0" width="1280" height="720"><path d="M-40 560 C 300 420, 700 640, 1320 380" stroke="#ff8000" stroke-width="70" fill="none" opacity=".55"/>'
            f'<path d="M-40 560 C 300 420, 700 640, 1320 380" stroke="#2b2b2b" stroke-width="54" fill="none"/>'
            f'<circle cx="640" cy="520" r="34" fill="#ff8000" stroke="#fff" stroke-width="6"/><text x="640" y="532" text-anchor="middle" font-size="30" font-weight="900" fill="#fff" font-family="Titillium Web, sans-serif">4</text></svg>'
            f'{conf}<div class="banner"><span>LAS VEGAS · VOLTA 50 DE 50</span><b>NORRIS É BICAMPEÃO!</b><span>CAMPEÃO MUNDIAL DE PILOTOS 2027</span></div>'
            f'<div style="position:absolute;left:24px;bottom:24px;font-size:13px;font-weight:800;color:#c3c9d3;max-width:520px;line-height:1.45">'
            f'<div class="cap">STORYBOARD · 1 DE 2</div>Na bandeirada da corrida que decide o título: câmera fecha no carro do campeão, a pista e a luz ganham a cor da equipe, '
            f'fogos e confete, e a faixa com o nome entra. Toque para pular.</div></div>')
    return V.page("V24 · Campeão · pista", CSS, body)


def poster():
    stats = "".join(f'<div><b>{v}</b><small>{k}</small></div>' for k, v in [("VITÓRIAS", 9), ("POLES", 7), ("PÓDIOS", 18), ("PONTOS", 431)])
    body = (f'<div class="scene"><div class="poster"></div><div class="big1">1</div><div class="pface">{face("norris", 640, "#ff9a33").replace("border-radius:50%", "border-radius:0").replace("width:640px;height:640px", "width:520px;height:640px;display:block")}</div>'
            f'<div class="pinfo"><h3>CAMPEÃO MUNDIAL 2027</h3><h2>LANDO<br>NORRIS</h2>'
            f'<div style="display:flex;gap:10px;margin-top:14px;align-items:center">{crown(30)}{crown(30)}<span style="font-size:18px;font-weight:900;color:#c3c9d3">2º título · McLaren</span></div>'
            f'<div class="pst">{stats}</div>'
            f'<div style="margin-top:22px;font-size:15px;font-weight:800;color:#c3c9d3;line-height:1.5">Garantido com uma etapa de antecedência. No ano que vem, o carro de Norris leva o número 1.</div>'
            f'<div style="display:flex;gap:12px;margin-top:26px"><div class="cta">CONTINUAR {ico("chev", 20, "#fff", 3)}</div></div></div>'
            f'<div style="position:absolute;right:24px;bottom:16px" class="cap">STORYBOARD · 2 DE 2 · TAMBÉM PARA CONSTRUTORES (CARRO NO LUGAR DA FOTO)</div></div>')
    return V.page("V24 · Campeão · pôster", CSS, body)


if __name__ == "__main__":
    out = pathlib.Path(os.environ["V24_OUT"]) if os.environ.get("V24_OUT") else HERE
    if os.environ.get("V24_OUT"):
        B.FONTS = B.FONTS.replace("url(fonts/", f"url(file://{(HERE / 'fonts').resolve()}/")
    pages = {"v24-1-historico-lendas": legends, "v24-2-historico-atuais": current, "v24-3-historico-campeonatos": seasons,
             "v24-4-campeao-pista": track, "v24-5-campeao-poster": poster}
    for name, fn in pages.items():
        (out / f"{name}.html").write_text(fn(), encoding="utf-8")
    print("ok")
