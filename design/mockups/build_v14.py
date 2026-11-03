"""V14 · Corrida refeita (pista em tela cheia, estilo Motorsport Manager 3) e classificação ao vivo.
Uso: python design/mockups/build_v14.py   (gera v14-*.html nesta pasta)
Cenário = captura real do 3D com os marcadores novos (disco plano + número). Tempos/pilotos = exemplo coerente.
Mudanças: pista ocupa a tela toda; cartões dos pilotos na vertical à esquerda; torre à direita;
radar saiu da pista e foi para Dados > Clima; rádio vira faixa baixa no centro.
"""
import pathlib
import sys

sys.path.insert(0, str(pathlib.Path(__file__).parent))
import build as B  # noqa: E402
import build_v3 as V  # noqa: E402

HERE = B.HERE
ico = V.ico
TYRE = {"S": "#E8261C", "M": "#F5C400", "H": "#F2F2F2", "I": "#2DB34A", "W": "#1F6FE5"}
import os  # noqa: E402

FACES = os.environ.get("V14_FACES")  # pasta com as fotos locais (NUNCA entram no git); sem ela usa o emblema
ME = "redbull"
MY = [d for d in V.DRIVERS if d["team"] == ME]

CSS = V.G_CSS + """
.scene{background:#0b0c0f}
.world{position:absolute;inset:0;background:#8fbf86 url(png/3d/v14_base.png) 40px 20px/1280px 720px no-repeat}
.glass{background:rgba(11,13,18,.84);border-radius:20px}
.top{position:absolute;left:0;right:0;top:0;height:84px;background:linear-gradient(rgba(8,10,14,.92) 0,rgba(8,10,14,.75) 55%,rgba(8,10,14,0));display:flex;align-items:center;gap:12px;padding:0 12px}
.top h1{font-size:22px;font-weight:900;line-height:1;white-space:nowrap}.top small{display:block;font-size:12px;letter-spacing:2.5px;color:#a8b0bd;margin-top:2px;font-weight:700;white-space:nowrap}
.rb{width:44px;height:44px;border-radius:50%;background:rgba(11,13,18,.84);display:grid;place-items:center;flex:none}
.seg{display:flex;background:rgba(11,13,18,.84);border-radius:24px;padding:3px;gap:3px}.seg span{flex:none;white-space:nowrap;min-width:44px;height:36px;padding:0 10px;border-radius:18px;display:grid;place-items:center;font-size:15px;font-weight:700;color:#c3c9d3}
.seg span.on{background:#f3f4f6;color:#11141a}
.pill{height:44px;padding:0 16px;border-radius:22px;background:rgba(11,13,18,.84);display:flex;align-items:center;gap:8px;font-size:15px;font-weight:700;white-space:nowrap}
.lapc{margin-left:auto;margin-right:314px;text-align:right}.lapc b{font-size:30px;font-weight:900;line-height:1}.lapc b i{font-style:normal;color:#E10600}.lapc small{margin:0}
.cap{font-size:12px;letter-spacing:2.5px;color:#8f98a7;font-weight:700}
/* coluna dos seus pilotos (vertical, à esquerda, compacta) */
.lc{position:absolute;left:12px;width:236px;padding:10px 12px 12px;display:flex;flex-direction:column;gap:7px}
.lc .h{display:flex;align-items:center;gap:10px}.lc .h .nm{display:flex;flex-direction:column;min-width:0;flex:1}.lc .h b{font-size:18px;font-weight:900;line-height:1.05;white-space:nowrap}
.lc .h i{font-style:normal;font-size:12px;color:#a8b0bd;font-weight:700;white-space:nowrap}.lc .h .ps{flex:none;font-size:28px;font-weight:900;color:#E10600;line-height:1}
.lc .t{display:flex;align-items:center;gap:7px;font-size:13px;color:#c3c9d3}.lc .t .tyre{width:22px;height:22px;border-radius:50%;border:4px solid var(--t);background:#0b0c0f;color:#fff;font-size:9px;font-weight:900;display:grid;place-items:center;box-sizing:border-box;flex:none}
.lc .t .bar2{flex:1;height:8px;border-radius:5px;background:rgba(255,255,255,.1);position:relative}.lc .t .bar2 i{position:absolute;inset:0 auto 0 0;border-radius:5px}.lc .t b{color:#fff;font-weight:900}
.lc .seg{background:rgba(255,255,255,.07);height:38px}.lc .seg span{flex:1;min-width:0;height:32px;font-size:13px;padding:0 2px}
.lc .btns{display:flex;gap:6px}.lc .eq{width:66px;height:42px;border-radius:12px;background:rgba(255,255,255,.1);display:flex;flex-direction:column;align-items:center;justify-content:center;font-size:10px;letter-spacing:1px;color:#8f98a7;font-weight:700;line-height:1.15}
.lc .eq b{font-size:12px;color:#fff;letter-spacing:0}
.lc .go{flex:1;height:42px;background:#E10600;color:#fff;font-size:14px;font-weight:900;letter-spacing:.3px;display:flex;align-items:center;justify-content:center;gap:6px;clip-path:polygon(0 0,calc(100% - 12px) 0,100% 12px,100% 100%,0 100%);border-radius:12px 0 12px 12px;white-space:nowrap}
.lc .hint{font-size:12px;color:#ffb4a8;line-height:1.2}.lc .chips,.lc .row{display:flex;align-items:center;gap:6px}.lc .lb{font-size:11px;letter-spacing:2px;color:#8f98a7;font-weight:700}
.lc .chips .c{width:34px;height:34px;border-radius:50%;border:5px solid var(--t);background:#0b0c0f;color:#fff;font-weight:900;font-size:13px;display:grid;place-items:center;box-sizing:border-box}
.lc .chips .c.on{box-shadow:0 0 0 3px #f3f4f6}.lc .bar2{flex:1;height:8px;border-radius:5px;background:rgba(255,255,255,.1);position:relative}.lc .bar2 i{position:absolute;inset:0 auto 0 0;border-radius:5px}
/* torre */
.tower{position:absolute;right:12px;top:70px;width:290px;height:642px;overflow:hidden}
.th{display:flex;height:32px;align-items:center;font-size:11px;letter-spacing:2px;color:#8f98a7;padding:0 12px;border-bottom:1px solid rgba(255,255,255,.08);font-weight:700}
.th .seg{padding:2px;margin-left:auto;gap:2px;height:26px;background:rgba(255,255,255,.07)}.th .seg span{min-width:0;height:22px;padding:0 9px;font-size:11px;letter-spacing:1px}
.tr{display:flex;height:27px;align-items:center;padding:0 8px 0 6px;font-size:14px;border-bottom:1px solid rgba(255,255,255,.06);gap:6px}
.tr .p{width:27px;height:21px;border-radius:6px;display:grid;place-items:center;font-weight:900;font-size:13px;flex:none}
.tr .n{flex:1;font-weight:900;letter-spacing:.3px;white-space:nowrap;overflow:hidden}.tr .g{width:56px;text-align:right;color:#a8b0bd;font-size:13px;font-variant-numeric:tabular-nums}
.tr .ty{width:20px;height:20px;border-radius:50%;border:3px solid var(--t);background:#0b0c0f;color:#fff;font-size:9px;font-weight:900;display:grid;place-items:center;flex:none;box-sizing:border-box}
.tr .age{width:30px;text-align:right;font-size:12px;color:#a8b0bd}.tr.me{background:rgba(54,113,198,.3)}.tr.cut{border-bottom:2px solid #E10600}.tr.out{opacity:.5}
.tlife{display:inline-block;width:34px;height:8px;border-radius:4px;background:rgba(255,255,255,.12);position:relative;flex:none}.tlife i{position:absolute;inset:0 auto 0 0;border-radius:4px}
/* faixas e avisos sobre a pista */
.banner{position:absolute;left:50%;transform:translateX(-50%);white-space:nowrap;border-radius:16px;padding:10px 16px;font-size:15px;font-weight:700;display:flex;align-items:center;gap:10px}
.radio{display:block;bottom:12px;width:600px;background:#f3f4f6;color:#11141a;padding:12px 16px;border-left:7px solid #E10600;border-radius:18px}
.radio .q{font-size:18px;font-weight:900;margin:3px 0 8px}.radio .opts{display:flex;gap:8px}.radio .opts span{flex:1;height:44px;border-radius:12px;background:#e3e6eb;display:grid;place-items:center;font-size:14px;font-weight:700}
.radio .opts span.h{background:#11141a;color:#fff}.radio .cap{color:#4b5260}
/* dados */
.sheet.glass{background:rgba(11,13,18,.94)}.sheet{position:absolute;left:260px;right:314px;top:70px;bottom:12px;padding:14px 18px;overflow:hidden}
.sheet .tabs{display:flex;gap:8px;align-items:center;margin-bottom:10px}.sheet .tabs h2{font-size:22px;font-weight:900;margin-right:8px;white-space:nowrap}
.sheet .seg{background:rgba(255,255,255,.07)}
.kv{display:flex;gap:10px;margin-top:10px}.kv .box{flex:1;border-radius:14px;background:rgba(255,255,255,.06);padding:10px 12px}.kv .box b{display:block;font-size:22px;font-weight:900;margin-top:2px}
.radar .bars{display:flex;gap:8px;align-items:flex-end;height:110px;margin:10px 0 4px}.radar .bars i{flex:1;background:#5c93ea;border-radius:4px 4px 0 0}
.radar .tk{display:flex;gap:8px;font-size:12px;color:#8f98a7}.radar .tk span{flex:1;text-align:center}
.radar p{font-size:15px;color:#c3c9d3;margin-top:10px;line-height:1.35}
.evo{margin-top:10px;font-size:14px;color:#c3c9d3;line-height:1.4}
"""


def lum(col):
    return int(col[1:3], 16) * .299 + int(col[3:5], 16) * .587 + int(col[5:7], 16) * .114


def avatar(d, size=60):
    """Foto do piloto num círculo na cor da equipe (como no jogo); sem a pasta local, emblema da equipe."""
    col = B.teams[d["team"]]["color"]
    if FACES:
        return (f'<span style="width:{size}px;height:{size}px;border-radius:50%;background:{col};flex:none;overflow:hidden;display:block">'
                f'<img src="file://{FACES}/{d["id"]}_face.png" style="width:100%;height:100%;object-fit:cover;display:block"></span>')
    return f'<span style="width:{size}px;height:{size}px;border-radius:50%;background:{col};flex:none;display:grid;place-items:center">{emb(d["team"], size // 2)}</span>'


def emb(tid, w=22):
    return f'<img src="{V.EMB.format(tid)}" width="{w}">'


def life_color(r):
    return "#f3f4f6" if r > 40 else ("#F5C400" if r > 20 else "#ff6b5e")


def seg(items, on):
    return "".join(f'<span class="{"on" if x == on else ""}">{x}</span>' for x in items)


ROWS = [("mclaren", "NORRIS", 0.0, "M", 5), ("williams", "SAINZ", 5.0, "M", 5), ("williams", "ALBON", 9.1, "M", 5),
        ("audi", "HÜLKENBERG", 10.9, "M", 5), ("racingbulls", "LINDBLAD", 11.6, "M", 5), ("redbull", "VERSTAPPEN", 22.5, "H", 1),
        ("mclaren", "PIASTRI", 23.7, "H", 0), ("mercedes", "RUSSELL", 24.4, "H", 0), ("ferrari", "LECLERC", 25.1, "H", 1),
        ("redbull", "HADJAR", 27.2, "H", 1), ("astonmartin", "ALONSO", 28.5, "H", 0), ("haas", "BEARMAN", 30.0, "H", 0),
        ("mercedes", "ANTONELLI", 31.2, "H", 2), ("haas", "OCON", 31.9, "H", 0), ("audi", "BORTOLETO", 32.4, "H", 0),
        ("astonmartin", "STROLL", 32.6, "H", 0), ("alpine", "COLAPINTO", 32.9, "H", 0), ("racingbulls", "LAWSON", 33.1, "H", 0),
        ("cadillac", "PÉREZ", 33.2, "H", 0), ("alpine", "GASLY", 33.4, "H", 0), ("cadillac", "BOTTAS", 33.8, "H", 0), ("ferrari", "HAMILTON", 0, "H", 0)]


def tower_race():
    out = '<div class="th"><span style="width:40px">POS</span><span>PILOTO</span><div class="seg"><span class="on">À FRENTE</span><span>LÍDER</span></div></div>'
    prev = 0.0
    for i, (tid, name, gap, tyr, age) in enumerate(ROWS):
        col = B.teams[tid]["color"]
        fg = "#11141a" if lum(col) > 140 else "#fff"
        if name == "HAMILTON":
            out += f'<div class="tr out"><span class="p" style="background:rgba(255,255,255,.18);color:#c3c9d3">–</span>{emb(tid)}<span class="n">{name}</span><span class="g" style="width:auto;font-size:11px">ABANDONO</span></div>'
            continue
        g = "Líder" if i == 0 else f"+{gap - prev:.1f}"
        prev = gap
        mine = tid == ME
        tail = '<span class="tlife"><i style="width:77%;background:#f3f4f6"></i></span>' if mine else f'<span class="age">{age}v</span>'
        out += (f'<div class="tr{" me" if mine else ""}"><span class="p" style="background:{col};color:{fg}">{i + 1}</span>{emb(tid)}'
                f'<span class="n">{name}</span><span class="g">{g}</span><span class="ty" style="--t:{TYRE[tyr]}">{tyr}</span>{tail}</div>')
    return out


def card_race(top, d, pos, tyr, tname, life, pace, energy, picked, hint, ahead, behind):
    hint_html = f'<div class="hint">{hint}</div>' if hint.strip("&nbsp;") else ""
    return f'''<div class="lc glass" style="top:{top}px"><div class="h">{avatar(d, 62)}<div class="nm"><b>{d["name"].split()[-1]}</b><i>#{d["number"]} · ▲{ahead} ▼{behind}</i></div><span class="ps">P{pos}</span></div>
<div class="t"><span class="tyre" style="--t:{TYRE[tyr]}">{tyr}</span><span>{tname}</span><div class="bar2"><i style="width:{life}%;background:{life_color(life)}"></i></div><b>{life}%</b></div>
<div class="seg">{seg(["Poupar", "Normal", "Atacar"], pace)}</div>
<div class="seg">{seg(["Carregar", "Equil.", "Bateria"], energy)}</div>{hint_html}
<div class="btns"><div class="eq">EQUIPE<b>Liberado</b></div><div class="go">P/ BOX {ico("chev", 15, "#fff", 3)}</div></div></div>'''


def top_bar(title, sub, lap, extra="", label="VOLTA"):
    return f'''<div class="top"><span class="rb">{ico("back", 22)}</span><div><h1>{title}</h1><small>{sub}</small></div>
<div class="seg" style="margin-left:14px"><span>II</span><span>1×</span><span class="on">2×</span><span>4×</span><span>8×</span></div>
{extra}<div class="lapc"><b>{lap}</b><small class="cap" style="display:block">{label}</small></div></div>'''


def corrida():
    verst, hadj = MY[0], MY[1]
    body = f'''<div class="scene"><div class="world"></div>
{top_bar("GP DE SÃO PAULO", "INTERLAGOS", '6<i>/</i>18', f'<div class="pill">{ico("sun", 20, "#ffd24a")} Seca · chuva 68% em 8–10 v</div><div class="pill">Dados</div><span class="rb">{ico("sun", 20)}</span>')}
<div class="banner glass" style="top:76px;background:rgba(14,16,20,.88)"><span style="width:10px;height:10px;border-radius:50%;background:#ffd24a"></span>HAMILTON ABANDONA: BATIDA · SAFETY CAR</div>
{card_race(70, verst, 3, "M", "Médio · 5 voltas", 77, "Normal", "Equil.", "H", "Falta usar outro composto seco.", "+4.1 s", "1.8 s")}
{card_race(354, hadj, 2, "M", "Médio · 5 voltas", 59, "Normal", "Equil.", "H", "&nbsp;", "+5.0 s", "4.1 s")}
<div class="tower glass">{tower_race()}</div>
<div class="banner radio"><div class="cap">RÁDIO · HADJAR</div><div class="q">“Os pneus estão caindo. Paro agora?”</div>
<div class="opts"><span class="h">Parar agora</span><span>Mais 3 voltas</span><span>Decido eu</span></div></div>
</div>'''
    return V.page("V14 · Corrida · pista em tela cheia", CSS, body)


def dados_clima():
    bars = "".join(f'<i style="height:{h}%"></i>' for h in (13, 22, 41, 68, 55))
    body = f'''<div class="scene"><div class="world"></div>
{top_bar("GP DE SÃO PAULO", "INTERLAGOS", '6<i>/</i>18', '<div class="pill" style="background:#f3f4f6;color:#11141a">Dados</div>')}
{card_race(70, MY[0], 3, "M", "Médio · 5 voltas", 77, "Normal", "Equil.", "H", "Falta usar outro composto seco.", "+4.1 s", "1.8 s")}
{card_race(354, MY[1], 2, "M", "Médio · 5 voltas", 59, "Normal", "Equil.", "H", "&nbsp;", "+5.0 s", "4.1 s")}
<div class="tower glass">{tower_race()}</div>
<div class="sheet glass"><div class="tabs"><h2>DADOS</h2><div class="seg">{seg(["Todos", "Meus pilotos", "Voltas", "Clima"], "Clima")}</div><span class="rb" style="margin-left:auto;background:rgba(255,255,255,.1)">{ico("close", 20)}</span></div>
<div class="radar"><div class="cap">RADAR · PRÓXIMAS VOLTAS · CHANCE DE CHUVA</div><div class="bars">{bars}</div>
<div class="tk"><span>+2 v</span><span>+4 v</span><span>+6 v</span><span>+8 v</span><span>+10 v</span></div>
<p>Chuva provável em 8–10 voltas (68%). A previsão melhora conforme a nuvem chega. Quem demorar para trocar o pneu pode perder tempo na pista molhada.</p></div>
<div class="kv"><div class="box"><span class="cap">PISTA</span><b>Seca 0%</b></div><div class="box"><span class="cap">TEMPERATURA</span><b>29 °C · asfalto 41 °C</b></div><div class="box"><span class="cap">BORRACHA</span><b>Média</b></div></div></div>
</div>'''
    return V.page("V14 · Dados · Clima", CSS, body)


QR = [("mercedes", "RUSSELL", "1:15.231", "S"), ("mercedes", "ANTONELLI", "1:15.340", "S"), ("ferrari", "LECLERC", "1:15.402", "S"), ("mclaren", "NORRIS", "1:15.488", "S"),
      ("mclaren", "PIASTRI", "1:15.560", "S"), ("redbull", "VERSTAPPEN", "1:15.611", "S"), ("ferrari", "HAMILTON", "1:15.702", "S"), ("alpine", "GASLY", "1:15.790", "S"),
      ("williams", "ALBON", "1:15.833", "S"), ("racingbulls", "LAWSON", "1:15.901", "S"), ("redbull", "HADJAR", "1:15.945", "S"), ("audi", "HÜLKENBERG", "1:15.980", "S"),
      ("astonmartin", "ALONSO", "1:16.040", "S"), ("haas", "BEARMAN", "1:16.102", "S"), ("williams", "SAINZ", "1:16.150", "S"), ("audi", "BORTOLETO", "1:16.211", "S"),
      ("haas", "OCON", "1:16.288", "S"), ("racingbulls", "LINDBLAD", "1:16.340", "M"), ("astonmartin", "STROLL", "1:16.402", "M"), ("alpine", "COLAPINTO", "1:16.470", "S"),
      ("cadillac", "PÉREZ", "—", ""), ("cadillac", "BOTTAS", "—", "")]


def tower_quali():
    out = '<div class="th"><span style="width:40px">POS</span><span>PILOTO</span><span style="margin-left:auto;width:64px;text-align:right">MELHOR</span><span style="width:60px;text-align:right">DIF.</span></div>'
    for i, (tid, name, t, tyr) in enumerate(QR):
        col = B.teams[tid]["color"]
        fg = "#11141a" if lum(col) > 140 else "#fff"
        mine = tid == ME
        secs = (lambda x: 60 * int(x[0]) + float(x[2:]))
        gap = "—" if i == 0 or t == "—" else "+%.3f" % (secs(t) - secs("1:15.231"))
        ty = f'<span class="ty" style="--t:{TYRE[tyr]}">{tyr}</span>' if tyr else '<span style="width:20px"></span>'
        cut = " cut" if i == 15 else ""
        out += (f'<div class="tr{" me" if mine else ""}{cut}"><span class="p" style="background:{col};color:{fg}">{i + 1}</span>{emb(tid)}'
                f'<span class="n" style="font-size:13px">{name}</span><span class="g" style="width:62px;color:#eef0f3">{t}</span><span class="g" style="width:52px">{gap}</span>{ty}</div>')
    return out


def card_quali(top, d, pos, status, state):
    chips = "".join(f'<span class="c {"on" if k == "S" else ""}" style="--t:{TYRE[k]}">{k}</span>' for k in "SMH")
    if state == "garage":
        mid = f'<div class="hint" style="color:#c3c9d3;font-size:13px">Garagem · 3 jogos de macios novos</div><div class="chips">{chips}</div>'
        btn = f'<div class="btns"><div class="go">SAIR PARA VOLTA RÁPIDA {ico("chev", 15, "#fff", 3)}</div></div>'
    else:
        mid = ('<div class="t"><span class="tyre" style="--t:#E8261C">S</span><span><b>Volta lançada</b> · setor 2/3</span></div>'
               '<div class="t"><div class="bar2"><i style="width:58%;background:#c77dff"></i></div><b>58%</b></div>'
               '<div class="hint" style="color:#c3c9d3;font-size:13px">Última: <b style="color:#fff">1:16.402</b></div>')
        btn = '<div class="btns"><div class="go" style="background:rgba(255,255,255,.1);color:#a8b0bd;clip-path:none;border-radius:12px">EM ANDAMENTO</div></div>'
    return f'''<div class="lc glass" style="top:{top}px"><div class="h">{avatar(d, 62)}<div class="nm"><b>{d["name"].split()[-1]}</b><i>#{d["number"]} · {status}</i></div><span class="ps">P{pos}</span></div>
{mid}{btn}</div>'''


def quali():
    body = f'''<div class="scene"><div class="world"></div>
{top_bar("CLASSIFICAÇÃO · Q1", "INTERLAGOS · 16 AVANÇAM", "12:34", '<div class="pill">SIMULAR RESTO</div>', "TEMPO RESTANTE")}
{card_quali(70, MY[0], 6, "Volta de saída", "garage")}
{card_quali(354, MY[1], 11, "Volta lançada", "fly")}
<div class="tower glass">{tower_quali()}</div>
<div class="banner glass" style="bottom:12px;left:calc(50% - 6px);width:600px;white-space:normal;font-size:14px;color:#c3c9d3">Pista evoluindo: +0,12 s nesta parte. Quem sair no fim ganha até 0,4 s, mas arrisca tráfego e bandeira vermelha.</div>
</div>'''
    return V.page("V14 · Classificação ao vivo", CSS, body)


if __name__ == "__main__":
    out = pathlib.Path(os.environ["V14_OUT"]) if os.environ.get("V14_OUT") else HERE
    if FACES:  # versão com fotos: caminhos absolutos, gravada fora do repositório
        css_abs = str((HERE / "png/3d/v14_base.png").resolve())
        CSS = CSS.replace("url(png/3d/v14_base.png)", f"url(file://{css_abs})")
        B.FONTS = B.FONTS.replace("url(fonts/", f"url(file://{(HERE / 'fonts').resolve()}/")
        V.EMB = "file://" + str((HERE / "../../game/assets/emblems").resolve()) + "/{}.svg"
    (out / "v14-1-corrida.html").write_text(corrida(), encoding="utf-8")
    (out / "v14-2-dados-clima.html").write_text(dados_clima(), encoding="utf-8")
    (out / "v14-3-classificacao.html").write_text(quali(), encoding="utf-8")
    print("ok")
