"""V20 · Campanha em 3 categorias — fase 1 (2026-11-04): tabelas novas de F1, F2 e F3 (grade de resultados por corrida com
cores, destaque do top 3 com fotos e logos, zonas de acesso e rebaixamento nos construtores).
Uso: python design/mockups/build_v20.py   (V20_FACES=<pasta> V20_LOGOS=<pasta raiz com f2/ f3/ e emblems/> V20_OUT=<pasta>: versão local)
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
FACES = os.environ.get("V20_FACES")
LOGOS = os.environ.get("V20_LOGOS")
FEED = json.loads((ROOT / "game/data/drivers_feeder_2026.json").read_text(encoding="utf-8"))["drivers"]
F2_COL = {"aixracing": "#7b2cbf", "artgrandprix": "#11141a", "camposracing": "#E10600", "damslucasoil": "#1e5bc6", "hitech": "#c0c6cf",
          "invictaracing": "#0b0c0f", "mpmotorsport": "#ff8000", "premaracing": "#d4001a", "rodinmotorsport": "#00a3e0", "trident": "#0a2a6e",
          "vanamersfoortracing": "#ff6a00"}


def face(d, size, col):
    inner = (f'<img src="file://{FACES}/{d["id"]}_face.png" style="width:100%;height:100%;object-fit:cover">' if FACES else "")
    return f'<span class="fc" style="width:{size}px;height:{size}px;background:{col}">{inner}</span>'


def logo(cat, tid, w):
    if cat == "F1":
        src = f"file://{LOGOS}/emblems/{tid}.png" if LOGOS else V.EMB.format(tid)
        return f'<img src="{src}" style="width:{w}px;height:{w}px;object-fit:contain;border-radius:6px">'
    if LOGOS:
        return f'<img src="file://{LOGOS}/series/{cat.lower()}/{tid}.png" style="width:{w}px;height:{w}px;object-fit:contain;border-radius:6px;background:{F2_COL.get(tid, "#333")}">'
    initials = "".join(p[0] for p in tid.replace("racing", " racing").split()[:2]).upper()[:2]
    return f'<span style="width:{w}px;height:{w}px;border-radius:6px;background:{F2_COL.get(tid, "#333")};display:grid;place-items:center;font-size:{w // 2.4:.0f}px;font-weight:900">{initials}</span>'


CSS = V.G_CSS + """
.scene{background:#0b0c0f}
.bg{position:absolute;inset:0;background:radial-gradient(ellipse 60% 70% at 30% 30%,#1b2a55,#0b0c0f 72%)}
.hd{position:absolute;left:44px;top:20px;right:44px;display:flex;align-items:center;gap:14px}
.rb{width:52px;height:52px;border-radius:50%;background:rgba(255,255,255,.08);display:grid;place-items:center}
.hd h1{font-size:28px;font-weight:900;line-height:1}.hd small{display:block;font-size:12px;letter-spacing:3px;color:#8f98a7;font-weight:900}
.seg{display:flex;gap:4px;background:rgba(255,255,255,.06);border-radius:26px;padding:4px}
.seg span{height:44px;padding:0 18px;border-radius:22px;display:flex;align-items:center;gap:8px;font-weight:900;font-size:16px;color:#c3c9d3}
.seg span.on{background:#f3f4f6;color:#11141a}
.cat{position:absolute;left:44px;top:88px}
.sub{position:absolute;left:330px;top:88px}
.pod{position:absolute;left:44px;top:150px;width:300px;display:flex;flex-direction:column;gap:10px}
.p1{border-radius:22px;padding:14px;position:relative;overflow:hidden;height:220px}
.p1 .big{position:absolute;right:-10px;bottom:-34px;font-size:180px;font-weight:900;color:rgba(255,255,255,.12);line-height:1}
.p1 .fc{position:absolute;left:14px;top:46px}
.p1 strong{position:absolute;left:150px;top:62px;font-size:22px;font-weight:900;line-height:1.05}
.p1 small{position:absolute;left:150px;top:118px;font-size:13px;font-weight:800;color:rgba(255,255,255,.85)}
.p1 b{position:absolute;left:14px;top:14px;font-size:12px;letter-spacing:3px;font-weight:900}
.p1 .pts{position:absolute;left:150px;top:146px;font-size:34px;font-weight:900}
.p1 .pts i{font-size:13px;font-style:normal;margin-left:4px}
.p23{display:flex;gap:10px}
.p2{flex:1;border-radius:18px;background:rgba(255,255,255,.07);padding:10px;display:flex;flex-direction:column;align-items:center;gap:4px;text-align:center}
.p2 strong{font-size:14px;font-weight:900}.p2 small{font-size:12px;color:#a8b0bd;font-weight:800}.p2 .n{font-size:12px;letter-spacing:2px;font-weight:900;color:#8f98a7}
.fc{border-radius:50%;overflow:hidden;display:grid;place-items:center;flex:none}
.tbl{position:absolute;left:360px;top:150px;right:44px;bottom:16px;border-radius:22px;background:rgba(255,255,255,.05);padding:10px 14px;overflow:hidden}
.th{display:flex;align-items:center;height:26px;font-size:11px;letter-spacing:2px;font-weight:900;color:#8f98a7}
.tr{display:flex;align-items:center;height:36px;border-top:1px solid rgba(255,255,255,.06);font-size:15px;font-weight:900;gap:8px}
.tr.me{background:rgba(19,71,245,.25);border-radius:10px}
.pos{width:34px;height:26px;border-radius:7px;display:grid;place-items:center;font-size:14px}
.nm{width:178px;white-space:nowrap;overflow:hidden;text-overflow:ellipsis}.nm small{font-size:11px;color:#8f98a7;margin-left:6px}
.grid{display:flex;gap:3px;flex:1}
.grid i{width:21px;height:21px;border-radius:5px;display:grid;place-items:center;font-size:10px;font-style:normal;font-weight:900;color:#11141a}
.g1{background:#ffd24a}.g2{background:#d6d9df}.g3{background:#d08a4a}.gp{background:#3c9d5d;color:#fff!important}.go{background:rgba(255,255,255,.12);color:#c3c9d3!important}
.gd{background:#E10600;color:#fff!important}.gn{background:transparent;border:1px dashed rgba(255,255,255,.15)}
.ptsc{width:52px;text-align:right;font-size:17px}
.zone{display:flex;align-items:center;gap:8px;height:24px;font-size:11px;letter-spacing:2px;font-weight:900;padding:0 8px;border-radius:7px;margin:4px 0}
.up{background:rgba(57,211,107,.16);color:#7fe0b1}.dn{background:rgba(225,6,0,.18);color:#ff8a80}
.tr.zu{box-shadow:inset 4px 0 0 #3c9d5d}.tr.zd{box-shadow:inset 4px 0 0 #E10600}
.legend{display:flex;gap:12px;font-size:11px;font-weight:800;color:#a8b0bd;margin-left:auto}
.legend span{display:flex;align-items:center;gap:5px}.legend i{width:12px;height:12px;border-radius:3px;display:block}
"""


def cell(r):
    if r is None:
        return '<i class="gn"></i>'
    if r == "D":
        return '<i class="gd">✕</i>'
    cls = {1: "g1", 2: "g2", 3: "g3"}.get(r, "gp" if r <= 10 else "go")
    return f'<i class="{cls}">{r}</i>'


def header(cat, sub_on):
    cats = "".join(f'<span class="{"on" if c == cat else ""}">{c}</span>' for c in ["F1", "F2", "F3"])
    subs = "".join(f'<span class="{"on" if s == sub_on else ""}">{s}</span>' for s in ["Pilotos", "Construtores"])
    return f'''<div class="hd"><span class="rb">{ico("back", 24, "#eef0f3", 2.6)}</span><div><small>WILLIAMS · APÓS 12 DE 22 RODADAS</small><h1>CAMPEONATOS</h1></div></div>
<div class="seg cat">{cats}</div><div class="seg sub">{subs}</div>'''


def legend():
    return ('<div class="legend"><span><i class="g1"></i>vitória</span><span><i class="g3"></i>pódio</span><span><i class="gp"></i>pontos</span>'
            '<span><i class="go"></i>sem pontos</span><span><i class="gd"></i>abandono</span></div>')


def drivers_page(cat):
    rng = random.Random(7 if cat == "F1" else 9)
    if cat == "F1":
        pool = [d for d in V.DRIVERS][:22]
        team_name = lambda d: B.teams[d["team"]]["name"]
        col = lambda d: B.teams[d["team"]]["color"]
        rounds = 22
        done = 12
    else:
        pool = [d for d in FEED if d["category"] == cat][:22]
        team_name = lambda d: d.get("series_team", "")
        col = lambda d: F2_COL.get(d.get("series_team_id", ""), "#444")
        rounds = 14 if cat == "F2" else 10
        done = 7 if cat == "F2" else 5
    pool = sorted(pool, key=lambda d: -d["rating"])
    rows = []
    for i, d in enumerate(pool[:14]):
        res = []
        for r in range(rounds):
            if r >= done:
                res.append(None)
            elif rng.random() < 0.07:
                res.append("D")
            else:
                res.append(max(1, min(22, int(rng.gauss(i + 2, 4)))))
        pts = max(0, 260 - i * 19 + rng.randint(-8, 8))
        rows.append((d, res, pts))
    top = rows[:3]
    d1 = top[0][0]
    pod = f'''<div class="pod"><div class="p1" style="background:linear-gradient(140deg,{col(d1)},#0b0c0f)"><b>LÍDER</b><span class="big">1</span>{face(d1, 124, col(d1))}
<strong>{d1["name"].replace(" ", "<br>", 1)}</strong><small>{team_name(d1)}</small><span class="pts">{top[0][2]}<i>pts</i></span></div>
<div class="p23">''' + "".join(f'<div class="p2"><span class="n">{n}º</span>{face(d, 64, col(d))}<strong>{d["name"].split()[-1]}</strong><small>{p} pts</small></div>'
                                  for n, (d, _, p) in zip([2, 3], top[1:3])) + "</div></div>"
    trs = ""
    for i, (d, res, p) in enumerate(rows):
        me = cat == "F1" and d.get("team") == "williams"
        tid = d.get("team") if cat == "F1" else d.get("series_team_id", "")
        trs += (f'<div class="tr{" me" if me else ""}"><span class="pos" style="background:{col(d)}">{i + 1}</span>{logo(cat, tid, 22)}'
                f'<span class="nm">{d["name"].split()[-1].upper()}<small>{team_name(d)[:14]}</small></span><div class="grid">{"".join(cell(x) for x in res)}</div>'
                f'<span class="ptsc">{p}</span></div>')
    tbl = f'<div class="tbl"><div class="th"><span style="width:222px">POS · PILOTO</span>POR CORRIDA {legend()}<span class="ptsc">PTS</span></div>{trs}</div>'
    return V.page(f"V20 · {cat} pilotos", CSS, f'<div class="scene"><div class="bg"></div>{header(cat, "Pilotos")}{pod}{tbl}</div>')


def teams_page(cat):
    rng = random.Random(3)
    if cat == "F2":
        teams = list(F2_COL.keys())
        names = {d["series_team_id"]: d["series_team"] for d in FEED if d["category"] == "F2"}
    else:
        teams = list(B.teams.keys())
        names = {t: B.teams[t]["name"] for t in teams}
    rng.shuffle(teams)
    rows = ""
    n = len(teams)
    for i, t in enumerate(teams):
        pts = max(0, 300 - i * 26 + rng.randint(-6, 6))
        cls = " zu" if i == 0 else (" zd" if i == n - 1 else "")
        if i == n - 1:
            rows += f'<div class="zone dn">{ico("chev", 14, "#ff8a80", 3)} REBAIXAMENTO PARA A {"F3" if cat == "F2" else "F2"}</div>'
        res = "".join(cell(max(1, min(22, int(rng.gauss(i * 2 + 2, 4))))) for _ in range(7 if cat == "F2" else 12))
        col = F2_COL.get(t, "#444") if cat == "F2" else B.teams[t]["color"]
        rows += (f'<div class="tr{cls}"><span class="pos" style="background:{col}">{i + 1}</span>{logo(cat, t, 24)}<span class="nm" style="width:220px">{names[t]}</span>'
                 f'<div class="grid">{res}</div><span class="ptsc">{pts}</span></div>')
        if i == 0:
            rows += f'<div class="zone up">{ico("chev", 14, "#7fe0b1", 3)} ACESSO PARA A {"F1" if cat == "F2" else "—"} · O CAMPEÃO SOBE NO FIM DO ANO</div>'
    lead = teams[0]
    col0 = F2_COL.get(lead, "#444") if cat == "F2" else B.teams[lead]["color"]
    pod = f'''<div class="pod"><div class="p1" style="background:linear-gradient(140deg,{col0},#0b0c0f)"><b>LÍDER</b><span class="big">1</span>
<span style="position:absolute;left:14px;top:50px">{logo(cat, lead, 110)}</span><strong>{names[lead].replace(" ", "<br>", 1)}</strong><small>sobe para a F1 se terminar assim</small><span class="pts">300<i>pts</i></span></div>
<div class="p2" style="text-align:left;align-items:flex-start;padding:12px 14px"><span class="n">COMO FUNCIONA</span><small style="line-height:1.4;color:#c3c9d3">Campeão de construtores da F3 sobe para a F2; o último da F2 desce. Campeão da F2 sobe para a F1; o último da F1 desce. O número de equipes nunca muda.</small></div></div>'''
    tbl = f'<div class="tbl"><div class="th"><span style="width:264px">POS · EQUIPE</span>MELHOR CARRO {legend()}<span class="ptsc">PTS</span></div>{rows}</div>'
    return V.page(f"V20 · {cat} construtores", CSS, f'<div class="scene"><div class="bg"></div>{header(cat, "Construtores")}{pod}{tbl}</div>')


if __name__ == "__main__":
    out = pathlib.Path(os.environ["V20_OUT"]) if os.environ.get("V20_OUT") else HERE
    if os.environ.get("V20_OUT"):
        B.FONTS = B.FONTS.replace("url(fonts/", f"url(file://{(HERE / 'fonts').resolve()}/")
        V.EMB = "file://" + str((ROOT / "game/assets/emblems").resolve()) + "/{}.svg"
    (out / "v20-1-f1-pilotos.html").write_text(drivers_page("F1"), encoding="utf-8")
    (out / "v20-2-f2-construtores.html").write_text(teams_page("F2"), encoding="utf-8")
    (out / "v20-3-f3-pilotos.html").write_text(drivers_page("F3"), encoding="utf-8")
    (out / "v20-4-f1-construtores.html").write_text(teams_page("F1"), encoding="utf-8")
    print("ok")
