"""Direção Garagem — painel do fim de semana e treino ao vivo (mockups antes do Godot).
Uso: python design/mockups/build_v4.py   (gera v4-*.html nesta pasta)
Reaproveita as peças da v3 (Garagem aprovada). Dados de exemplo coerentes com o jogo.
"""
import pathlib
import sys

sys.path.insert(0, str(pathlib.Path(__file__).parent))
import build as B  # noqa: E402
import build_v3 as V  # noqa: E402

HERE = B.HERE
C = V.C
TEAM = V.TEAM
MY = V.MY
EMB = V.EMB
ico = V.ico

CSS = V.G_CSS + """
.wrap{position:absolute;inset:0}
.hdr2{position:absolute;left:44px;top:26px;right:44px;display:flex;align-items:center;gap:16px}
.hdr2 .day{margin-left:auto;font-weight:900;font-size:30px;color:#E10600;letter-spacing:1px}
.hdr2 b{display:block;font-size:13px;letter-spacing:3px;color:#8f98a7}.hdr2 h1{font-size:30px;font-weight:900;line-height:1}
.steps{position:absolute;left:44px;right:44px;top:104px;display:flex;align-items:center}
.st{display:flex;align-items:center;gap:10px;font-size:15px;color:#8f98a7;font-weight:700;white-space:nowrap}
.st i{font-style:normal;width:34px;height:34px;border-radius:50%;display:grid;place-items:center;background:rgba(255,255,255,.07);font-size:13px;font-weight:900;color:#c3c9d3}
.st.done i{background:#2a6b3f;color:#fff}.st.now{color:#fff}.st.now i{background:#E10600;color:#fff;box-shadow:0 0 0 5px rgba(225,6,0,.25)}
.ln{flex:1;height:3px;margin:0 12px;background:rgba(255,255,255,.08);border-radius:2px}.ln.done{background:#2a6b3f}
.next{position:absolute;left:44px;top:162px;width:700px;height:226px;border-radius:20px;background:#f3f4f6;color:#11141a;padding:24px 28px;overflow:hidden}
.next:before{content:"";position:absolute;left:0;top:0;bottom:0;width:7px;background:#E10600}
.next .k{font-size:13px;letter-spacing:3px;color:#4b5260;font-weight:700}.next h2{font-size:46px;font-weight:900;line-height:1;margin:6px 0 6px}
.next p{font-size:16px;color:#4b5260;max-width:420px}
.next .acts{position:absolute;left:28px;bottom:22px;display:flex;gap:12px}
.btn2{height:56px;padding:0 26px;border-radius:14px;display:flex;align-items:center;gap:10px;font-size:19px;font-weight:900;letter-spacing:.5px}
.btn2.sim{background:#e3e6eb;color:#11141a}
.next svg.trk{position:absolute;right:26px;top:26px;opacity:.9}
.fc{position:absolute;left:44px;top:404px;width:700px;display:flex;gap:10px}
.fc>div{flex:1;border-radius:16px;background:rgba(255,255,255,.06);padding:12px 16px;display:flex;align-items:center;gap:12px}
.fc b{display:block;font-size:22px;font-weight:900}.fc small{font-size:12px;letter-spacing:2px;color:#8f98a7}
.prog{position:absolute;left:44px;top:494px;width:700px}
.prog .row{display:flex;gap:10px;align-items:center;margin-top:8px}
.blk{flex:1;justify-content:center;height:52px;border-radius:14px;padding:0 8px;display:flex;align-items:center;gap:10px;font-size:14px;font-weight:700;background:rgba(255,255,255,.07);white-space:nowrap}
.blk em{font-style:normal;font-size:12px;color:#8f98a7;letter-spacing:1px}
.blk.on{background:#f3f4f6;color:#11141a}.blk.on em{color:#4b5260}.blk.add{background:none;border:2px dashed rgba(255,255,255,.18);color:#a8b0bd}
.cars{position:absolute;right:40px;top:162px;width:450px;display:flex;flex-direction:column;gap:14px}
.car2{border-radius:20px;background:rgba(255,255,255,.06);padding:16px 20px;position:relative;overflow:hidden}
.car2 .nm{display:flex;align-items:center;gap:12px}.car2 .nm b{font-size:21px;font-weight:900}.car2 .nm .no{margin-left:auto;font-size:38px;font-weight:900;color:transparent;-webkit-text-stroke:1.5px #5c93ea;line-height:.8}
.bars{margin-top:12px;display:flex;flex-direction:column;gap:9px}
.bar2{display:flex;align-items:center;gap:12px;font-size:14px}.bar2 span{width:96px;color:#c3c9d3}.bar2 .t{flex:1;height:10px;border-radius:6px;background:rgba(255,255,255,.08);position:relative}
.bar2 .t i{position:absolute;left:0;top:0;bottom:0;border-radius:6px;background:linear-gradient(90deg,#1868DB,#5c93ea)}.bar2 b{width:44px;text-align:right;font-size:16px;font-weight:900}
.quote{margin-top:12px;font-size:15px;color:#c3c9d3;display:flex;gap:10px;align-items:flex-start}.quote i{font-size:28px;line-height:.6;color:#5c93ea;font-style:normal;font-weight:900}
.tag2{display:inline-block;font-size:12px;letter-spacing:2px;border-radius:12px;padding:4px 10px;background:rgba(255,255,255,.08);color:#a8b0bd;margin-top:10px}
/* treino */
.sheet{position:absolute;left:44px;top:104px;width:720px;bottom:20px;border-radius:20px;background:rgba(255,255,255,.04);overflow:hidden}
.th{display:flex;height:40px;align-items:center;font-size:12px;letter-spacing:2px;color:#8f98a7;padding:0 14px;border-bottom:1px solid rgba(255,255,255,.08)}
.tr{display:flex;height:36px;align-items:center;padding:0 14px;font-size:16px;border-bottom:1px solid rgba(255,255,255,.07)}
.tr .p{width:34px;height:26px;border-radius:7px;display:grid;place-items:center;font-weight:900;font-size:15px;margin-right:12px}
.tr .n{flex:1;font-weight:900;letter-spacing:.5px}.tr .c{width:96px;text-align:right;font-variant-numeric:tabular-nums}.tr .d{width:80px;text-align:right;color:#a8b0bd}
.tr .l{width:66px;text-align:right;color:#a8b0bd}.tr .s{width:170px;padding-left:18px;color:#a8b0bd;font-size:14px}
.tr.me{background:rgba(24,104,219,.22)}.tr.me .n{color:#fff}
.clock{margin-left:auto;display:flex;align-items:center;gap:14px}.clock b{font-size:34px;font-weight:900;font-variant-numeric:tabular-nums;color:#eef0f3}
.spd{display:flex;background:rgba(255,255,255,.07);border-radius:24px;padding:4px;gap:4px}.spd span{width:52px;height:40px;border-radius:20px;display:grid;place-items:center;font-size:15px;font-weight:700;color:#c3c9d3}.spd span.on{background:#f3f4f6;color:#11141a}
.right{position:absolute;right:40px;top:104px;width:430px;display:flex;flex-direction:column;gap:14px}
.tl{display:flex;gap:6px;margin-top:12px}.tl div{flex:1;height:44px;border-radius:12px;background:rgba(255,255,255,.07);font-size:12px;font-weight:700;display:flex;flex-direction:column;justify-content:center;padding:0 10px;color:#a8b0bd;position:relative;overflow:hidden}
.tl div.done{color:#cfe8d6}.tl div.done:after{content:"";position:absolute;left:0;bottom:0;height:4px;width:100%;background:#3c9d5d}
.tl div.now{background:#f3f4f6;color:#11141a}.tl div.now:after{content:"";position:absolute;left:0;bottom:0;height:4px;width:58%;background:#E10600}
.tl small{font-size:11px;font-weight:600;opacity:.8}
.feed{border-radius:20px;background:rgba(255,255,255,.04);padding:14px 18px;font-size:15px;color:#c3c9d3;line-height:1.7}
.feed b{color:#fff}.feed .w{color:#ffb4a8}
.note{position:absolute;font-size:11px;letter-spacing:1.5px;color:#5d6574}
"""


def weekend():
    steps = [("TL1", "done", "✓"), ("TL2", "now", "2"), ("TL3", "", "3"), ("CLASS", "", "Q"), ("CORRIDA", "", "R")]
    st = ""
    for i, (name, cls, ic) in enumerate(steps):
        if i:
            st += f'<div class="ln{" done" if steps[i - 1][1] == "done" else ""}"></div>'
        st += f'<div class="st {cls}"><i>{ic}</i>{name}</div>'
    days = [("SEXTA", "10%", "sun"), ("SÁBADO", "25%", "mix"), ("DOMINGO", "55%", "rain")]
    fc = "".join(f'<div>{ico(i, 30, "#dfe3ea")}<div><small>{d}</small><b>{p} chuva</b></div></div>' for d, p, i in days)
    blocks = [("Acerto aero", "15 min", True), ("Acerto mecânico", "15 min", True), ("Simulação de corrida", "20 min", True), ("Volta rápida", "10 min", True)]
    blk = "".join(f'<div class="blk on">{n} <em>{m}</em></div>' for n, m, on in blocks)
    cars = ""
    data = [(MY[0], (62, 48, 55), "O carro sai de frente nas curvas lentas e pula nas zebras."), (MY[1], (40, 66, 51), "Falta asa nas curvas rápidas, a traseira fica solta.")]
    for d, vals, q in data:
        bars = "".join(f'<div class="bar2"><span>{n}</span><div class="t"><i style="width:{v}%"></i></div><b>{v}%</b></div>' for n, v in zip(["Aerodinâmica", "Mecânico", "Equilíbrio"], vals))
        cars += f'''<div class="car2"><div class="nm"><img src="{EMB.format("williams")}" width="28"><b>{d["name"]}</b><span class="no">{d["number"]}</span></div>
<div class="bars">{bars}</div><div class="quote"><i>“</i>{q}</div><span class="tag2">TL1: 3º · 14 VOLTAS</span></div>'''
    body = f'''<div class="scene"><div class="wall" style="bottom:0"></div><div class="glow" style="background:radial-gradient(ellipse 45% 50% at 30% 40%,rgba(24,104,219,.22),transparent 70%)"></div>
<div class="hdr2"><span class="round">{ico("back", 26, "#eef0f3", 2.6)}</span><div><b>FIM DE SEMANA · WILLIAMS</b><h1>{C["grand_prix"].upper()}</h1></div><span class="day">SEXTA</span></div>
<div class="steps">{st}</div>
<div class="next"><div class="k">PRÓXIMA SESSÃO · AGORA</div><h2>TREINO LIVRE 2</h2><p>60 minutos. Seus pilotos seguem o programa abaixo; jogue para acompanhar ou simule para ver o resultado.</p>
{V.outline("interlagos", 150, 130, "#11141a", 6, 8).replace("<svg ", '<svg class="trk" ', 1)}
<div class="acts"><div class="cta" style="height:56px;padding:0 26px;font-size:19px">JOGAR {ico("chev", 22, "#fff", 3)}</div><div class="btn2 sim">SIMULAR</div></div></div>
<div class="fc">{fc}</div>
<div class="prog"><div class="lbl">PROGRAMA DO TREINO · ALBON · 60 / 60 MIN · TOQUE NUM BLOCO PARA TIRAR</div><div class="row">{blk}</div>
<div class="row"><div class="blk add">+ Aero</div><div class="blk add">+ Mecânico</div><div class="blk add">+ Corrida</div><div class="blk add">+ Volta rápida</div></div></div>
<div class="cars">{cars}</div>
<div class="note" style="left:44px;bottom:8px">MOCKUP · ACERTO, COMENTÁRIOS E POSIÇÕES = DADOS DE EXEMPLO DO JOGO</div></div>'''
    return V.page("V4 · Garagem · fim de semana", CSS, body)


def practice():
    rows = [("NORRIS", "mclaren", "1:13.721", "—", 15, "Acerto mecânico"), ("LECLERC", "ferrari", "1:13.857", "+0.137", 16, "Acerto aero"),
            ("VERSTAPPEN", "redbull", "1:13.868", "+0.147", 15, "Acerto aero"), ("RUSSELL", "mercedes", "1:13.879", "+0.159", 15, "Simulação de corrida"),
            ("PIASTRI", "mclaren", "1:13.891", "+0.170", 15, "Acerto aero"), ("ANTONELLI", "mercedes", "1:13.919", "+0.199", 15, "Acerto aero"),
            ("HAMILTON", "ferrari", "1:14.097", "+0.377", 15, "Acerto mecânico"), ("SAINZ", "williams", "1:14.152", "+0.431", 15, "Acerto mecânico"),
            ("HADJAR", "redbull", "1:14.162", "+0.441", 16, "Acerto mecânico"), ("ALONSO", "astonmartin", "1:14.190", "+0.469", 15, "Volta rápida"),
            ("ALBON", "williams", "1:14.530", "+0.810", 15, "Acerto mecânico"), ("HÜLKENBERG", "audi", "1:14.775", "+1.055", 15, "Acerto aero"),
            ("BEARMAN", "haas", "1:14.758", "+1.037", 15, "Garagem"), ("LAWSON", "racingbulls", "1:14.845", "+1.124", 16, "Simulação de corrida")]
    tr = ""
    for i, (n, t, c, d, laps, s) in enumerate(rows):
        col = B.teams[t]["color"]
        lum = int(col[1:3], 16) * .299 + int(col[3:5], 16) * .587 + int(col[5:7], 16) * .114
        me = " me" if t == "williams" else ""
        tr += (f'<div class="tr{me}"><span class="p" style="background:{col};color:{"#11141a" if lum > 140 else "#fff"}">{i + 1}</span>'
               f'<img src="{EMB.format(t)}" width="20" style="margin-right:10px"><span class="n">{n}</span><span class="c">{c}</span><span class="d">{d}</span>'
               f'<span class="l">{laps}</span><span class="s">{s}</span></div>')
    cars = ""
    for d, done, now, vals in [(MY[1], 1, 1, (84, 80, 69)), (MY[0], 1, 1, (92, 73, 72))]:
        tl = ""
        for k, (b, m) in enumerate([("Aero", "15 min"), ("Mecânico", "15 min"), ("Corrida", "20 min"), ("Volta rápida", "10 min")]):
            cls = "done" if k < done else ("now" if k == done else "")
            tl += f'<div class="{cls}">{b}<small>{"✓ feito" if cls == "done" else ("em andamento" if cls == "now" else m)}</small></div>'
        bars = "".join(f'<div class="bar2"><span>{n}</span><div class="t"><i style="width:{v}%"></i></div><b>{v}%</b></div>' for n, v in zip(["Aerodinâmica", "Mecânico", "Equilíbrio"], vals))
        pos = 8 if d["number"] == 55 else 11
        cars += f'''<div class="car2"><div class="nm"><img src="{EMB.format("williams")}" width="28"><b>{d["name"]}</b><span style="margin-left:auto;font-size:30px;font-weight:900;color:#E10600">P{pos}</span></div>
<div class="tl">{tl}</div><div class="bars">{bars}</div></div>'''
    body = f'''<div class="scene"><div class="wall" style="bottom:0"></div>
<div class="hdr2"><span class="round">{ico("back", 26, "#eef0f3", 2.6)}</span><div><b>{C["grand_prix"].upper()} · ACOMPANHAMENTO</b><h1>TREINO LIVRE 2</h1></div>
<div class="clock"><div class="spd"><span>II</span><span>4×</span><span>8×</span><span class="on">16×</span><span>32×</span></div><span class="btn2 sim" style="height:48px;font-size:15px;background:rgba(255,255,255,.08);color:#eef0f3">SIMULAR RESTO</span><b>34:59</b></div></div>
<div class="sheet"><div class="th"><span style="width:46px">POS</span><span style="flex:1;padding-left:30px">PILOTO</span><span style="width:96px;text-align:right">MELHOR</span><span style="width:80px;text-align:right">DIF.</span><span style="width:66px;text-align:right">VOLTAS</span><span style="width:170px;padding-left:18px">FAZENDO AGORA</span></div>{tr}</div>
<div class="right">{cars}<div class="feed"><b>SAI</b> — Acerto aero concluído.<br><b>ALB</b> — Acerto aero concluído.<br><span class="w"><b>BEA</b> — Problema mecânico: carro na garagem.</span></div></div>
<div class="note" style="right:40px;bottom:8px">TREINO = SÓ ACOMPANHAMENTO (AS DECISÕES FORAM O PROGRAMA, NO PAINEL)</div></div>'''
    return V.page("V4 · Garagem · treino ao vivo", CSS, body)


if __name__ == "__main__":
    (HERE / "v4-1-garagem-fim-de-semana.html").write_text(weekend(), encoding="utf-8")
    (HERE / "v4-2-garagem-treino.html").write_text(practice(), encoding="utf-8")
    print("ok")
