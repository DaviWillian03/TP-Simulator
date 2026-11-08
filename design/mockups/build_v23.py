"""V23 · F2 e F3 jogáveis nos três modos (decisões de 2026-11-08).
1) Escolha de equipe com F1 / F2 / F3 (campanha, Grande Prêmio e corrida rápida).
2) Grande Prêmio da F2: só as etapas da categoria, formato da categoria.
3) Sede na F2: nível de operação (engenharia, mecânicos, simulador), pilotos pagantes e pessoal enxuto.
4) Fim de semana da F2: treino simulado, classificação única, sprint invertida e corrida principal.
5) Corrida na F2: cartão sem bateria, com DRS.
Uso: python design/mockups/build_v23.py   (V23_FACES=<pasta> V23_OUT=<pasta>: versão local com rostos)
"""
import json
import os
import pathlib
import sys

sys.path.insert(0, str(pathlib.Path(__file__).parent))
import build as B  # noqa: E402
import build_v3 as V  # noqa: E402

HERE = B.HERE
ROOT = HERE.parent.parent
ico = V.ico
FACES = os.environ.get("V23_FACES")
FEED = json.loads((ROOT / "game/data/feeder_teams_2026.json").read_text(encoding="utf-8"))["series"]
FD = json.loads((ROOT / "game/data/drivers_feeder_2026.json").read_text(encoding="utf-8"))["drivers"]
CAL = V.CAL
TY = json.loads((ROOT / "game/data/tyres_2026.json").read_text(encoding="utf-8"))["compounds"]
TEAM = next(t for t in FEED["F2"]["teams"] if t["name"] == "Campos Racing")
COL = TEAM["color"]
MY = [d for d in FD if d.get("category") == "F2" and d.get("series_team") == "Campos Racing"]

G = {
    "gear": '<circle cx="12" cy="12" r="4"/><path d="M12 2v3M12 19v3M2 12h3M19 12h3M5 5l2 2M17 17l2 2M5 19l2-2M17 7l2-2"/>',
    "wrench": '<path d="M14.5 5.5a4 4 0 0 0 4.9 5.2L21 12l-9 9-3-3 9-9-1.3-1.6a4 4 0 0 0-5.2-4.9l2.5 2.5-2 2-2.5-2.5"/>',
    "sim": '<rect x="3" y="4" width="18" height="12" rx="2"/><path d="M8 20h8M12 16v4"/>',
    "money": '<path d="M12 2v20M17 6.5Q15 4 12 4 7 4 7 8t5 4 5 4-5 4q-3 0-5-2.5"/>',
    "eng": '<path d="M4 14v-2a8 8 0 0 1 16 0v2"/><rect x="2" y="14" width="5" height="6" rx="2"/><rect x="17" y="14" width="5" height="6" rx="2"/>',
    "shield": '<path d="M12 3l8 4v5c0 5-3.5 8-8 9-4.5-1-8-4-8-9V7z"/>',
    "up": '<path d="M12 19V5M6 11l6-6 6 6"/>',
    "drs": '<rect x="3" y="8" width="18" height="8" rx="2"/><path d="M7 12h10"/>',
    "flag": '<path d="M5 21V4h11l-2 4 2 4H5"/>',
    "swap": '<path d="M4 8h13l-3-3M20 16H7l3 3"/>',
}


def g(n, s=18, c="currentColor", w=2.3):
    return (f'<svg width="{s}" height="{s}" viewBox="0 0 24 24" fill="none" stroke="{c}" stroke-width="{w}" stroke-linecap="round" '
            f'stroke-linejoin="round" style="flex:none">{G[n]}</svg>')


def face(name, size, col=COL):
    did = name.lower().replace(" ", "_").replace("ü", "u").replace("â", "a").replace("ó", "o").replace("é", "e").replace("í", "i")
    inner = f'<img src="file://{FACES}/{did}_face.png" style="width:100%;height:100%;object-fit:cover">' if FACES else ""
    return f'<span class="fc" style="width:{size}px;height:{size}px;background:{col}">{inner}</span>'


def tyre(k, size=30):
    t = TY[k]
    return (f'<span class="ty" style="width:{size}px;height:{size}px;border-color:{t["color"]};font-size:{size * 0.45:.0f}px">'
            f'{t["letter"]}</span>')


def short(name):
    return {"MP Motorsport": "MP", "Van Amersfoort Racing": "VAR"}.get(name, name.split()[0][:3].upper())


CSS = V.G_CSS + """
.scene{background:#0b0c0f}
.bg{position:absolute;inset:0;background:radial-gradient(ellipse 60% 70% at 50% 35%,#4a1a1a,#0b0c0f 72%)}
.bg2{position:absolute;inset:0;background:radial-gradient(ellipse 60% 70% at 30% 30%,#3a1414,#0b0c0f 72%)}
.fc{border-radius:50%;overflow:hidden;display:block;flex:none}
.ty{border-radius:50%;border:4px solid;background:#15171c;color:#fff;font-weight:900;display:grid;place-items:center;flex:none}
.cap{font-size:12px;letter-spacing:3px;color:#8f98a7;font-weight:900}
.rb{width:52px;height:52px;border-radius:50%;background:rgba(255,255,255,.08);display:grid;place-items:center}
.cta{height:56px;background:#E10600;color:#fff;font-weight:900;font-size:19px;display:flex;align-items:center;justify-content:center;gap:10px;
 clip-path:polygon(0 0,calc(100% - 18px) 0,100% 18px,100% 100%,0 100%);border-radius:14px 0 14px 14px;padding:0 26px}
.ghost{height:56px;border-radius:14px;background:rgba(255,255,255,.08);font-weight:900;font-size:16px;display:flex;align-items:center;justify-content:center;padding:0 22px;gap:8px}
.glass{position:absolute;border-radius:22px;background:rgba(11,13,18,.8);padding:14px 16px}
.cat{display:flex;border-radius:999px;background:rgba(255,255,255,.08);padding:4px;gap:4px}
.cat span{border-radius:999px;padding:8px 22px;font-size:16px;font-weight:900;color:#c3c9d3}
.cat .on{background:#f3f4f6;color:#11141a}
.tile{width:62px;height:62px;border-radius:14px;display:grid;place-items:center;font-weight:900;font-size:15px;color:#fff}
.tile.on{box-shadow:0 0 0 3px #fff}
.bar{display:flex;align-items:center;gap:10px;font-size:13px;font-weight:800;color:#c3c9d3;margin-top:8px}
.bar .t{flex:1;height:8px;border-radius:4px;background:rgba(255,255,255,.1);overflow:hidden}.bar .t i{display:block;height:100%}
.bar b{width:30px;text-align:right;color:#fff;font-weight:900}
.dr{display:flex;align-items:center;gap:10px;border-radius:16px;background:rgba(255,255,255,.05);padding:8px 10px;margin-top:8px}
.dr strong{display:block;font-size:16px;font-weight:900}.dr small{display:block;font-size:12px;color:#a8b0bd;font-weight:800}
.pill{border-radius:10px;background:rgba(255,255,255,.08);padding:3px 8px;font-size:12px;font-weight:900;display:inline-block;margin-right:4px}
.pay{color:#7fe0b1}
.kv{display:flex;justify-content:space-between;font-size:13px;font-weight:800;color:#c3c9d3;margin-top:7px}.kv b{color:#fff;font-weight:900}
.big{font-size:34px;font-weight:900;line-height:1}
.lvl{border-radius:16px;background:rgba(255,255,255,.05);padding:12px 14px;margin-top:10px;display:flex;align-items:center;gap:12px}
.lvl strong{display:block;font-size:16px;font-weight:900}.lvl small{display:block;font-size:12px;color:#a8b0bd;font-weight:800}
.pips{display:flex;gap:4px;margin-top:6px}.pips i{width:30px;height:8px;border-radius:4px;background:rgba(255,255,255,.12)}.pips i.on{background:#ffd24a}
.btn{height:44px;border-radius:12px;background:#f3f4f6;color:#11141a;font-weight:900;font-size:13px;display:flex;align-items:center;padding:0 14px;gap:6px;margin-left:auto;white-space:nowrap}
.steps{position:absolute;left:44px;right:44px;top:100px;display:flex;align-items:center;gap:10px;font-weight:900;font-size:15px;color:#8f98a7}
.steps i{width:32px;height:32px;border-radius:50%;background:rgba(255,255,255,.08);display:grid;place-items:center;font-style:normal;font-size:13px}
.steps .on i{background:#E10600;color:#fff}.steps .on{color:#fff}.steps .ln{flex:1;height:2px;background:rgba(255,255,255,.1)}
.hero{position:absolute;left:44px;top:150px;width:700px;border-radius:22px;background:#f3f4f6;color:#11141a;padding:18px 24px;box-shadow:inset 7px 0 0 #E10600}
.hero h2{font-size:40px;font-weight:900;line-height:1;margin:6px 0}.hero p{font-size:15px;color:#4b5260;font-weight:700;line-height:1.4}
.rule{display:flex;gap:10px;margin-top:12px}.rule div{flex:1;border-radius:14px;background:#e3e6eb;padding:10px 12px;font-size:12px;font-weight:800;color:#4b5260}
.rule b{display:block;font-size:16px;color:#11141a;font-weight:900}
.seg{display:flex;border-radius:12px;background:rgba(255,255,255,.06);overflow:hidden;flex:1}
.seg span{flex:1;text-align:center;font-size:12px;font-weight:900;padding:9px 0;color:#c3c9d3}.seg .on{background:#f3f4f6;color:#11141a}
.track{position:absolute;inset:0;background:radial-gradient(ellipse 70% 60% at 55% 50%,#24304a,#0b0c0f 75%)}
.rd{width:170px;height:104px;border-radius:16px;background:rgba(255,255,255,.07);padding:10px 12px;flex:none}
.rd.on{background:#f3f4f6;color:#11141a}.rd small{font-size:11px;letter-spacing:2px;font-weight:900;color:#8f98a7}.rd strong{display:block;font-size:17px;font-weight:900;margin-top:4px}
"""


def car_svg(col, w=620):
    # carro de fórmula genérico (ilustração original, perfil lateral)
    return (f'<svg width="{w}" height="{w * 0.24:.0f}" viewBox="0 0 620 150"><g>'
            f'<rect x="30" y="92" width="560" height="10" rx="5" fill="#111"/>'
            f'<path d="M40 96 L120 84 L250 78 L300 58 L360 58 L380 74 L520 82 L585 90 L585 102 L40 104 Z" fill="{col}"/>'
            f'<path d="M300 58 L320 40 L350 40 L360 58 Z" fill="#1b1d22"/>'
            f'<rect x="520" y="48" width="60" height="10" rx="3" fill="#1b1d22"/><rect x="545" y="58" width="8" height="30" fill="#1b1d22"/>'
            f'<rect x="20" y="96" width="70" height="8" rx="3" fill="#1b1d22"/>'
            f'<circle cx="150" cy="104" r="34" fill="#15171c" stroke="#2a2d33" stroke-width="6"/><circle cx="150" cy="104" r="10" fill="#c3c9d3"/>'
            f'<circle cx="480" cy="104" r="36" fill="#15171c" stroke="#2a2d33" stroke-width="6"/><circle cx="480" cy="104" r="10" fill="#c3c9d3"/>'
            f'<text x="390" y="80" font-size="24" font-weight="900" fill="#fff" font-family="Titillium Web, sans-serif">12</text></g></svg>')


def team_select():
    tiles = "".join(f'<span class="tile{" on" if t["name"] == TEAM["name"] else ""}" style="background:{t["color"]};border:2px solid rgba(255,255,255,.18)">{short(t["name"])}</span>'
                    for t in FEED["F2"]["teams"])
    drivers = ""
    for d in MY:
        pay = 2.4 if d["rating"] < 72 else 0.9
        drivers += (f'<div class="dr">{face(d["name"], 50)}<div style="flex:1"><strong>{d["name"]}</strong><small>{d.get("nationality", "")} · nota {d["rating"]}</small>'
                    f'<div style="margin-top:4px"><span class="pill pay">traz US$ {str(pay).replace(".", ",")} mi</span></div></div></div>')
    body = (f'<div class="scene"><div class="bg"></div>'
            f'<div style="position:absolute;left:44px;top:26px"><span class="pill" style="background:#E10600;color:#fff">ESCOLHA DE EQUIPE</span>'
            f'<div style="font-size:44px;font-weight:900;margin-top:8px;line-height:1">{TEAM["name"].upper()}</div>'
            f'<div style="font-size:15px;font-weight:800;color:#c3c9d3;margin-top:6px">GRANDE PRÊMIO</div></div>'
            f'<div style="position:absolute;right:44px;top:30px" class="cat"><span>F1</span><span class="on">F2</span><span>F3</span></div>'
            f'<div style="position:absolute;left:330px;top:300px">{car_svg(COL, 620)}</div>'
            f'<div class="glass" style="left:44px;top:300px;width:256px"><div class="cap">CARRO 2026 · F2</div>'
            f'<div style="display:flex;align-items:baseline;gap:8px;margin-top:8px"><span class="big">74</span><small style="font-size:12px;font-weight:800;color:#a8b0bd">operação da equipe · 3º</small></div>'
            f'<div class="kv">Chassi<b>Dallara F2 (igual para todos)</b></div><div class="kv">Motor<b>Mecachrome V6</b></div>'
            f'<div class="kv">Engenharia<b>nível 3</b></div><div class="kv">Mecânicos<b>nível 2</b></div><div class="kv">Simulador<b>nível 2</b></div>'
            f'<div class="kv">Títulos de equipes<b>3</b></div></div>'
            f'<div class="glass" style="right:44px;top:300px;width:300px"><div class="cap">PILOTOS</div>{drivers}</div>'
            f'<div style="position:absolute;left:44px;bottom:24px;display:flex;gap:8px">{tiles}</div>'
            f'<div style="position:absolute;right:44px;bottom:24px;display:flex;gap:10px"><div class="ghost">{ico("back", 18, "#fff", 2.6)} Voltar</div>'
            f'<div class="cta">CONFIRMAR {ico("chev", 20, "#fff", 3)}</div></div></div>')
    return V.page("V23 · Escolha de equipe F1/F2/F3", CSS, body)


def gp_setup():
    rounds = FEED["F2"]["rounds"]
    sel = rounds[11]
    strip = ""
    for i, r in enumerate(rounds[8:14], 9):
        c = CAL[r]
        on = r == sel
        strip += f'<div class="rd{" on" if on else ""}"><small>F2 · ETAPA {i}</small><strong>{c["grand_prix"].replace("GP de ", "").replace("GP da ", "").replace("GP do ", "").replace("GP dos ", "")}</strong></div>'
    c = CAL[sel]
    circ = V.CIRC.get(c["id"], V.C)
    body = (f'<div class="scene"><div class="bg2"></div><div style="position:absolute;left:44px;top:26px;display:flex;gap:14px;align-items:center">'
            f'<span class="rb">{ico("back", 24, "#eef0f3", 2.6)}</span><div><div class="cap">GRANDE PRÊMIO · FÓRMULA 2 · 2026</div>'
            f'<div style="font-size:30px;font-weight:900">ESCOLHA A ETAPA</div></div></div>'
            f'<div style="position:absolute;left:44px;top:132px"><span class="pill" style="background:#E10600;color:#fff;font-size:15px">F2 · ETAPA 12 DE 14</span>'
            f'<div style="font-size:50px;font-weight:900;margin-top:14px;line-height:1">{c["grand_prix"].upper()}</div>'
            f'<div style="font-size:16px;color:#a8b0bd;font-weight:700;margin-top:10px">Mesmo fim de semana da F1 · formato da F2</div>'
            f'<div style="display:flex;gap:40px;margin-top:30px"><div><div class="big">{round(circ.get("laps", 50) * 0.55)}</div><div class="cap" style="margin-top:6px">VOLTAS · PRINCIPAL</div></div>'
            f'<div><div class="big">{round(circ.get("laps", 50) * 0.4)}</div><div class="cap" style="margin-top:6px">VOLTAS · SPRINT</div></div></div></div>'
            f'<div style="position:absolute;left:480px;top:110px">{V.outline(c["id"], 330, 400, "#eef0f3", 14)}</div>'
            f'<div style="position:absolute;right:44px;top:100px;width:390px"><div class="cap">SUA EQUIPE</div>'
            f'<div class="dr" style="margin-top:8px"><span class="tile" style="width:40px;height:40px;background:{COL};font-size:12px">CR</span><div><strong>Campos Racing</strong><small>{MY[0]["name"]} · {MY[1]["name"]}</small></div></div>'
            f'<div class="cap" style="margin-top:18px">CATEGORIA</div><div class="cat" style="margin-top:8px;width:fit-content"><span>F1</span><span class="on">F2</span><span>F3</span></div>'
            f'<div class="cap" style="margin-top:18px">FORMATO DA F2</div>'
            f'<div class="kv">Treino livre<b>45 min · simulado</b></div><div class="kv">Classificação<b>sessão única · 30 min</b></div>'
            f'<div class="kv">Sprint<b>10 primeiros invertidos · sem parada</b></div><div class="kv">Corrida principal<b>parada obrigatória · 2 compostos</b></div>'
            f'<div class="cta" style="margin-top:22px">COMEÇAR FIM DE SEMANA {ico("chev", 20, "#fff", 3)}</div></div>'
            f'<div style="position:absolute;left:0;right:0;bottom:16px;display:flex;gap:12px;padding-left:44px">{strip}</div></div>')
    return V.page("V23 · Grande Prêmio da F2", CSS, body)


def hub():
    levels = [("gear", "Engenharia", "acerto e ritmo do carro", 3, "US$ 0,6 mi"), ("wrench", "Mecânicos", "paradas e confiabilidade", 2, "US$ 0,4 mi"),
              ("sim", "Simulador", "treino e classificação", 2, "US$ 0,5 mi")]
    lv = ""
    for ic, n, s, k, cost in levels:
        pips = "".join(f'<i class="{"on" if j < k else ""}"></i>' for j in range(4))
        lv += (f'<div class="lvl">{g(ic, 26, "#ffd24a")}<div><strong>{n}</strong><small>{s}</small><div class="pips">{pips}</div></div>'
               f'<span class="btn">{g("up", 16, "#11141a")}NÍVEL {k + 1} · {cost}</span></div>')
    staff = "".join(f'<div class="dr">{g(i, 22, "#5c93ea")}<div style="flex:1"><strong>{n}</strong><small>{r}</small></div><b style="font-size:20px">{s}</b></div>'
                    for i, n, r, s in [("shield", "Marta Ibáñez", "chefe de engenharia", 71), ("eng", "Tom Hale", f"engenheiro · {MY[0]['name'].split()[-1]}", 66),
                                       ("eng", "Luca Ferri", f"engenheiro · {MY[1]['name'].split()[-1]}", 63)])
    body = (f'<div class="scene"><div class="bg2"></div><div style="position:absolute;left:44px;top:26px;display:flex;gap:14px;align-items:center">'
            f'<span class="tile" style="background:{COL};width:52px;height:52px">CR</span><div><div class="cap">SEDE · FÓRMULA 2 · 2026</div>'
            f'<div style="font-size:30px;font-weight:900">CAMPOS RACING</div></div>'
            f'<span class="pill" style="margin-left:24px;font-size:14px;padding:8px 14px">3º nas equipes · 84 pts</span></div>'
            f'<div class="glass" style="left:44px;top:110px;width:560px"><div class="cap">OPERAÇÃO DA EQUIPE · 74</div>'
            f'<div style="font-size:13px;font-weight:700;color:#a8b0bd;margin-top:6px">O chassi é igual para todos: a diferença vem de quem opera o carro.</div>{lv}</div>'
            f'<div class="glass" style="left:624px;top:110px;width:612px"><div class="cap">DINHEIRO</div>'
            f'<div style="display:flex;gap:30px;margin-top:8px"><div><div class="big">US$ 4,8 mi</div><div class="cap" style="margin-top:4px">EM CAIXA</div></div>'
            f'<div><div class="big pay">+ 3,3 mi</div><div class="cap" style="margin-top:4px">PILOTOS PAGANTES / ANO</div></div></div>'
            f'<div class="kv">Patrocínio<b>US$ 1,6 mi / ano</b></div><div class="kv">Custo por etapa<b>US$ 0,35 mi</b></div>'
            f'<div class="kv">Verba de entrada se subir para a F1<b>US$ 45 mi</b></div></div>'
            f'<div class="glass" style="left:624px;top:350px;width:612px"><div class="cap">PESSOAL</div>{staff}</div>'
            f'<div style="position:absolute;left:44px;right:44px;bottom:24px;display:flex;gap:12px;align-items:center">'
            f'<div class="glass" style="position:static;flex:1;display:flex;align-items:center;gap:14px">{g("flag", 22, "#fff")}<div><div class="cap">PRÓXIMA ETAPA · 9 DE 14</div>'
            f'<div style="font-size:18px;font-weight:900">Silverstone · em 5 dias · sprint + principal</div></div></div>'
            f'<div class="cta">IR PARA O FIM DE SEMANA {ico("chev", 20, "#fff", 3)}</div></div></div>')
    return V.page("V23 · Sede na F2", CSS, body)


def weekend():
    steps = ('<div class="steps"><span class="on"><i>1</i> TL</span><span class="ln"></span><span><i>Q</i> CLASS</span><span class="ln"></span>'
             '<span><i>S</i> SPRINT</span><span class="ln"></span><span><i>P</i> PRINCIPAL</span></div>')
    cards = ""
    for i, d in enumerate(MY):
        cards += (f'<div class="glass" style="left:770px;top:{150 + i * 250}px;width:466px"><div style="display:flex;align-items:center;gap:10px">{face(d["name"], 44)}'
                  f'<strong style="font-size:19px;font-weight:900">{d["name"]}</strong></div>'
                  f'<div class="bar"><span style="width:100px">Aerodinâmica</span><div class="t"><i style="width:48%;background:#5c93ea"></i></div><b>48%</b></div>'
                  f'<div class="bar"><span style="width:100px">Mecânico</span><div class="t"><i style="width:44%;background:#5c93ea"></i></div><b>44%</b></div>'
                  f'<div class="dr">{g("eng", 22, "#5c93ea")}<div style="flex:1"><strong style="font-size:14px">{["Tom Hale", "Luca Ferri"][i]}</strong><small>engenheiro de corrida</small></div><b>{[66, 63][i]}</b></div>'
                  f'<div style="display:flex;gap:6px;margin-top:10px;align-items:center;font-size:13px;font-weight:900;color:#c3c9d3">{tyre("hard", 22)}3 de 3{tyre("soft", 22)}2 de 2</div></div>')
    body = (f'<div class="scene"><div class="bg2"></div><div style="position:absolute;left:44px;top:22px;display:flex;gap:14px;align-items:center">'
            f'<span class="rb">{ico("back", 24, "#eef0f3", 2.6)}</span><div><div class="cap">FÓRMULA 2 · CAMPOS RACING</div><div style="font-size:30px;font-weight:900">ETAPA 9 · SILVERSTONE</div></div></div>'
            f'{steps}<div class="hero"><div class="cap" style="color:#4b5260">PRÓXIMA SESSÃO · AGORA</div><h2>TREINO LIVRE</h2>'
            f'<p>45 minutos, simulados. Depois: classificação de sessão única (ao vivo), sprint com os 10 primeiros invertidos e corrida principal.</p>'
            f'<div class="rule"><div><b>5 jogos secos</b>3 duros (principal) + 2 macios (opção)</div><div><b>Sprint</b>sem parada · 10 primeiros invertidos</div>'
            f'<div><b>Principal</b>parada obrigatória · usa os 2 compostos</div></div>'
            f'<div class="cta" style="margin-top:14px;width:360px">SIMULAR TREINO LIVRE {ico("chev", 20, "#fff", 3)}</div></div>{cards}</div>')
    return V.page("V23 · Fim de semana na F2", CSS, body)


def race():
    card = (f'<div class="glass" style="left:12px;top:78px;width:236px"><div style="display:flex;gap:10px;align-items:center">{face(MY[0]["name"], 44)}'
            f'<div><strong style="font-size:17px;font-weight:900">{MY[0]["name"].split()[-1]}</strong><div style="color:#E10600;font-weight:900;font-size:17px">P6 <small style="color:#8f98a7;font-size:12px">#{MY[0].get("number") or 4}</small></div></div></div>'
            f'<div style="display:flex;align-items:center;gap:8px;margin-top:10px;font-size:12px;font-weight:800;color:#c3c9d3">{tyre("hard", 22)}Duro · 14v'
            f'<div style="flex:1;height:6px;border-radius:3px;background:rgba(255,255,255,.12)"><div style="width:62%;height:100%;background:#7fe0b1;border-radius:3px"></div></div>62%</div>'
            f'<div style="display:flex;gap:6px;margin-top:10px">{g("gear", 30, "#c3c9d3")}<div class="seg"><span>Poupar</span><span class="on">Normal</span><span>Atacar</span></div></div>'
            f'<div style="display:flex;gap:8px;margin-top:10px;align-items:center;border-radius:12px;background:rgba(127,224,177,.15);padding:8px 10px">{g("drs", 24, "#7fe0b1")}'
            f'<div><b style="font-size:14px;color:#7fe0b1">DRS ABERTO</b><small style="display:block;font-size:11px;color:#a8b0bd;font-weight:800">a 0,7 s do P5 · reta principal</small></div></div>'
            f'<div style="font-size:12px;font-weight:800;color:#ffb4a8;margin-top:8px">Parada obrigatória: ainda falta usar o macio.</div>'
            f'<div style="display:flex;gap:6px;margin-top:10px"><div class="ghost" style="height:44px;font-size:12px;padding:0 10px">EQUIPE</div>'
            f'<div class="cta" style="height:44px;flex:1;font-size:14px;padding:0">P/ BOX</div></div></div>')
    note = ('<div class="glass" style="left:300px;top:540px;width:520px;font-size:13px;font-weight:800;color:#c3c9d3;line-height:1.45">'
            '<div class="cap">O QUE MUDA NA F2/F3</div>Sem sistema híbrido: sai a bateria (Carregar / Equil. / Usar). O DRS abre sozinho nas zonas '
            'quando o carro está a menos de 1 s do da frente. Na F3 não há parada obrigatória.</div>')
    top = (f'<div style="position:absolute;left:12px;top:14px;right:12px;display:flex;align-items:center;gap:12px">'
           f'<span class="pill" style="background:#E10600;color:#fff;font-size:14px;padding:8px 12px">F2 · PRINCIPAL</span>'
           f'<div style="font-size:20px;font-weight:900">Silverstone</div></div>')
    body = f'<div class="scene"><div class="track"></div>{top}{card}{note}</div>'
    return V.page("V23 · Corrida na F2", CSS, body)


if __name__ == "__main__":
    out = pathlib.Path(os.environ["V23_OUT"]) if os.environ.get("V23_OUT") else HERE
    if os.environ.get("V23_OUT"):
        B.FONTS = B.FONTS.replace("url(fonts/", f"url(file://{(HERE / 'fonts').resolve()}/")
    pages = {"v23-1-equipe-categorias": team_select, "v23-2-gp-f2": gp_setup, "v23-3-sede-f2": hub,
             "v23-4-fim-de-semana-f2": weekend, "v23-5-corrida-f2": race}
    for name, fn in pages.items():
        (out / f"{name}.html").write_text(fn(), encoding="utf-8")
    print("ok")
