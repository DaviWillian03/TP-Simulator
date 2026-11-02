"""Tela de corrida na direção Garagem (mockup antes do Godot).
Uso: python design/mockups/build_v7.py   (gera v7-*.html nesta pasta)
Cenário = captura real do 3D atual (png/3d/clean_*.png). Pilotos, tempos e rádio = exemplo coerente com o jogo.
Logos das equipes: emblemas originais do jogo (no jogo, as logos pessoais do usuário entram no lugar).
"""
import pathlib
import sys

sys.path.insert(0, str(pathlib.Path(__file__).parent))
import build as B  # noqa: E402
import build_v3 as V  # noqa: E402

HERE = B.HERE
ico = V.ico
TYRE = {"S": "#E8261C", "M": "#F5C400", "H": "#F2F2F2", "I": "#2DB34A", "W": "#1F6FE5"}

CSS = V.G_CSS + """
.scene{background:#0b0c0f}
.bar{position:absolute;left:16px;right:16px;top:10px;height:56px;display:flex;align-items:center;gap:14px}
.bar h1{font-size:26px;font-weight:900;line-height:1}.bar small{display:block;font-size:12px;letter-spacing:2.5px;color:#8f98a7;margin-top:3px;font-weight:700}
.lap{margin-left:auto;text-align:right}.lap b{font-size:34px;font-weight:900;line-height:1}.lap b i{font-style:normal;color:#E10600}.lap small{margin:0}
.seg{display:flex;background:rgba(255,255,255,.07);border-radius:24px;padding:3px;gap:3px}.seg span{flex:none;white-space:nowrap;min-width:46px;height:38px;padding:0 10px;border-radius:19px;display:grid;place-items:center;font-size:15px;font-weight:700;color:#c3c9d3}
.seg span.on{background:#f3f4f6;color:#11141a}
.pill{height:44px;padding:0 18px;border-radius:22px;background:rgba(255,255,255,.08);display:flex;align-items:center;gap:8px;font-size:15px;font-weight:700}
.rb{width:44px;height:44px;border-radius:50%;background:rgba(255,255,255,.1);display:grid;place-items:center}
.view{position:absolute;left:16px;top:76px;width:872px;height:378px;border-radius:22px;overflow:hidden;background:#000 var(--img) center/cover}
.card{position:absolute;border-radius:16px;background:rgba(14,16,20,.88);padding:12px 14px}
.cap{font-size:12px;letter-spacing:2.5px;color:#8f98a7;font-weight:700}
.radar{right:14px;top:14px;width:250px}.radar .bars{display:flex;gap:6px;align-items:flex-end;height:44px;margin:8px 0 4px}.radar .bars i{flex:1;background:#5c93ea;border-radius:3px 3px 0 0}
.radar p{font-size:13px;color:#c3c9d3}.radar .tk{display:flex;justify-content:space-between;font-size:11px;color:#8f98a7}
.stamp{left:14px;top:14px;white-space:nowrap;background:#E10600;color:#fff;border-radius:12px;padding:8px 14px;font-size:15px;font-weight:900;letter-spacing:.5px;display:flex;align-items:center;gap:8px}
.stamp.n{background:rgba(14,16,20,.88);font-weight:700;margin-top:0}
.radio{left:14px;bottom:14px;width:470px;background:#f3f4f6;color:#11141a;padding:14px 16px 14px;border-left:7px solid #E10600}
.radio .cap{color:#4b5260}.radio .q{font-size:19px;font-weight:900;margin:4px 0 10px}.radio .opts{display:flex;gap:8px}
.radio .opts span{flex:1;height:44px;border-radius:12px;background:#e3e6eb;display:grid;place-items:center;font-size:14px;font-weight:700;text-align:center;line-height:1.1}
.radio .opts span.h{background:#11141a;color:#fff}.radio .t{font-size:12px;color:#4b5260;margin-top:8px;display:flex;justify-content:space-between}
.camc{right:14px;bottom:14px;display:flex;gap:8px;padding:8px}.camc span{height:38px;padding:0 14px;border-radius:19px;background:rgba(255,255,255,.1);display:grid;place-items:center;font-size:14px;font-weight:700}
.camc span.on{background:#f3f4f6;color:#11141a}
.tower{position:absolute;right:16px;top:76px;width:352px;height:630px;border-radius:22px;background:rgba(255,255,255,.05);overflow:hidden}
.th{display:flex;height:30px;align-items:center;font-size:11px;letter-spacing:2px;color:#8f98a7;padding:0 12px;border-bottom:1px solid rgba(255,255,255,.08);font-weight:700}
.tr{display:flex;height:27px;align-items:center;padding:0 10px 0 8px;font-size:14px;border-bottom:1px solid rgba(255,255,255,.06);gap:7px}
.tr .p{width:27px;height:21px;border-radius:6px;display:grid;place-items:center;font-weight:900;font-size:13px;flex:none}
.tr .n{flex:1;font-weight:900;letter-spacing:.3px;white-space:nowrap;overflow:hidden}.tr .g{width:54px;text-align:right;color:#a8b0bd;font-size:13px;font-variant-numeric:tabular-nums}
.tr .ty{width:20px;height:20px;border-radius:50%;border:3px solid var(--t);background:#0b0c0f;color:#fff;font-size:9px;font-weight:900;display:grid;place-items:center;flex:none;box-sizing:border-box}
.tr .w{width:34px;text-align:right;font-size:12px;color:#a8b0bd}.tr .w.hot{color:#ffb4a8;font-weight:900}
.tr img{flex:none}.tr.me{background:rgba(24,104,219,.25)}.tr.me .n{color:#fff}.tr.out{opacity:.45}
.tr .tag{font-size:10px;font-weight:900;background:#E10600;color:#fff;border-radius:5px;padding:1px 5px;letter-spacing:.5px}
.tr .tag.b{background:rgba(255,255,255,.15)}
.ctl{position:absolute;top:464px;width:430px;height:244px;border-radius:20px;background:rgba(255,255,255,.06);padding:12px 14px}
.ctl .h{display:flex;align-items:center;gap:10px}.ctl .h b{font-size:19px;font-weight:900}.ctl .h i{font-style:normal;font-size:12px;color:#8f98a7;font-weight:700}.ctl .h .ps{margin-left:auto;font-size:32px;font-weight:900;color:#E10600;line-height:1}
.ctl .t{display:flex;align-items:center;gap:8px;margin:6px 0 7px;font-size:13px;color:#c3c9d3}.ctl .t .bar2{flex:1;height:8px;border-radius:5px;background:rgba(255,255,255,.1);position:relative}.ctl .t .bar2 i{position:absolute;inset:0 auto 0 0;border-radius:5px}
.ctl .t .tyre{width:22px;height:22px;border-radius:50%;border:4px solid var(--t);background:#0b0c0f;color:#fff;font-size:10px;font-weight:900;display:grid;place-items:center;box-sizing:border-box}
.ctl .row{display:flex;gap:8px;margin-top:6px}.ctl .seg span{min-width:0;flex:1;font-size:13px;padding:0 6px}.ctl .seg{flex:1;padding:3px;height:44px}.ctl .seg span{height:38px}
.lbl{font-size:11px;letter-spacing:2px;color:#8f98a7;font-weight:700;width:58px;align-self:center}
.pit{display:flex;gap:8px;margin-top:8px;align-items:center}.pit .c{width:40px;height:40px;border-radius:50%;border:5px solid var(--t);background:#0b0c0f;color:#fff;font-weight:900;font-size:14px;display:grid;place-items:center;box-sizing:border-box}
.pit .c.on{box-shadow:0 0 0 3px #f3f4f6}
.pit .go{flex:1;height:46px;background:#E10600;color:#fff;font-size:16px;font-weight:900;letter-spacing:.5px;display:flex;align-items:center;justify-content:center;gap:8px;clip-path:polygon(0 0,calc(100% - 14px) 0,100% 14px,100% 100%,0 100%);border-radius:12px 0 12px 12px}
.hint{font-size:12px;color:#ffb4a8;margin-top:5px}
.note{position:absolute;font-size:11px;letter-spacing:1.5px;color:#5d6574}
.data{position:absolute;left:16px;top:76px;width:872px;height:378px;border-radius:22px;background:#12141a;padding:14px 18px;overflow:hidden}
.data .tabs{display:flex;gap:8px;align-items:center;margin-bottom:8px}.data .tabs h2{font-size:22px;font-weight:900;margin-right:10px;white-space:nowrap}
.dr{display:flex;height:25px;align-items:center;font-size:13px;border-bottom:1px solid rgba(255,255,255,.06);gap:8px}.dr{white-space:nowrap}.dr .a{width:44px}.dr .b{flex:1;font-weight:900}.dr .c{width:130px;color:#a8b0bd}.dr .d{width:84px;text-align:right}.dr .e{width:44px;text-align:center}.dr .f{width:70px;text-align:right}
.sc{background:#ffd24a;color:#11141a}
"""


def tyre(c, size=20, pct=None):
    return f'<span class="ty" style="--t:{TYRE[c]}">{c}</span>'


def tower(rows, me=("albon", "sainz")):
    out = ""
    for i, (tid, name, gap, tyr, wear, tag) in enumerate(rows):
        col = B.teams[tid]["color"]
        lum = int(col[1:3], 16) * .299 + int(col[3:5], 16) * .587 + int(col[5:7], 16) * .114
        mine = tid == "williams" and name in ("SAINZ", "ALBON")
        hot = "hot" if wear >= 80 else ""
        tg = f'<span class="tag{" b" if tag in ("BOX", "SC") else ""}">{tag}</span>' if tag else ""
        out += (f'<div class="tr{" me" if mine else ""}"><span class="p" style="background:{col};color:{"#11141a" if lum > 140 else "#fff"}">{i + 1}</span>'
                f'<img src="{V.EMB.format(tid)}" width="18"><span class="n">{name}</span>{tg}<span class="g">{gap}</span>{tyre(tyr)}<span class="w {hot}">{wear}%</span></div>')
    return out


ROWS = [("mclaren", "NORRIS", "Líder", "M", 71, ""), ("williams", "SAINZ", "+5.0", "M", 69, ""), ("williams", "ALBON", "+9.1", "M", 69, ""),
        ("audi", "HÜLKENBERG", "+10.9", "M", 80, ""), ("racingbulls", "LINDBLAD", "+11.6", "M", 80, ""), ("redbull", "VERSTAPPEN", "+22.5", "H", 12, ""),
        ("mclaren", "PIASTRI", "+23.7", "H", 3, ""), ("mercedes", "RUSSELL", "+24.4", "H", 4, ""), ("ferrari", "LECLERC", "+25.1", "H", 12, ""),
        ("ferrari", "HAMILTON", "+25.6", "H", 3, ""), ("redbull", "HADJAR", "+27.2", "H", 11, ""), ("astonmartin", "ALONSO", "+28.5", "H", 2, "+5s"),
        ("haas", "BEARMAN", "+30.0", "H", 2, ""), ("mercedes", "ANTONELLI", "+31.2", "H", 20, ""), ("haas", "OCON", "+31.9", "H", 3, "BOX"),
        ("audi", "BORTOLETO", "+32.4", "H", 2, ""), ("astonmartin", "STROLL", "+32.6", "H", 3, ""), ("alpine", "COLAPINTO", "+32.9", "H", 3, ""),
        ("racingbulls", "LAWSON", "+33.1", "H", 2, ""), ("cadillac", "PÉREZ", "+33.2", "H", 3, ""), ("alpine", "GASLY", "+33.4", "H", 2, ""),
        ("cadillac", "BOTTAS", "+33.8", "H", 2, "")]


def ctl(left, d, pos, tyr, name_t, wear, bat, pace, energy, order, picked, hint):
    segp = "".join(f'<span class="{"on" if x == pace else ""}">{x}</span>' for x in ["Poupar", "Normal", "Atacar"])
    sege = "".join(f'<span class="{"on" if x == energy else ""}">{x}</span>' for x in ["Carregar", "Equilíbrio", "Bateria"])
    sego = "".join(f'<span class="{"on" if x == order else ""}">{x}</span>' for x in ["Deixar passar", "Não brigar", "Liberado"])
    chips = "".join(f'<span class="c {"on" if k == picked else ""}" style="--t:{TYRE[k]}">{k}</span>' for k in "SMHIW")
    return f'''<div class="ctl" style="left:{left}px"><div class="h"><img src="{V.EMB.format("williams")}" width="26"><i>#{d["number"]}</i><b>{d["name"]}</b><span class="ps">P{pos}</span></div>
<div class="t"><span class="tyre" style="--t:{TYRE[tyr]}">{tyr}</span><span>{name_t}</span><span class="bar2"><i style="width:{wear}%;background:#f3f4f6"></i></span><b>{wear}%</b>
<span style="margin-left:8px;color:#8f98a7">BATERIA</span><span class="bar2" style="max-width:70px"><i style="width:{bat}%;background:#5c93ea"></i></span></div>
<div class="row"><div class="seg">{segp}</div><div class="seg">{sege}</div></div>
<div class="row"><span class="lbl">EQUIPE</span><div class="seg">{sego}</div></div>
<div class="pit">{chips}<div class="go">CHAMAR P/ BOX {ico("chev", 18, "#fff", 3)}</div></div><div class="hint">{hint}</div></div>'''


def corrida():
    me = V.MY
    body = f'''<div class="scene" style="--img:url(png/3d/clean_follow.png)">
<div class="bar"><div><h1>GP DE SÃO PAULO</h1><small>INTERLAGOS · PISTA SECA</small></div>
<div class="seg" style="margin-left:18px"><span>II</span><span>1×</span><span class="on">2×</span><span>4×</span><span>8×</span></div>
<div class="pill">Dados</div>
<div class="lap"><b>6<i>/</i>18</b><small>VOLTA</small></div><span class="rb">{ico("close", 20)}</span></div>
<div class="view">
<div class="card stamp">{ico("flag", 18, "#fff")} ALB: PUNIÇÃO: +5 SEG</div>
<div class="card radar"><div class="cap">RADAR · PRÓXIMAS VOLTAS</div><div class="bars"><i style="height:10%"></i><i style="height:28%"></i><i style="height:34%"></i><i style="height:12%"></i><i style="height:8%"></i></div>
<div class="tk"><span>+2</span><span>+4</span><span>+6</span><span>+8</span><span>+10</span></div><p>Sem chuva prevista nas próximas 10 voltas.</p></div>
<div class="card radio"><div class="cap">RÁDIO · ALBON</div><div class="q">“Os pneus estão caindo. Paro agora?”</div>
<div class="opts"><span class="h">Parar agora</span><span>Mais 3 voltas</span><span>Decido eu</span></div><div class="t"><span>Sem resposta, o piloto decide sozinho</span><span>12 s</span></div></div>
<div class="card camc"><span class="on">Seguir ALB</span><span>Seguir SAI</span><span>Líder</span><span>Geral</span></div></div>
<div class="tower"><div class="th"><span style="width:44px">POS</span><span style="flex:1">PILOTO</span><span style="width:54px;text-align:right">INTERV.</span><span style="width:28px"></span><span style="width:34px;text-align:right">PNEU</span></div>{tower(ROWS)}</div>
{ctl(16, me[0], 3, "M", "Médio · 5 voltas", 69, 12, "Normal", "Equilíbrio", "Liberado", "M", "Falta usar outro composto seco.")}
{ctl(458, me[1], 2, "M", "Médio · 5 voltas", 69, 24, "Normal", "Equilíbrio", "Liberado", "H", "Falta usar outro composto seco.")}
</div>'''
    return V.page("V7 · Corrida · Garagem", CSS, body)


def corrida_dados():
    rows = ""
    for i, (tid, name, gap, tyr, wear, tag) in enumerate(ROWS[:12]):
        col = B.teams[tid]["color"]
        lum = int(col[1:3], 16) * .299 + int(col[3:5], 16) * .587 + int(col[5:7], 16) * .114
        rows += (f'<div class="dr"><span class="a"><span class="tr" style="border:none;padding:0;height:auto;display:inline-flex"><span class="p" style="background:{col};color:{"#11141a" if lum > 140 else "#fff"}">{i + 1}</span></span></span>'
                 f'<span class="b">{name}</span><span class="c">{B.teams[tid]["name"]}</span><span class="d">1:{16 + i % 3}.{200 + i * 37 % 700}</span><span class="d">1:15.{855 + i * 31 % 140}</span>'
                 f'<span class="d">{gap}</span><span class="e">{tyre(tyr)}</span><span class="f">{i % 2}</span></div>')
    seg = lambda items, on: "".join(f'<span class="{"on" if x == on else ""}">{x}</span>' for x in items)
    body = f'''<div class="scene" style="--img:url(png/3d/clean_over.png)">
<div class="bar"><div><h1>GP DE SÃO PAULO</h1><small>INTERLAGOS · SAFETY CAR</small></div><div class="seg" style="margin-left:18px"><span>II</span><span>1×</span><span class="on">2×</span><span>4×</span><span>8×</span></div>
<div class="pill" style="background:#f3f4f6;color:#11141a">Dados</div><div class="pill sc" style="font-weight:900">SAFETY CAR</div>
<div class="lap"><b>6<i>/</i>18</b><small>VOLTA</small></div><span class="rb">{ico("close", 20)}</span></div>
<div class="data"><div class="tabs"><h2>DADOS DA CORRIDA</h2><div class="seg">{seg(["Todos", "Meus pilotos", "Voltas"], "Todos")}</div><span class="rb" style="margin-left:auto">{ico("close", 20)}</span></div>
<div class="dr cap" style="height:24px"><span class="a">POS</span><span class="b">PILOTO</span><span class="c">EQUIPE</span><span class="d">ÚLT. VOLTA</span><span class="d">MELHOR</span><span class="d">INTERV.</span><span class="e">PN</span><span class="f">PARADAS</span></div>{rows}</div>
<div class="tower"><div class="th"><span style="width:44px">POS</span><span style="flex:1">PILOTO</span><span style="width:54px;text-align:right">INTERV.</span><span style="width:28px"></span><span style="width:34px;text-align:right">PNEU</span></div>{tower(ROWS)}</div>
{ctl(16, V.MY[0], 3, "M", "Médio · 5 voltas", 69, 12, "Poupar", "Carregar", "Liberado", "H", "Safety car: parar custa menos tempo agora.")}
{ctl(458, V.MY[1], 2, "M", "Médio · 5 voltas", 69, 24, "Poupar", "Carregar", "Liberado", "H", "Safety car: parar custa menos tempo agora.")}
</div>'''
    return V.page("V7 · Corrida · dados e safety car", CSS, body)


if __name__ == "__main__":
    (HERE / "v7-1-corrida.html").write_text(corrida(), encoding="utf-8")
    (HERE / "v7-2-corrida-dados.html").write_text(corrida_dados(), encoding="utf-8")
    print("ok")
