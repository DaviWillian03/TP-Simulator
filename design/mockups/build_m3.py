"""Mockups do Marco 3 (modo Grande Prêmio), direção Paddock.
Uso: python design/mockups/build_m3.py   (gera m3-*.html nesta pasta)
"""
import json
import pathlib
import sys

sys.path.insert(0, str(pathlib.Path(__file__).parent))
import build as B  # noqa: E402
import scenery as S  # noqa: E402

HERE = B.HERE
CIRC = {p.stem: json.loads(p.read_text(encoding="utf-8")) for p in (B.ROOT / "game/data/circuits").glob("*.json")}
CAL = json.loads((B.ROOT / "game/data/calendar_2026.json").read_text(encoding="utf-8"))["rounds"]
TYRE = {"S": "#E8261C", "M": "#F5C400", "H": "#F2F2F2", "I": "#2DB34A", "W": "#1F6FE5"}

CSS = """
body{background:#efe9de;color:#141414;font-family:ArchivoN;font-weight:600}
.pg{width:1280px;height:720px;padding:12px 16px;display:flex;flex-direction:column}
.mast{display:flex;align-items:flex-end;gap:14px;border-bottom:5px solid #141414;padding-bottom:6px}
.mast h1{font-family:ArchivoBlack;font-size:34px;line-height:.9}.cap{font-size:10px;letter-spacing:2px;text-transform:uppercase}
.mast .r{margin-left:auto;font-family:ArchivoBlack;font-size:30px;color:#E10600;line-height:.9}
.btn{border:2px solid #141414;padding:6px 10px;font-size:13px;text-transform:uppercase;display:inline-flex;align-items:center;justify-content:center;gap:6px}
.btn.on{background:#141414;color:#efe9de}.btn.red{background:#E10600;border-color:#E10600;color:#fff;font-family:ArchivoBlack}
.sheet{border:2px solid #141414}.sh{display:flex;background:#141414;color:#efe9de;font-size:10px;letter-spacing:1.5px;height:24px;align-items:center}
.row{display:flex;align-items:center;height:25px;border-bottom:1px solid #141414;font-size:13px}.row>*,.sh>*{padding:0 6px;border-right:1px solid #c9c1b2;height:100%;display:flex;align-items:center}
.sh>*{border-right-color:#3d3d3d}.row .pos{width:30px;justify-content:center;font-family:ArchivoBlack;padding:0}
.row.me{background:#141414;color:#efe9de}.row.sel{background:#141414;color:#efe9de}.row.out{color:#a39a8a}
.tyre{width:18px;height:18px;border-radius:50%;border:3px solid var(--t);background:#141414;color:#fff;font-family:ArchivoBlack;font-size:9px;display:inline-flex;align-items:center;justify-content:center}
.tag{font-family:ArchivoBlack;font-size:9px;padding:1px 4px;margin-left:6px}.tag.s{background:#E10600;color:#fff}.tag.n{background:#1d2436;color:#ffd36b}
h2{font-family:ArchivoBlack;font-size:20px;margin:10px 0 6px}
.bar{height:8px;background:#d8d0c1;position:relative;flex:1}.bar i{position:absolute;inset:0 auto 0 0;background:#141414}
"""


def pos_cell(team_id, n):
    c = B.teams[team_id]["color"]
    lum = int(c[1:3], 16) * .299 + int(c[3:5], 16) * .587 + int(c[5:7], 16) * .114
    return f'<span class="pos" style="background:{c};color:{"#141414" if lum > 140 else "#fff"}">{n}</span>'


def track_thumb(cid, w=300, h=190):
    c = CIRC[cid]
    pts = S.fit(c["points"], w, h, 16)
    poly = " ".join(f"{x:.1f},{y:.1f}" for x, y in pts)
    return f'<svg width="{w}" height="{h}"><polygon points="{poly}" fill="none" stroke="#141414" stroke-width="6" stroke-linejoin="round"/></svg>'


def screen_config():
    rows = []
    for r in CAL:
        c = CIRC[r["id"]]
        sel = " sel" if r["id"] == "interlagos" else ""
        tags = ('<span class="tag s">SPRINT</span>' if r["sprint"] else "") + ('<span class="tag n">NOITE</span>' if r["night"] else "")
        rows.append(f'<div class="row{sel}"><span style="width:34px;justify-content:center;font-family:ArchivoBlack">{r["round"]}</span>'
                    f'<span style="flex:1;font-family:ArchivoBlack">{r["grand_prix"]}{tags}</span><span style="width:110px">{c["short_name"]}</span>'
                    f'<span style="width:62px;justify-content:flex-end">{r["date"][8:]}/{r["date"][5:7]}</span></div>')
    teams = "".join(f'<span class="btn{" on" if t == "williams" else ""}" style="justify-content:flex-start">{B.emblem(t, 18)}{B.teams[t]["name"]}</span>' for t in B.teams)
    c = CIRC["interlagos"]
    body = f'''<div class="pg"><div class="mast"><h1>GRANDE PRÊMIO</h1><span class="cap">Escolha o fim de semana · temporada 2026</span><span class="r">22 GPs</span></div>
<div style="display:grid;grid-template-columns:470px 1fr;gap:18px;margin-top:10px;flex:1;min-height:0">
<div class="sheet" style="overflow:hidden"><div class="sh"><span style="width:34px">RD</span><span style="flex:1">GRANDE PRÊMIO</span><span style="width:110px">CIRCUITO</span><span style="width:62px">DATA</span></div>{"".join(rows[:21])}</div>
<div style="display:flex;flex-direction:column;gap:8px">
<div style="display:flex;gap:16px;align-items:center"><div class="sheet" style="padding:4px">{track_thumb("interlagos")}</div>
<div><div style="font-family:ArchivoBlack;font-size:26px">GP DE SÃO PAULO</div><div class="cap">Autódromo José Carlos Pace · Interlagos</div>
<div style="font-size:14px;margin-top:8px;line-height:1.6">4,309 km · 71 voltas · sentido anti-horário<br>Ultrapassagem: média · Chuva: 35% de chance<br>Formato: fim de semana normal</div></div></div>
<div class="cap" style="color:#6d665a">Sua equipe</div><div style="display:grid;grid-template-columns:repeat(4,1fr);gap:6px">{teams}</div>
<div style="display:flex;gap:6px;align-items:center"><span class="cap" style="width:70px">Duração</span><span class="btn on">25%</span><span class="btn">50%</span><span class="btn">100%</span>
<span class="cap" style="width:52px;margin-left:14px">Clima</span><span class="btn on">Realista</span><span class="btn">Seco</span><span class="btn">Chuva</span><span class="btn">Variável</span></div>
<div style="display:flex;gap:6px;align-items:center"><span class="cap" style="width:70px">Formato</span><span class="btn on">Fim de semana completo</span><span class="btn">Só a corrida</span>
<span class="btn red" style="margin-left:auto;font-size:20px;padding:10px 26px">COMEÇAR ▶</span></div></div></div></div>'''
    return B.page("M3 — configuração", CSS, body)


def screen_weekend():
    sessions = [("TL1", "Treino livre 1", "Concluído · ALB 3º, SAI 7º", "done"), ("TL2", "Treino livre 2", "Agora", "now"),
                ("TL3", "Treino livre 3", "Sábado 11:30", ""), ("CLASS", "Classificação Q1 · Q2 · Q3", "Sábado 15:00", ""), ("CORRIDA", "Corrida · 18 voltas", "Domingo 14:00", "")]
    cards = []
    for code, name, st, state in sessions:
        bg = "#141414;color:#efe9de" if state == "now" else ("#e3dccd" if state == "done" else "transparent")
        btns = '<span class="btn red">JOGAR</span><span class="btn" style="border-color:#efe9de;color:#efe9de">SIMULAR</span>' if state == "now" else ("<span class='cap'>✓ concluído</span>" if state == "done" else "")
        cards.append(f'<div style="display:flex;align-items:center;gap:14px;border:2px solid #141414;padding:10px 12px;background:{bg}"><span style="font-family:ArchivoBlack;font-size:20px;width:96px">{code}</span>'
                     f'<span style="flex:1"><b style="font-family:ArchivoBlack;font-size:15px">{name}</b><br><span style="font-size:12px">{st}</span></span>{btns}</div>')
    car = lambda code, aero, mech, bal, fb: f'''<div style="border:2px solid #141414;padding:10px"><div style="display:flex;align-items:center;gap:8px">{B.emblem("williams", 20)}<b style="font-family:ArchivoBlack;font-size:16px">{B.drivers[code]["name"]}</b></div>
<div class="cap" style="margin-top:8px">Acerto do carro</div>{"".join(f'<div style="display:flex;align-items:center;gap:8px;font-size:12px;margin-top:4px"><span style="width:90px">{n}</span><div class="bar"><i style="width:{v}%"></i></div><span style="width:34px;text-align:right">{v}%</span></div>' for n, v in [("Aerodinâmica", aero), ("Mecânico", mech), ("Equilíbrio", bal)])}
<div style="font-size:12px;margin-top:8px;font-style:italic">“{fb}”</div>
<div class="cap" style="margin-top:8px">Programa no próximo treino</div><div style="display:flex;gap:4px;margin-top:4px"><span class="btn on" style="font-size:11px;padding:4px 6px">Acerto aero</span><span class="btn" style="font-size:11px;padding:4px 6px">Acerto mecânico</span><span class="btn" style="font-size:11px;padding:4px 6px">Simulação de corrida</span><span class="btn" style="font-size:11px;padding:4px 6px">Volta rápida</span></div></div>'''
    fc = "".join(f'<div style="flex:1;border:2px solid #141414;padding:8px;text-align:center"><div class="cap">{d}</div><div style="font-family:ArchivoBlack;font-size:22px">{p}</div><div style="font-size:11px">chance de chuva</div></div>' for d, p in [("Sexta", "10%"), ("Sábado", "25%"), ("Domingo", "55%")])
    body = f'''<div class="pg"><div class="mast"><h1>GP DE SÃO PAULO</h1><span class="cap">Interlagos · fim de semana · Williams</span><span class="r">SEXTA</span></div>
<div style="display:grid;grid-template-columns:1fr 470px;gap:18px;margin-top:12px;flex:1">
<div style="display:flex;flex-direction:column;gap:8px"><h2 style="margin:0">PROGRAMAÇÃO</h2>{"".join(cards)}<h2>PREVISÃO DO TEMPO</h2><div style="display:flex;gap:8px">{fc}</div></div>
<div style="display:flex;flex-direction:column;gap:8px"><h2 style="margin:0">SEUS CARROS</h2>{car("ALB", 62, 48, 55, "O carro sai de frente nas curvas lentas.")}{car("SAI", 40, 66, 51, "Falta asa na Junção, traseira solta.")}</div></div></div>'''
    return B.page("M3 — fim de semana", CSS, body)


def screen_quali():
    order = ["NOR", "VER", "LEC", "PIA", "RUS", "SAI", "HAM", "ANT", "ALB", "ALO", "HAD", "GAS", "LIN", "BOR", "HUL", "LAW", "OCO", "BEA", "STR", "COL", "PER", "BOT"]
    rows = []
    for i, code in enumerate(order):
        d = B.drivers[code]
        out = " out" if i >= 16 else ""
        me = " me" if d["team"] == "williams" else ""
        t = 71.2 + i * 0.07
        status = ["Volta lançada", "Garagem", "Volta de saída", "Garagem", "Volta lançada"][i % 5] if i < 16 else "Eliminado"
        rows.append(f'<div class="row{me}{out}">{pos_cell(d["team"], i + 1)}<span style="flex:1;gap:6px">{B.emblem(d["team"], 16)}<b style="font-family:ArchivoBlack">{d["name"].split(" ")[-1].upper()}</b></span>'
                    f'<span style="width:84px;justify-content:flex-end">1:{t:06.3f}</span><span style="width:70px;justify-content:flex-end">{"—" if i == 0 else f"+{i * 0.07:.3f}"}</span>'
                    f'<span style="width:34px;justify-content:center"><span class="tyre" style="--t:{TYRE["S"]}">S</span></span><span style="width:110px">{status}</span></div>')
        if i == 9:
            rows.append('<div style="height:4px;background:#E10600"></div>')
    car = lambda code, pos, st, btn: f'''<div style="border:2px solid #141414;padding:10px;display:flex;flex-direction:column;gap:6px"><div style="display:flex;align-items:center;gap:8px">{B.emblem("williams", 20)}<b style="font-family:ArchivoBlack;font-size:16px;flex:1">{B.drivers[code]["name"]}</b><b style="font-family:ArchivoBlack;font-size:26px;color:#E10600">P{pos}</b></div>
<div style="font-size:13px">{st}</div><div style="display:flex;gap:4px;align-items:center">{"".join(f'<span class="btn{" on" if c == "S" else ""}" style="padding:4px"><span class="tyre" style="--t:{TYRE[c]}">{c}</span></span>' for c in "SMHIW")}
<span class="btn red" style="flex:1">{btn}</span></div></div>'''
    body = f'''<div class="pg"><div class="mast"><h1>CLASSIFICAÇÃO</h1><span class="cap">GP de São Paulo · Q2 · 10 avançam para o Q3</span>
<span class="btn" style="align-self:center;margin-left:16px">II</span><span class="btn on" style="align-self:center">2×</span><span class="btn" style="align-self:center">4×</span><span class="btn" style="align-self:center">8×</span><span class="r">Q2 · 08:42</span></div>
<div style="display:grid;grid-template-columns:1fr 400px;gap:16px;margin-top:10px">
<div class="sheet"><div class="sh"><span style="width:30px">POS</span><span style="flex:1">PILOTO</span><span style="width:84px">MELHOR</span><span style="width:70px">DIF.</span><span style="width:34px">PN</span><span style="width:110px">SITUAÇÃO</span></div>{"".join(rows[:17])}</div>
<div style="display:flex;flex-direction:column;gap:10px">{car("SAI", 6, "Garagem · 2 jogos de macios novos", "SAIR PARA VOLTA RÁPIDA")}{car("ALB", 9, "Volta lançada · setor 2: −0,08 s", "VOLTA EM ANDAMENTO")}
<div style="border:2px solid #141414;padding:10px;font-size:13px;line-height:1.5"><b style="font-family:ArchivoBlack">PISTA EVOLUINDO</b><br>Quem sair no fim ganha até 0,3 s de borracha — mas arrisca tráfego, bandeira vermelha ou chuva.<br><span style="color:#E10600;font-family:ArchivoBlack">Linha vermelha: zona de eliminação (11º–16º)</span></div></div></div></div>'''
    return B.page("M3 — classificação", CSS, body)


def screen_scenery():
    panels = [("interlagos", "dry", None, "Interlagos · dia · seco (lago + skyline)"), ("interlagos", "rain", None, "Interlagos · chuva"),
              ("monaco", "dry", None, "Mônaco · porto com iates"), ("lasvegas", "dry", True, "Las Vegas · noite (Strip + esfera)")]
    cells = "".join(f'<div><div class="cap" style="margin-bottom:4px">{t}</div><div class="sheet">{S.scenery_svg(CIRC[cid], 610, 300, w, n)}</div></div>' for cid, w, n, t in panels)
    body = f'''<div class="pg"><div class="mast"><h1>CENÁRIOS</h1><span class="cap">Fundo da pista desenhado por código, no estilo de ilustração de revista · muda com clima e noite</span></div>
<div style="display:grid;grid-template-columns:1fr 1fr;gap:10px 16px;margin-top:8px">{cells}</div></div>'''
    return B.page("M3 — cenários", CSS, body)


if __name__ == "__main__":
    for name, fn in [("m3-a-configuracao", screen_config), ("m3-b-fim-de-semana", screen_weekend), ("m3-c-classificacao", screen_quali), ("m3-d-cenarios", screen_scenery)]:
        (HERE / f"{name}.html").write_text(fn(), encoding="utf-8")
    print("ok")
