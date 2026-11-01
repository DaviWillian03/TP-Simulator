"""Mockups das peças novas da tela de corrida no Marco 2 (direção Paddock).

Uso: python design/mockups/build_m2.py   (gera m2-*.html nesta pasta)
"""
import pathlib
import sys

sys.path.insert(0, str(pathlib.Path(__file__).parent))
import build as B  # noqa: E402  (reaproveita dados, emblemas, pista e fontes)

HERE = B.HERE
TYRE = {"S": "#E8261C", "M": "#F5C400", "H": "#F2F2F2", "I": "#2DB34A", "W": "#1F6FE5"}

CSS = """
body{background:#efe9de;color:#141414;font-family:ArchivoN;font-weight:600}
.screen{grid-template-columns:1fr 296px;grid-template-rows:60px 1fr 214px;gap:0;padding:10px 16px}
.mast{grid-column:1/3;display:flex;align-items:flex-end;border-bottom:5px solid #141414;padding-bottom:6px;gap:14px}
.mast h1{font-family:ArchivoBlack;font-size:34px;line-height:.9}.mast .meta{font-size:12px;letter-spacing:2px;text-transform:uppercase}
.mast .lap{margin-left:auto;font-family:ArchivoBlack;font-size:34px;color:#E10600;line-height:.9}
.btn{border:2px solid #141414;padding:5px 9px;font-size:13px;text-transform:uppercase;display:inline-flex;align-items:center;justify-content:center}
.btn.on{background:#141414;color:#efe9de}.btn.red{background:#E10600;border-color:#E10600;color:#fff;font-family:ArchivoBlack}
.speed{display:flex;gap:4px;align-self:center}
.main{grid-column:1;grid-row:2;border-right:2px solid #141414;position:relative;overflow:hidden}
.tower{grid-column:2;grid-row:2/4;padding:6px 0 0 12px;display:flex;flex-direction:column}
.status{font-family:ArchivoBlack;font-size:15px;letter-spacing:1px;text-align:center;padding:5px 0;margin-bottom:4px}
.status.red{background:#E10600;color:#fff}.status.sc{background:#F5C400;color:#141414}.status.ink{background:#141414;color:#efe9de}
.row{height:23px;border-bottom:1px solid #c9c1b2;gap:6px}.row .pos{font-family:ArchivoBlack;font-size:15px;width:24px}
.row .name{font-family:ArchivoBlack;font-size:13px}.row.lead .pos{color:#E10600}
.row.me{background:#141414;color:#efe9de}.row.me .wear{color:#efe9de}.row .gap{font-size:13px;width:50px}
.row .tyre{font-family:ArchivoBlack;text-shadow:0 0 1.5px #141414,0 0 1.5px #141414}.row .wear{font-size:11px;color:#6d665a;width:34px}
.row .wear.hot{color:#E10600}.row.out{color:#a39a8a}.row.out .emb{opacity:.35}
.pen{font-family:ArchivoBlack;font-size:10px;color:#fff;background:#E10600;padding:0 3px;margin-left:4px}
.panels{grid-column:1;grid-row:3;border-top:2px solid #141414;display:grid;grid-template-columns:1fr 1fr;gap:16px;padding:9px 14px 0 0}
.car{display:flex;flex-direction:column;gap:6px}
.car-head{display:flex;align-items:center;gap:7px}.car-head .cname{font-family:ArchivoBlack;font-size:17px;flex:1}.cpos{font-family:ArchivoBlack;font-size:28px;color:#E10600}
.cap{font-size:10px;letter-spacing:2px;text-transform:uppercase}
.line{display:flex;align-items:center;gap:5px}.line .btn{flex:1;height:32px;padding:0 2px;font-size:12px}
.tl{font-family:ArchivoBlack;text-shadow:0 0 1.5px #141414,0 0 1.5px #141414}
.bar{flex:1;height:7px;background:#d8d0c1;position:relative}.bar i{position:absolute;inset:0 auto 0 0;background:#141414}
.dmg{font-family:ArchivoBlack;font-size:11px;color:#E10600}
.cpd{flex:0 0 32px!important}.boxb{flex:0 0 118px!important}
.radar{position:absolute;right:12px;top:12px;width:236px;border:2px solid #141414;background:#efe9de;padding:8px 10px;z-index:3}
.radar h3{font-family:ArchivoBlack;font-size:13px;letter-spacing:1px;display:flex;justify-content:space-between}
.bars{display:flex;align-items:flex-end;gap:6px;height:56px;margin:8px 0 2px}.bars div{flex:1;height:100%;display:flex;flex-direction:column;justify-content:flex-end;align-items:center;gap:2px;font-size:10px}
.bars i{width:100%;background:repeating-linear-gradient(135deg,#1F6FE5 0 3px,#8fb4ee 3px 6px)}
.radar p{font-size:12px;line-height:1.25}.radar b{font-family:ArchivoBlack;color:#E10600}
.wet{display:flex;align-items:center;gap:6px;margin-top:6px}.wet .bar i{background:#1F6FE5}
.radio{position:absolute;left:10px;bottom:12px;width:430px;background:#141414;color:#efe9de;padding:10px 12px;z-index:3}
.radio .who{display:flex;align-items:center;gap:7px;font-size:11px;letter-spacing:2px}.radio .who b{font-family:ArchivoBlack;font-size:14px;letter-spacing:0}
.radio q{display:block;font-family:ArchivoBlack;font-size:17px;line-height:1.2;margin:6px 0 8px;quotes:"“" "”"}
.radio .ans{display:flex;gap:6px}.radio .btn{border-color:#efe9de;color:#efe9de;flex:1;height:34px}.radio .btn.red{border-color:#E10600}
.radio .t{font-size:10px;letter-spacing:1px;margin-top:6px;color:#b9b0a0}
.toast{left:10px;top:12px;font-family:ArchivoBlack;font-size:14px;background:#E10600;color:#fff;padding:5px 11px;transform:rotate(-1.5deg)}
.rain{position:absolute;inset:0;background:repeating-linear-gradient(110deg,transparent 0 22px,rgba(31,111,229,.12) 22px 24px);pointer-events:none}
.drawer{position:absolute;inset:0;background:#efe9de;z-index:4;padding:10px 12px 0 2px}
.drawer h2{font-family:ArchivoBlack;font-size:22px;display:flex;align-items:center;gap:12px;border-bottom:3px solid #141414;padding-bottom:5px}
.drawer h2 .tabs{display:flex;gap:4px;margin-left:12px}.drawer h2 .x{margin-left:auto}
table{width:100%;border-collapse:collapse;font-size:12.5px;margin-top:4px}th{font-size:10px;letter-spacing:1.5px;text-align:left;padding:3px 4px;font-weight:600;color:#6d665a}
td{padding:2.5px 4px;border-bottom:1px solid #c9c1b2;white-space:nowrap}td.n{font-family:ArchivoBlack}tr.me td{background:#141414;color:#efe9de}tr.out td{color:#a39a8a}
"""

ROWS_A = [("NOR", "Líder", "M", 71, ""), ("VER", "+2.1", "M", 74, ""), ("SAI", "+4.0", "I", 6, ""), ("RUS", "+6.8", "H", 40, ""),
          ("ANT", "+8.2", "M", 77, ""), ("ALB", "+9.9", "M", 70, "+5s"), ("LEC", "+12.4", "H", 38, ""), ("HAM", "+13.0", "H", 37, ""),
          ("PIA", "+15.6", "I", 3, ""), ("ALO", "+17.9", "H", 35, ""), ("LIN", "+20.2", "M", 80, ""), ("BOR", "+22.0", "H", 33, ""),
          ("HUL", "+24.4", "H", 33, ""), ("BEA", "+25.1", "H", 30, ""), ("HAD", "+26.7", "H", 30, ""), ("GAS", "+28.0", "H", 29, ""),
          ("OCO", "+29.3", "H", 29, ""), ("STR", "+31.8", "H", 28, ""), ("BOT", "+33.0", "H", 28, ""), ("PER", "+34.6", "H", 27, ""),
          ("LAW", "+1 V", "H", 26, ""), ("COL", "ABANDONO", "H", 0, "out")]


def rows(data, me="williams"):
    out = []
    for i, (code, gap, tyre, wear, flag) in enumerate(data):
        d = B.drivers[code]
        cls = "row" + (" me" if d["team"] == me else "") + (" lead" if i == 0 else "") + (" out" if flag == "out" else "")
        pen = f'<span class="pen">{flag}</span>' if flag.startswith("+") else ""
        pos = "–" if flag == "out" else str(i + 1)
        wear_txt = "" if flag == "out" else f"{wear}%"
        hot = " hot" if wear >= 70 else ""
        out.append(f'<div class="{cls}"><span class="pos">{pos}</span>{B.emblem(d["team"])}<span class="name">{d["name"].split(" ")[-1].upper()}{pen}</span>'
                   f'<span class="gap">{gap}</span><span class="tyre" style="color:{TYRE[tyre]}">{"" if flag == "out" else tyre}</span><span class="wear{hot}">{wear_txt}</span></div>')
    return "\n".join(out)


def car(code, pos, tyre, tyre_txt, wear, bat, dmg="", order_on="Liberado", box_on=False):
    d = B.drivers[code]
    comp = "".join(f'<span class="btn cpd{" on" if c == "I" and box_on else ""}"><span class="tl" style="color:{TYRE[c]}">{c}</span></span>' for c in "SMHIW")
    orders = "".join(f'<span class="btn{" on" if o == order_on else ""}">{o}</span>' for o in ["Deixar passar", "Não brigar", "Liberado"])
    wing = '<span class="btn on" style="flex:0 0 96px">Trocar asa</span>' if dmg else ""
    return f'''<div class="car"><div class="car-head">{B.emblem(d["team"], 22)}<span>#{d["number"]}</span><span class="cname">{d["name"]}</span><span class="cpos">P{pos}</span></div>
<div class="line"><span class="cap">Pneu</span><span class="tl" style="color:{TYRE[tyre]}">{tyre}</span><span style="font-size:13px;width:140px">{tyre_txt}</span><div class="bar"><i style="width:{wear}%"></i></div>
<span class="cap">Bateria</span><div class="bar"><i style="width:{bat}%;background:#E10600"></i></div>{f'<span class="dmg">{dmg}</span>' if dmg else ''}</div>
<div class="line"><span class="btn">Poupar</span><span class="btn on">Normal</span><span class="btn">Atacar</span><span style="width:8px"></span><span class="btn">Carregar</span><span class="btn on">Equilíbrio</span><span class="btn">Bateria</span></div>
<div class="line"><span class="cap" style="width:46px">Equipe</span>{orders}</div>
<div class="line">{comp}{wing}<span class="btn red boxb{" on" if box_on else ""}">{"Box confirmado" if box_on else "Chamar p/ box"}</span></div></div>'''


def mast(lap, meta):
    return (f'<div class="mast"><h1>GP DE SÃO PAULO</h1><span class="meta">{meta}</span><div class="speed"><span class="btn">II</span><span class="btn">1×</span>'
            f'<span class="btn on">2×</span><span class="btn">4×</span><span class="btn">8×</span></div><span class="btn" style="align-self:center;margin-left:14px">Dados</span>'
            f'<span class="lap">{lap}</span></div>')


def screen_a():
    radar = '''<div class="radar"><h3>RADAR <span style="font-family:ArchivoN;font-size:11px;letter-spacing:1px">PRÓXIMAS VOLTAS</span></h3>
<div class="bars"><div><i style="height:30%"></i>+2</div><div><i style="height:45%"></i>+4</div><div><i style="height:62%"></i>+6</div><div><i style="height:70%"></i>+8</div><div><i style="height:55%"></i>+10</div></div>
<p>Garoa agora. Chuva forte <b>provável em 6–9 voltas (60%)</b> — a previsão melhora conforme a nuvem chega.</p>
<div class="wet"><span class="cap">Pista</span><div class="bar"><i style="width:34%"></i></div><span style="font-family:ArchivoBlack;font-size:12px">ÚMIDA 34%</span></div></div>'''
    radio = '''<div class="radio"><div class="who">RÁDIO · '''+B.emblem("williams", 18)+'''<b>ALBON</b> · PERGUNTA</div>
<q>Está começando a garoar e o pneu médio está no fim. Paro para intermediários?</q>
<div class="ans"><span class="btn red">Box: intermediários</span><span class="btn">Fica na pista</span><span class="btn">Mais 2 voltas</span></div>
<div class="t">SEM RESPOSTA EM 2 VOLTAS, O PILOTO DECIDE SOZINHO</div></div>'''
    body = f'''<div class="screen">{mast("21/36", "Interlagos · 36 voltas · garoa")}
<div class="main"><div class="rain"></div><div class="toast">SAINZ COLOCA INTERMEDIÁRIOS!</div>{radar}{radio}
{B.track_svg(asphalt="#141414", edge="#efe9de", width=20, edge_w=20, dot=15, label_color="#141414", label_bg="#efe9de")}</div>
<div class="tower"><div class="status ink">PISTA ÚMIDA · GAROA</div>{rows(ROWS_A)}</div>
<div class="panels">{car("ALB", 6, "M", "Médio · 20 voltas · 70%", 70, 35, dmg="ASA −40%", box_on=False)}{car("SAI", 3, "I", "Intermediário · 1 volta · 6%", 6, 60, order_on="Não brigar")}</div></div>'''
    return B.page("Marco 2 — chuva e rádio", CSS, body)


def screen_b():
    sc_rows = [(c, g, t, w, f) for c, g, t, w, f in ROWS_A]
    tbl = ['<tr><th>POS</th><th>PILOTO</th><th>EQUIPE</th><th>ÚLT. VOLTA</th><th>MELHOR</th><th>INTERVALO</th><th>PNEU</th><th>PARADAS</th><th>PUNIÇÃO</th><th>ESTADO</th></tr>']
    for i, (code, gap, tyre, wear, flag) in enumerate(sc_rows[:20]):
        d = B.drivers[code]
        cls = "me" if d["team"] == "williams" else ""
        tbl.append(f'<tr class="{cls}"><td class="n">{i + 1}</td><td class="n">{d["name"]}</td><td>{B.teams[d["team"]]["name"]}</td><td>1:58.{300 + i * 17}</td>'
                   f'<td>1:13.{150 + i * 23}</td><td>+{0.6 + i * 0.3:.1f}</td><td><span class="tl" style="color:{TYRE[tyre]}">{tyre}</span> · {max(1, wear // 4)} v</td>'
                   f'<td>{1 if tyre != "M" else 0}</td><td>{flag if flag.startswith("+") else "—"}</td><td>Na pista</td></tr>')
    drawer = f'''<div class="drawer"><h2>DADOS DA CORRIDA <span class="tabs"><span class="btn on">Todos</span><span class="btn">Meus pilotos</span><span class="btn">Voltas</span></span>
<span class="btn x">Fechar ✕</span></h2><table>{"".join(tbl)}</table></div>'''
    body = f'''<div class="screen">{mast("24/36", "Interlagos · 36 voltas · chuva")}
<div class="main">{drawer}</div>
<div class="tower"><div class="status sc">SAFETY CAR · VOLTA 2 DE 4</div>{rows(ROWS_A)}</div>
<div class="panels">{car("ALB", 6, "I", "Intermediário · 3 voltas · 10%", 10, 40, box_on=False)}{car("SAI", 3, "I", "Intermediário · 4 voltas · 12%", 12, 62)}</div></div>'''
    return B.page("Marco 2 — safety car e dados", CSS, body)


if __name__ == "__main__":
    (HERE / "m2-a-chuva-radio.html").write_text(screen_a(), encoding="utf-8")
    (HERE / "m2-b-safety-car-dados.html").write_text(screen_b(), encoding="utf-8")
    print("ok")
